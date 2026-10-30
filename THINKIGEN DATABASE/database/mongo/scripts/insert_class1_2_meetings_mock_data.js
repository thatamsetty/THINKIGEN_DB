/* ========================================================================
   THINKIGEN SCHOOL ERP - MONGODB MOCK DATA SEED SCRIPT
   Script: database/mongo/scripts/insert_class1_2_meetings_mock_data.js
   Collection: connect_meeting
   Academic Year: 2026-2027 (academic_year_id = 1)
   Scope: school_id = 1, branch_id = 1 (Central Campus)
   Classes: Class 1 and Class 2 (Sections 1, 2, 3, 4)

   REQUIREMENTS COVERED:
   - 10 meetings for each section of Classes 1 and 2:
     * Class 1, Section A (section_id = 1): 10 meetings (5 completed, 5 upcoming)
     * Class 1, Section B (section_id = 2): 10 meetings (5 completed, 5 upcoming)
     * Class 2, Section A (section_id = 3): 10 meetings (5 completed, 5 upcoming)
     * Class 2, Section B (section_id = 4): 10 meetings (5 completed, 5 upcoming)
   - Total: 40 realistic meeting documents.
   - 5 upcoming meetings per section (20 upcoming meetings total across classes 1 & 2).
   - Strict 100% compliance with 009_connect_meeting.js validator and ROOT_FIELDS.
   - Run in mongosh:
       mongosh "mongodb://localhost:27017/thinkigen" insert_class1_2_meetings_mock_data.js
   ======================================================================== */

const DB_NAME = "thinkigen";
const COLLECTION_NAME = "connect_meeting";

const dbInstance = typeof db !== "undefined" ? db : connect("mongodb://localhost:27017/" + DB_NAME);

print("========================================================================");
print("SEEDING CONNECT_MEETING MOCK DATA: Classes 1 & 2 (Sections 1 to 4)");
print("========================================================================");

const baseCreatedAt = ISODate("2026-09-01T08:00:00Z");

// Teacher and student cohorts for Classes 1 & 2
const sectionConfigs = [
  {
    section_id: 1,
    section_label: "Class 1 - Section A",
    organizer: {
      user_id: NumberInt(101),
      name: "Keshav Kulkarni",
      role: "TEACHER",
      email: "tch_1201@schoolname.edu"
    },
    students: [201, 202, 203, 204, 205, 206, 207, 208, 209, 210].map(id => NumberInt(id)),
    room: "Room 101"
  },
  {
    section_id: 2,
    section_label: "Class 1 - Section B",
    organizer: {
      user_id: NumberInt(102),
      name: "Radhika Pillai",
      role: "TEACHER",
      email: "tch_1202@schoolname.edu"
    },
    students: [211, 212, 213, 214, 215, 216, 217, 218, 219, 220].map(id => NumberInt(id)),
    room: "Room 102"
  },
  {
    section_id: 3,
    section_label: "Class 2 - Section A",
    organizer: {
      user_id: NumberInt(103),
      name: "Mayank Mukherjee",
      role: "TEACHER",
      email: "tch_1203@schoolname.edu"
    },
    students: [221, 222, 223, 224, 225, 226, 227, 228, 229, 230].map(id => NumberInt(id)),
    room: "Room 201"
  },
  {
    section_id: 4,
    section_label: "Class 2 - Section B",
    organizer: {
      user_id: NumberInt(104),
      name: "Tara Mishra",
      role: "TEACHER",
      email: "tch_1204@schoolname.edu"
    },
    students: [231, 232, 233, 234, 235, 236, 237, 238, 239, 240].map(id => NumberInt(id)),
    room: "Room 202"
  }
];

// 10 meeting definitions: 5 Past/Completed + 5 Upcoming (Strictly Aligned with Timetable Dates)
const meetingTemplates = [
  // PAST / COMPLETED (5 meetings: Oct 06, Oct 09, Oct 14, Oct 20, Oct 23)
  {
    index: 1,
    title_suffix: "Term-1 Orientation & Student Learning Goals",
    status: "completed",
    type: "IN_PERSON",
    duration: 45,
    scheduled_at: ISODate("2026-10-06T10:00:00Z"),
    agenda: [
      { agenda_id: NumberInt(1), title: "Welcome & Academic Objectives" },
      { agenda_id: NumberInt(2), title: "Textbook & Digital Portal Overview" }
    ]
  },
  {
    index: 2,
    title_suffix: "Foundational Literacy & Phonics Assessment Review",
    status: "completed",
    type: "VIRTUAL",
    duration: 30,
    scheduled_at: ISODate("2026-10-09T14:30:00Z"),
    agenda: [
      { agenda_id: NumberInt(1), title: "Phonics & Reading Fluency Benchmark" },
      { agenda_id: NumberInt(2), title: "Home Reading Guidelines" }
    ]
  },
  {
    index: 3,
    title_suffix: "Numerical Skills & Mental Mathematics Clinic",
    status: "completed",
    type: "IN_PERSON",
    duration: 45,
    scheduled_at: ISODate("2026-10-14T11:00:00Z"),
    agenda: [
      { agenda_id: NumberInt(1), title: "Number Systems & Counting Games" },
      { agenda_id: NumberInt(2), title: "Workbook Exercise Feedback" }
    ]
  },
  {
    index: 4,
    title_suffix: "Mid-Term Periodic Progress & Formative Review",
    status: "completed",
    type: "VIRTUAL",
    duration: 40,
    scheduled_at: ISODate("2026-10-20T15:00:00Z"),
    agenda: [
      { agenda_id: NumberInt(1), title: "Mid-Term Assessment Analysis" },
      { agenda_id: NumberInt(2), title: "Individual Student Milestone Review" }
    ]
  },
  {
    index: 5,
    title_suffix: "Creative Arts, Physical Health & Social Habits Review",
    status: "completed",
    type: "IN_PERSON",
    duration: 45,
    scheduled_at: ISODate("2026-10-23T10:30:00Z"),
    agenda: [
      { agenda_id: NumberInt(1), title: "Personal Development & Classroom Decorum" },
      { agenda_id: NumberInt(2), title: "Sports & Fine Arts Participation" }
    ]
  },

  // UPCOMING (5 meetings: Oct 28, Nov 04, Nov 18, Dec 02, Dec 16)
  {
    index: 6,
    title_suffix: "Term-2 Learning Plan & Activity-Based Curriculum Guidance",
    status: "scheduled",
    type: "VIRTUAL",
    duration: 45,
    scheduled_at: ISODate("2026-10-28T14:00:00Z"),
    agenda: [
      { agenda_id: NumberInt(1), title: "Term-2 Chapter Milestones" },
      { agenda_id: NumberInt(2), title: "Hands-on Science Project Demonstrations" }
    ]
  },
  {
    index: 7,
    title_suffix: "Parent-Teacher Consultation & Behavioral Development Check",
    status: "scheduled",
    type: "IN_PERSON",
    duration: 60,
    scheduled_at: ISODate("2026-11-04T09:30:00Z"),
    agenda: [
      { agenda_id: NumberInt(1), title: "One-on-One Parent Check-in" },
      { agenda_id: NumberInt(2), title: "Collaborative Study Habits Formation" }
    ]
  },
  {
    index: 8,
    title_suffix: "Periodic Assessment 3 Preparatory Strategy Meeting",
    status: "scheduled",
    type: "VIRTUAL",
    duration: 35,
    scheduled_at: ISODate("2026-11-18T15:30:00Z"),
    agenda: [
      { agenda_id: NumberInt(1), title: "Exam Schedule & Revision Routine" },
      { agenda_id: NumberInt(2), title: "Question Pattern & Practice Worksheets" }
    ]
  },
  {
    index: 9,
    title_suffix: "Winter Science Fair Project Collaboration & Showcase Prep",
    status: "scheduled",
    type: "IN_PERSON",
    duration: 45,
    scheduled_at: ISODate("2026-12-02T11:15:00Z"),
    agenda: [
      { agenda_id: NumberInt(1), title: "Group Model Review" },
      { agenda_id: NumberInt(2), title: "Presentation Rubrics & Setup Guidance" }
    ]
  },
  {
    index: 10,
    title_suffix: "End-of-Term Comprehensive Review & Winter Break Roadmap",
    status: "scheduled",
    type: "VIRTUAL",
    duration: 45,
    scheduled_at: ISODate("2026-12-16T14:00:00Z"),
    agenda: [
      { agenda_id: NumberInt(1), title: "Term-2 Academic Summary" },
      { agenda_id: NumberInt(2), title: "Winter Enrichment Reading Assignment" }
    ]
  }
];

const documents = [];
let meetingCounter = 1000;

sectionConfigs.forEach(sec => {
  meetingTemplates.forEach(tmpl => {
    meetingCounter++;
    const isVirtual = tmpl.type === "VIRTUAL";
    const meetCode = "thk-c" + sec.section_id + "-m" + tmpl.index;

    const doc = {
      meeting_id: NumberLong(String(meetingCounter)),
      school_id: NumberInt(1),
      branch_id: NumberInt(1),
      academic_year_id: NumberInt(1),
      title: sec.section_label + ": " + tmpl.title_suffix,
      status: tmpl.status,
      meeting_type: tmpl.type,
      scheduled_at: tmpl.scheduled_at,
      duration_minutes: NumberInt(tmpl.duration),
      organizer: {
        user_id: sec.organizer.user_id,
        name: sec.organizer.name,
        role: sec.organizer.role,
        email: sec.organizer.email
      },
      targets: [
        {
          target_type: "USER",
          role: "STUDENT",
          user_ids: sec.students
        }
      ],
      agenda: tmpl.agenda,
      online_details: isVirtual
        ? {
            platform: "GOOGLE_MEET",
            meeting_url: "https://meet.google.com/" + meetCode
          }
        : null,
      location: isVirtual ? null : "Central Campus Academic Block",
      room_no: isVirtual ? null : sec.room,
      resources: [],
      notification_reminder: {
        enabled: true,
        minutes_before: NumberInt(15)
      },
      is_active: true,
      created_at: baseCreatedAt,
      updated_at: baseCreatedAt,
      created_by: sec.organizer.user_id,
      updated_by: sec.organizer.user_id
    };

    documents.push(doc);
  });
});

print("Prepared " + documents.length + " meeting documents across 4 sections (10 each).");

// Insert documents with idempotent check
let insertedCount = 0;
documents.forEach(doc => {
  const existing = dbInstance[COLLECTION_NAME].findOne({ meeting_id: doc.meeting_id });
  if (!existing) {
    dbInstance[COLLECTION_NAME].insertOne(doc);
    insertedCount++;
  }
});

print("Successfully inserted " + insertedCount + " new connect_meeting documents.");

// Verification summary
print("");
print("--- SUMMARY OF CONNECT_MEETING DOCUMENTS IN DB ---");
const counts = dbInstance[COLLECTION_NAME].aggregate([
  { $match: { school_id: 1, branch_id: 1 } },
  {
    $group: {
      _id: "$status",
      count: { $sum: 1 },
      min_date: { $min: "$scheduled_at" },
      max_date: { $max: "$scheduled_at" }
    }
  }
]).toArray();

printjson(counts);
print("CONNECT_MEETING SEEDING COMPLETED SUCCESSFULLY.");
