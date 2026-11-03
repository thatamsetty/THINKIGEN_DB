"""
Unit tests for Teacher Leave & Grievance service logic, pending calculations,
overlap prevention, and status lifecycle state machines.
"""

from datetime import date
from decimal import Decimal
import pytest

from app.schemas.teacher_leave import (
    LeaveType,
    LeaveDurationType,
    LeaveStatus,
    GrievanceCategory,
    GrievancePriority,
    GrievanceStatus,
    TeacherLeaveApplicationCreate,
)
from app.services.teacher_leave_service import (
    TeacherLeaveService,
    InsufficientLeaveBalanceError,
    OverlappingLeaveError,
    InvalidLeaveTransitionError,
    UnauthorizedAssigneeError,
)


def test_leave_application_duration_validation():
    # Valid Half Day
    valid_half = TeacherLeaveApplicationCreate(
        leave_type=LeaveType.CASUAL,
        leave_duration_type=LeaveDurationType.HALF_DAY,
        start_date=date(2026, 11, 2),
        end_date=date(2026, 11, 2),
        total_days=Decimal("0.5"),
        reason="Dentist appointment afternoon",
    )
    assert valid_half.total_days == Decimal("0.5")

    # Invalid Half Day: different dates
    with pytest.raises(ValueError, match="HALF_DAY leave must have start_date equal to end_date"):
        TeacherLeaveApplicationCreate(
            leave_type=LeaveType.CASUAL,
            leave_duration_type=LeaveDurationType.HALF_DAY,
            start_date=date(2026, 11, 2),
            end_date=date(2026, 11, 3),  # Multi-day!
            total_days=Decimal("0.5"),
            reason="Invalid half day",
        )

    # Invalid Full Day: total_days < 1.0
    with pytest.raises(ValueError, match="FULL_DAY leave total_days must be at least 1.0"):
        TeacherLeaveApplicationCreate(
            leave_type=LeaveType.SICK,
            leave_duration_type=LeaveDurationType.FULL_DAY,
            start_date=date(2026, 11, 5),
            end_date=date(2026, 11, 5),
            total_days=Decimal("0.5"),  # Invalid for full day
            reason="Fever",
        )


def test_available_leave_with_pending_reservations():
    # Total = 10, Used = 4 => Remaining = 6
    # Pending = 3 => Available = 3
    balance = TeacherLeaveService.calculate_available_leave(
        total_days=Decimal("10.0"),
        used_days=Decimal("4.0"),
        pending_reserved_days=Decimal("3.0"),
    )
    assert balance["remaining_days"] == Decimal("6.0")
    assert balance["available_days"] == Decimal("3.0")

    # When pending equals remaining: Available is 0.0
    zero_balance = TeacherLeaveService.calculate_available_leave(
        total_days=Decimal("10.0"),
        used_days=Decimal("4.0"),
        pending_reserved_days=Decimal("6.0"),
    )
    assert zero_balance["available_days"] == Decimal("0.0")


def test_overlap_detection():
    existing_leaves = [
        {
            "start_date": date(2026, 11, 10),
            "end_date": date(2026, 11, 14),
            "status": LeaveStatus.PENDING,
            "is_active": True,
        },
        {
            "start_date": date(2026, 11, 20),
            "end_date": date(2026, 11, 22),
            "status": LeaveStatus.CANCELLED,  # Inactive status
            "is_active": True,
        },
    ]

    # Partial overlap with pending leave: Nov 12 to Nov 16
    assert TeacherLeaveService.check_for_overlap(
        date(2026, 11, 12), date(2026, 11, 16), existing_leaves
    ) is True

    # Complete enclosure: Nov 11 to Nov 13
    assert TeacherLeaveService.check_for_overlap(
        date(2026, 11, 11), date(2026, 11, 13), existing_leaves
    ) is True

    # No overlap: Nov 15 to Nov 18
    assert TeacherLeaveService.check_for_overlap(
        date(2026, 11, 15), date(2026, 11, 18), existing_leaves
    ) is False

    # Overlap with cancelled leave: should be ignored (False)
    assert TeacherLeaveService.check_for_overlap(
        date(2026, 11, 21), date(2026, 11, 21), existing_leaves
    ) is False


def test_allowance_delta_and_reversal_on_cancellation():
    total_days = Decimal("3.0")

    # 1. PENDING -> APPROVED: Quota deducted (+3.0 used)
    delta_approve = TeacherLeaveService.compute_allowance_delta_on_status_change(
        LeaveStatus.PENDING, LeaveStatus.APPROVED, total_days
    )
    assert delta_approve == Decimal("3.0")

    # 2. APPROVED -> CANCELLED: Quota reversed (-3.0 used restored)
    delta_cancel_approved = TeacherLeaveService.compute_allowance_delta_on_status_change(
        LeaveStatus.APPROVED, LeaveStatus.CANCELLED, total_days
    )
    assert delta_cancel_approved == Decimal("-3.0")

    # 3. PENDING -> REJECTED: No quota change (0.0)
    delta_reject = TeacherLeaveService.compute_allowance_delta_on_status_change(
        LeaveStatus.PENDING, LeaveStatus.REJECTED, total_days
    )
    assert delta_reject == Decimal("0.0")

    # 4. PENDING -> CANCELLED: No quota change (0.0)
    delta_cancel_pending = TeacherLeaveService.compute_allowance_delta_on_status_change(
        LeaveStatus.PENDING, LeaveStatus.CANCELLED, total_days
    )
    assert delta_cancel_pending == Decimal("0.0")

    # 5. Illegal transition: REJECTED -> APPROVED raises error
    with pytest.raises(InvalidLeaveTransitionError):
        TeacherLeaveService.compute_allowance_delta_on_status_change(
            LeaveStatus.REJECTED, LeaveStatus.APPROVED, total_days
        )


def test_grievance_status_transitions():
    # Legal progression
    TeacherLeaveService.validate_grievance_transition(GrievanceStatus.OPEN, GrievanceStatus.UNDER_REVIEW)
    TeacherLeaveService.validate_grievance_transition(GrievanceStatus.UNDER_REVIEW, GrievanceStatus.RESOLVED)
    TeacherLeaveService.validate_grievance_transition(GrievanceStatus.RESOLVED, GrievanceStatus.CLOSED)

    # Illegal: OPEN to CLOSED directly
    with pytest.raises(InvalidLeaveTransitionError):
        TeacherLeaveService.validate_grievance_transition(GrievanceStatus.OPEN, GrievanceStatus.CLOSED)

    # Illegal: CLOSED to OPEN (terminal state)
    with pytest.raises(InvalidLeaveTransitionError):
        TeacherLeaveService.validate_grievance_transition(GrievanceStatus.CLOSED, GrievanceStatus.OPEN)


def test_grievance_assignee_tenant_authorization():
    # Valid: Same school, same branch, valid role
    TeacherLeaveService.validate_assignee_tenant_scope(
        grievance_school_id=1,
        grievance_branch_id=1,
        assignee_school_id=1,
        assignee_branch_id=1,
        assignee_roles=["PRINCIPAL"],
    )

    # Cross-school violation
    with pytest.raises(UnauthorizedAssigneeError, match="Cross-school assignment violation"):
        TeacherLeaveService.validate_assignee_tenant_scope(
            grievance_school_id=1,
            grievance_branch_id=1,
            assignee_school_id=2,  # Different school!
            assignee_branch_id=1,
            assignee_roles=["PRINCIPAL"],
        )

    # Cross-branch violation
    with pytest.raises(UnauthorizedAssigneeError, match="Cross-branch assignment violation"):
        TeacherLeaveService.validate_assignee_tenant_scope(
            grievance_school_id=1,
            grievance_branch_id=1,
            assignee_school_id=1,
            assignee_branch_id=2,  # Different branch!
            assignee_roles=["PRINCIPAL"],
        )

    # Unauthorized role violation
    with pytest.raises(UnauthorizedAssigneeError, match="Assignee lacks required grievance resolution role"):
        TeacherLeaveService.validate_assignee_tenant_scope(
            grievance_school_id=1,
            grievance_branch_id=1,
            assignee_school_id=1,
            assignee_branch_id=1,
            assignee_roles=["TEACHER"],  # Regular teacher cannot resolve grievances
        )
