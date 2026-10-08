/*
    Insert two section group conversations into connect_conversation.
    Run in mongosh against the Thinkigen database.

    Group 1: school 1, branch 1, class 1, section 1
             admin = section teacher user 101
             students = user 201 through 210
    Group 2: school 1, branch 1, class 1, section 2
             admin = section teacher user 103
             students = user 211 through 220
*/
const now = ISODate("2026-04-01T08:00:00Z");

const documents = [
  {
    conversation_id: "conv_group_class1_section1",
    school_id: NumberInt(1),
    branch_id: NumberInt(1),
    conversation_type: "group",
    participant_pair_key: null,
    title: "Class 1 - Section A",
    header_context: "Academic Year 2026-2027 | Class 1 Section A",
    academic_year_id: NumberInt(1),
    class_id: NumberInt(1),
    section_id: NumberInt(1),
    subject_id: null,
    group_type: "section_group",
    participants: [
      { user_id: NumberInt(101), participant_role: "admin", display_name: "Keshav Kulkarni" },
      { user_id: NumberInt(201), participant_role: "student", display_name: "Karishma Shaik" },
      { user_id: NumberInt(202), participant_role: "student", display_name: "Dhamodhar Rao" },
      { user_id: NumberInt(203), participant_role: "student", display_name: "Sita Ram" },
      { user_id: NumberInt(204), participant_role: "student", display_name: "Krupa Joseph" },
      { user_id: NumberInt(205), participant_role: "student", display_name: "Jeswanth Reddy" },
      { user_id: NumberInt(206), participant_role: "student", display_name: "Sravan Kumar" },
      { user_id: NumberInt(207), participant_role: "student", display_name: "Gaurav Joshi" },
      { user_id: NumberInt(208), participant_role: "student", display_name: "Manish Talwar" },
      { user_id: NumberInt(209), participant_role: "student", display_name: "Zara Tiwari" },
      { user_id: NumberInt(210), participant_role: "student", display_name: "Sarita Sengupta" }
    ],
    last_message_preview: null,
    last_message_at: null,
    last_message_sender_user_id: null,
    is_active: true,
    created_at: now,
    updated_at: now,
    created_by: NumberInt(101),
    updated_by: NumberInt(101)
  },
  {
    conversation_id: "conv_group_class1_section2",
    school_id: NumberInt(1),
    branch_id: NumberInt(1),
    conversation_type: "group",
    participant_pair_key: null,
    title: "Class 1 - Section B",
    header_context: "Academic Year 2026-2027 | Class 1 Section B",
    academic_year_id: NumberInt(1),
    class_id: NumberInt(1),
    section_id: NumberInt(2),
    subject_id: null,
    group_type: "section_group",
    participants: [
      { user_id: NumberInt(103), participant_role: "admin", display_name: "Mayank Mukherjee" },
      { user_id: NumberInt(211), participant_role: "student", display_name: "Gurpreet Pillai" },
      { user_id: NumberInt(212), participant_role: "student", display_name: "Deepika Pathak" },
      { user_id: NumberInt(213), participant_role: "student", display_name: "Varun Venkataraman" },
      { user_id: NumberInt(214), participant_role: "student", display_name: "Reena Mitra" },
      { user_id: NumberInt(215), participant_role: "student", display_name: "Sangeeta Ghosh" },
      { user_id: NumberInt(216), participant_role: "student", display_name: "Uma Asthana" },
      { user_id: NumberInt(217), participant_role: "student", display_name: "Nikhil Acharya" },
      { user_id: NumberInt(218), participant_role: "student", display_name: "Kavya Sidhu" },
      { user_id: NumberInt(219), participant_role: "student", display_name: "Suresh Banerjee" },
      { user_id: NumberInt(220), participant_role: "student", display_name: "Nakul Chatterjee" }
    ],
    last_message_preview: null,
    last_message_at: null,
    last_message_sender_user_id: null,
    is_active: true,
    created_at: now,
    updated_at: now,
    created_by: NumberInt(103),
    updated_by: NumberInt(103)
  }
];

const result = db.connect_conversation.insertMany(documents);
print("Inserted conversation ids: " + result.insertedIds);
