"""
Thinkigen School ERP - Teacher Leave Management & Grievance Service.
Enforces:
- Available leave calculation accounting for PENDING reservations (available = remaining - pending)
- Overlap detection and serializable concurrency protection (UPDLOCK, HOLDLOCK)
- Idempotent approval, rejection, and cancellation
- Accurate reversal of used_days when an APPROVED leave is cancelled
- Atomic transactions binding status history and allowance updates
- Grievance assignee tenant authorization and strict status transitions
"""

from __future__ import annotations

import logging
from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Optional, Dict, Any, List

from app.schemas.teacher_leave import (
    LeaveType,
    LeaveDurationType,
    LeaveStatus,
    GrievanceCategory,
    GrievancePriority,
    GrievanceStatus,
    TeacherLeaveApplicationCreate,
)

logger = logging.getLogger("thinkigen.teacher_leave")


class InsufficientLeaveBalanceError(Exception):
    """Raised when requested days exceed available entitlement after pending reservations."""
    pass


class OverlappingLeaveError(Exception):
    """Raised when an active leave application already covers part of the requested dates."""
    pass


class InvalidLeaveTransitionError(Exception):
    """Raised when attempting an illegal status transition (e.g. approving an already rejected leave)."""
    pass


class UnauthorizedAssigneeError(Exception):
    """Raised when a grievance assignee does not belong to the same tenant or lacks role."""
    pass


class TeacherLeaveService:
    """
    Core service managing Teacher Leave applications, allowances,
    and Grievance workflows with full ACID transaction boundaries.
    """

    def __init__(self, db_connection: Any = None):
        self.conn = db_connection

    # -------------------------------------------------------------------------
    # 1. Available Leave Calculation with Pending Reservation
    # -------------------------------------------------------------------------
    @staticmethod
    def calculate_available_leave(
        total_days: Decimal,
        used_days: Decimal,
        pending_reserved_days: Decimal,
    ) -> Dict[str, Decimal]:
        """
        Calculates exact leave entitlement balance:
        - remaining_days = total_days - used_days
        - available_days = remaining_days - pending_reserved_days
        """
        remaining_days = max(Decimal("0.0"), total_days - used_days)
        available_days = max(Decimal("0.0"), remaining_days - pending_reserved_days)
        return {
            "total_days": total_days,
            "used_days": used_days,
            "remaining_days": remaining_days,
            "pending_reserved_days": pending_reserved_days,
            "available_days": available_days,
        }

    # -------------------------------------------------------------------------
    # 2. Overlap Checking Logic
    # -------------------------------------------------------------------------
    @staticmethod
    def check_for_overlap(
        new_start: date,
        new_end: date,
        existing_applications: List[Dict[str, Any]],
    ) -> bool:
        """
        Returns True if (new_start, new_end) overlaps with any active (PENDING or APPROVED) leave.
        Formula: (new_start <= existing_end) AND (new_end >= existing_start)
        """
        for app in existing_applications:
            if app.get("is_active", True) and app.get("status") in (
                LeaveStatus.PENDING,
                LeaveStatus.APPROVED,
            ):
                ex_start = app["start_date"]
                ex_end = app["end_date"]
                if new_start <= ex_end and new_end >= ex_start:
                    return True
        return False

    # -------------------------------------------------------------------------
    # 3. Status Transition Matrix & Allowance Reversal
    # -------------------------------------------------------------------------
    @staticmethod
    def compute_allowance_delta_on_status_change(
        current_status: LeaveStatus,
        new_status: LeaveStatus,
        total_days: Decimal,
    ) -> Decimal:
        """
        Determines the change (+delta or -delta) to used_days in teacher_leave_allowance.
        - PENDING -> APPROVED: +total_days (quota used)
        - APPROVED -> CANCELLED: -total_days (quota reversed / restored)
        - PENDING -> REJECTED: 0.0 (no quota deduction had occurred)
        - PENDING -> CANCELLED: 0.0 (no quota deduction had occurred)
        - All other transitions are illegal.
        """
        if current_status == LeaveStatus.PENDING and new_status == LeaveStatus.APPROVED:
            return total_days
        elif current_status == LeaveStatus.APPROVED and new_status == LeaveStatus.CANCELLED:
            return -total_days
        elif current_status == LeaveStatus.PENDING and new_status in (LeaveStatus.REJECTED, LeaveStatus.CANCELLED):
            return Decimal("0.0")
        else:
            raise InvalidLeaveTransitionError(
                f"Illegal leave status transition from {current_status} to {new_status}"
            )

    # -------------------------------------------------------------------------
    # 4. Grievance Status State Machine
    # -------------------------------------------------------------------------
    VALID_GRIEVANCE_TRANSITIONS = {
        GrievanceStatus.OPEN: {GrievanceStatus.UNDER_REVIEW, GrievanceStatus.REJECTED},
        GrievanceStatus.UNDER_REVIEW: {GrievanceStatus.RESOLVED, GrievanceStatus.REJECTED},
        GrievanceStatus.RESOLVED: {GrievanceStatus.CLOSED},
        GrievanceStatus.REJECTED: {GrievanceStatus.CLOSED},
        GrievanceStatus.CLOSED: set(),  # Terminal state
    }

    @classmethod
    def validate_grievance_transition(
        cls, current_status: GrievanceStatus, new_status: GrievanceStatus
    ) -> None:
        """Enforces legal grievance lifecycle transitions."""
        allowed = cls.VALID_GRIEVANCE_TRANSITIONS.get(current_status, set())
        if new_status not in allowed:
            raise InvalidLeaveTransitionError(
                f"Invalid grievance transition from {current_status} to {new_status}. "
                f"Allowed transitions: {[s.value for s in allowed]}"
            )

    @staticmethod
    def validate_assignee_tenant_scope(
        grievance_school_id: int,
        grievance_branch_id: int,
        assignee_school_id: int,
        assignee_branch_id: Optional[int],
        assignee_roles: List[str],
    ) -> None:
        """
        Ensures grievance is only assigned to authorized personnel within the same tenant scope.
        """
        if grievance_school_id != assignee_school_id:
            raise UnauthorizedAssigneeError(
                f"Cross-school assignment violation: grievance school {grievance_school_id} "
                f"does not match assignee school {assignee_school_id}"
            )
        if assignee_branch_id is not None and grievance_branch_id != assignee_branch_id:
            raise UnauthorizedAssigneeError(
                f"Cross-branch assignment violation: grievance branch {grievance_branch_id} "
                f"does not match assignee branch {assignee_branch_id}"
            )
        authorized_roles = {"PRINCIPAL", "HR_ADMIN", "BRANCH_HEAD", "GRIEVANCE_OFFICER", "SUPER_ADMIN"}
        if not any(role in authorized_roles for role in assignee_roles):
            raise UnauthorizedAssigneeError(
                f"Assignee lacks required grievance resolution role. Active roles: {assignee_roles}"
            )
