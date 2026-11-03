"""
Unit tests for student_attentions Pydantic models and service logic.
"""

from datetime import datetime, timezone, date
import pytest

from app.schemas.student_attentions import (
    AttentionType,
    AttentionSeverity,
    TriggerSource,
    AttentionStatus,
    AttentionItemBase,
    AssessmentDetails,
    HomeworkDetails,
    AttendanceDetails,
    HomeworkSubmissionStatus,
    AttendancePeriodStatus,
    SubjectAttentionItem,
    StudentSubjectAttentionDocument,
)
from app.services.student_attentions_service import generate_deterministic_attention_id


def test_deterministic_attention_id():
    att_id_asm = generate_deterministic_attention_id(101, TriggerSource.ASSESSMENT, 501, 2026)
    assert att_id_asm == "ATT-101-ASM-501-2026"

    att_id_hw = generate_deterministic_attention_id(101, TriggerSource.ASSIGNMENT_HOMEWORK, 802, 2026)
    assert att_id_hw == "ATT-101-HW-802-2026"

    att_id_att = generate_deterministic_attention_id(101, TriggerSource.ATTENDANCE, 9003, 2026)
    assert att_id_att == "ATT-101-ATT-9003-2026"


def test_valid_assessment_attention():
    att = AttentionItemBase(
        attention_id="ATT-101-ASM-501-2026",
        attention_type=AttentionType.LOW_ASSESSMENT_SCORE,
        severity=AttentionSeverity.CRITICAL,
        title="Failed Slip Test",
        description="Scored 12 out of 50",
        trigger_source=TriggerSource.ASSESSMENT,
        source_id=501,
        triggered_at=datetime.now(timezone.utc),
        status=AttentionStatus.ACTIVE,
        assessment_details=AssessmentDetails(
            assessment_id=501,
            assessment_name="Slip Test 1",
            exam_type="SLIP_TEST",
            max_marks=50,
            pass_marks=20,
            obtained_marks=12,
            percentage=24.0,
        ),
    )
    assert att.attention_type == AttentionType.LOW_ASSESSMENT_SCORE
    assert att.trigger_source == TriggerSource.ASSESSMENT
    assert att.assessment_details.obtained_marks == 12


def test_invalid_assessment_mismatched_trigger():
    with pytest.raises(ValueError, match="LOW_ASSESSMENT_SCORE must have trigger_source = ASSESSMENT"):
        AttentionItemBase(
            attention_id="ATT-101-ASM-501-2026",
            attention_type=AttentionType.LOW_ASSESSMENT_SCORE,
            severity=AttentionSeverity.CRITICAL,
            title="Failed Slip Test",
            description="Scored 12 out of 50",
            trigger_source=TriggerSource.ATTENDANCE,  # INVALID TRIGGER
            source_id=501,
            triggered_at=datetime.now(timezone.utc),
            status=AttentionStatus.ACTIVE,
            assessment_details=AssessmentDetails(
                assessment_id=501,
                assessment_name="Slip Test 1",
                max_marks=50,
                pass_marks=20,
                obtained_marks=12,
                percentage=24.0,
            ),
        )


def test_invalid_assessment_with_homework_details():
    with pytest.raises(ValueError, match="homework_details and attendance_details must be null"):
        AttentionItemBase(
            attention_id="ATT-101-ASM-501-2026",
            attention_type=AttentionType.LOW_ASSESSMENT_SCORE,
            severity=AttentionSeverity.CRITICAL,
            title="Failed Slip Test",
            description="Scored 12 out of 50",
            trigger_source=TriggerSource.ASSESSMENT,
            source_id=501,
            triggered_at=datetime.now(timezone.utc),
            status=AttentionStatus.ACTIVE,
            assessment_details=AssessmentDetails(
                assessment_id=501,
                assessment_name="Slip Test 1",
                max_marks=50,
                pass_marks=20,
                obtained_marks=12,
                percentage=24.0,
            ),
            homework_details=HomeworkDetails(  # ILLEGAL FOR ASSESSMENT
                homework_id=1,
                homework_title="HW",
                assigned_date=date(2026, 10, 1),
                due_date=date(2026, 10, 3),
                submission_status=HomeworkSubmissionStatus.NOT_SUBMITTED,
            ),
        )


def test_valid_homework_attention():
    att = AttentionItemBase(
        attention_id="ATT-101-HW-802-2026",
        attention_type=AttentionType.PENDING_HOMEWORK,
        severity=AttentionSeverity.HIGH,
        title="Pending Homework Ex 4",
        description="Homework overdue",
        trigger_source=TriggerSource.ASSIGNMENT_HOMEWORK,
        source_id=802,
        triggered_at=datetime.now(timezone.utc),
        status=AttentionStatus.ACTIVE,
        homework_details=HomeworkDetails(
            homework_id=802,
            homework_title="Ex 4 Algebra",
            assigned_date=date(2026, 10, 10),
            due_date=date(2026, 10, 12),
            days_overdue=4,
            submission_status=HomeworkSubmissionStatus.NOT_SUBMITTED,
        ),
    )
    assert att.attention_type == AttentionType.PENDING_HOMEWORK
    assert att.homework_details.days_overdue == 4


def test_valid_attendance_attention():
    att = AttentionItemBase(
        attention_id="ATT-101-ATT-9003-2026",
        attention_type=AttentionType.ABSENT_ATTENDANCE,
        severity=AttentionSeverity.MEDIUM,
        title="Absent in Period 2",
        description="Period absence",
        trigger_source=TriggerSource.ATTENDANCE,
        source_id=9003,
        triggered_at=datetime.now(timezone.utc),
        status=AttentionStatus.ACTIVE,
        attendance_details=AttendanceDetails(
            attendance_id=9003,
            attendance_date=date(2026, 10, 15),
            period_number=2,
            period_time="09:15 - 10:00",
            attendance_status=AttendancePeriodStatus.ABSENT,
        ),
    )
    assert att.attention_type == AttentionType.ABSENT_ATTENDANCE
    assert att.attendance_details.period_number == 2


def test_resolution_audit_requirements():
    # RESOLVED requires resolved_at
    with pytest.raises(ValueError, match="resolved_at must be populated"):
        AttentionItemBase(
            attention_id="ATT-101-ASM-501-2026",
            attention_type=AttentionType.LOW_ASSESSMENT_SCORE,
            severity=AttentionSeverity.CRITICAL,
            title="Failed Slip Test",
            description="Scored 12 out of 50",
            trigger_source=TriggerSource.ASSESSMENT,
            source_id=501,
            triggered_at=datetime.now(timezone.utc),
            status=AttentionStatus.RESOLVED,
            resolved_at=None,  # Missing!
            assessment_details=AssessmentDetails(
                assessment_id=501,
                assessment_name="Slip Test 1",
                max_marks=50,
                pass_marks=20,
                obtained_marks=12,
                percentage=24.0,
            ),
        )

    # EXCUSED requires excused_reason
    with pytest.raises(ValueError, match="excused_reason must be populated"):
        AttentionItemBase(
            attention_id="ATT-101-ATT-9003-2026",
            attention_type=AttentionType.ABSENT_ATTENDANCE,
            severity=AttentionSeverity.MEDIUM,
            title="Absent in Period 2",
            description="Period absence",
            trigger_source=TriggerSource.ATTENDANCE,
            source_id=9003,
            triggered_at=datetime.now(timezone.utc),
            status=AttentionStatus.EXCUSED,
            excused_reason=None,  # Missing!
            attendance_details=AttendanceDetails(
                attendance_id=9003,
                attendance_date=date(2026, 10, 15),
                period_number=2,
                attendance_status=AttendancePeriodStatus.ABSENT,
            ),
        )


def test_document_recalculate_counts():
    now = datetime.now(timezone.utc)
    att1 = AttentionItemBase(
        attention_id="ATT-101-ASM-501-2026",
        attention_type=AttentionType.LOW_ASSESSMENT_SCORE,
        severity=AttentionSeverity.CRITICAL,
        title="Failed Slip Test",
        description="Scored 12 out of 50",
        trigger_source=TriggerSource.ASSESSMENT,
        source_id=501,
        triggered_at=now,
        status=AttentionStatus.ACTIVE,
        assessment_details=AssessmentDetails(
            assessment_id=501,
            assessment_name="Slip Test 1",
            max_marks=50,
            pass_marks=20,
            obtained_marks=12,
            percentage=24.0,
        ),
    )
    att2 = AttentionItemBase(
        attention_id="ATT-101-HW-802-2026",
        attention_type=AttentionType.PENDING_HOMEWORK,
        severity=AttentionSeverity.HIGH,
        title="Pending Homework Ex 4",
        description="Homework overdue",
        trigger_source=TriggerSource.ASSIGNMENT_HOMEWORK,
        source_id=802,
        triggered_at=now,
        status=AttentionStatus.RESOLVED,
        resolved_at=now,
        homework_details=HomeworkDetails(
            homework_id=802,
            homework_title="Ex 4 Algebra",
            assigned_date=date(2026, 10, 10),
            due_date=date(2026, 10, 12),
            submission_status=HomeworkSubmissionStatus.NOT_SUBMITTED,
        ),
    )

    sub1 = SubjectAttentionItem(
        subject_id=1,
        subject_name="Mathematics",
        subject_code="MAT",
        attentions=[att1, att2],
    )

    doc = StudentSubjectAttentionDocument(
        student_id=101,
        student_name="Rahul Varma",
        school_id=1,
        branch_id=1,
        academic_year_id=2026,
        class_id=10,
        class_name="Class 10",
        section_id=1,
        section_name="A",
        subjects=[sub1],
        last_evaluated_at=now,
        created_at=now,
        updated_at=now,
    )

    # Trigger recalculation
    doc.recalculate_counts()

    # att1 is ACTIVE & CRITICAL, att2 is RESOLVED
    assert doc.subjects[0].active_attentions_count == 1
    assert doc.total_active_attentions == 1
    assert doc.critical_attentions_count == 1
