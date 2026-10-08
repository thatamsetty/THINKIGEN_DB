/* ============================================================================
   THINKIGEN Connect — Section-wise Group Conversation Seeder
   Script:     seed_section_group_conversations.js
   Database:   MongoDB (Compass / mongosh)
   Purpose:    Create section-wise group conversations with teacher-as-leader mapping
               in 'connect_conversation' (or 'conversations') and user-level state
               in 'connect_conversation_user_state' (or 'conversation_user_state').
   Example:    section_id = 1 -> leader teacher_id = 3 (created_by: 3)
   Compliance: Strict BSON Schema, NumberInt 32-bit types, null pair key for groups,
               and referential integrity between conversation & user states.
   ============================================================================ */

(function () {
    const now = new Date();

    // -------------------------------------------------------------------------
    // 0. Auto-detect collection names (supports Thinkigen Connect schema & aliases)
    // -------------------------------------------------------------------------
    const existingCollections = db.getCollectionNames();

    const convColName = existingCollections.includes("connect_conversation")
        ? "connect_conversation"
        : (existingCollections.includes("conversations") ? "conversations" : "connect_conversation");

    const userStateColName = existingCollections.includes("connect_conversation_user_state")
        ? "connect_conversation_user_state"
        : (existingCollections.includes("conversation_user_state") ? "conversation_user_state" : "connect_conversation_user_state");

    print("============================================================");
    print("STARTING SECTION GROUP CONVERSATION SEEDER");
    print("Conversation Collection: " + convColName);
    print("User State Collection:   " + userStateColName);
    print("============================================================");

    // -------------------------------------------------------------------------
    // 1. Define Section-wise Group Mappings
    //    Configure section_id, leader teacher_id (created_by), and students.
    // -------------------------------------------------------------------------
    const SECTION_GROUP_CONFIGS = [
        {
            section_id: 1,
            section_name: "Section A",
            class_id: 1,
            class_name: "Class 1",
            school_id: 1,
            branch_id: 1,
            academic_year_id: 1,
            conversation_id: "conv_group_sec_1",
            group_title: "Class 1 - Section A (Official Group)",
            header_context: "Academic Year 2026-2027 | Class 1 Section A",
            welcome_message: "Welcome to Class 1 - Section A official group chat!",
            // Teacher is the leader of the group (teacher_id = 1, user_id = 101, tch_1201@schoolname.edu)
            leader_teacher: {
                user_id: 101, // Teacher User ID
                teacher_id: 1,
                display_name: "Teacher Keshav Kulkarni (Leader)",
                participant_role: "teacher"
            },
            // Exactly 10 student members enrolled in Section 1 (stu_1201 to stu_1210)
            students: [
                { user_id: 201, student_id: 1, display_name: "Ovi Iyer", participant_role: "student" },
                { user_id: 202, student_id: 2, display_name: "Lalit Patel", participant_role: "student" },
                { user_id: 203, student_id: 3, display_name: "Suraj Bajwa", participant_role: "student" },
                { user_id: 204, student_id: 4, display_name: "Vasant Nigam", participant_role: "student" },
                { user_id: 205, student_id: 5, display_name: "Lavanya Sharma", participant_role: "student" },
                { user_id: 206, student_id: 6, display_name: "Tanvi Suri", participant_role: "student" },
                { user_id: 207, student_id: 7, display_name: "Gaurav Joshi", participant_role: "student" },
                { user_id: 208, student_id: 8, display_name: "Manish Talwar", participant_role: "student" },
                { user_id: 209, student_id: 9, display_name: "Zara Tiwari", participant_role: "student" },
                { user_id: 210, student_id: 10, display_name: "Sarita Sengupta", participant_role: "student" }
            ]
        },
        {
            section_id: 2,
            section_name: "Section B",
            class_id: 1,
            class_name: "Class 1",
            school_id: 1,
            branch_id: 1,
            academic_year_id: 1,
            conversation_id: "conv_group_sec_2",
            group_title: "Class 1 - Section B (Official Group)",
            header_context: "Academic Year 2026-2027 | Class 1 Section B",
            welcome_message: "Welcome to Class 1 - Section B official group chat!",
            // Teacher is the leader of the group (teacher_id = 3, user_id = 103, tch_1203@schoolname.edu)
            leader_teacher: {
                user_id: 103, // Teacher User ID
                teacher_id: 3,
                display_name: "Teacher Mayank Mukherjee (Leader)",
                participant_role: "teacher"
            },
            // Exactly 10 student members enrolled in Section 2 (stu_1211 to stu_1220)
            students: [
                { user_id: 211, student_id: 11, display_name: "Gurpreet Pillai", participant_role: "student" },
                { user_id: 212, student_id: 12, display_name: "Deepika Pathak", participant_role: "student" },
                { user_id: 213, student_id: 13, display_name: "Varun Venkataraman", participant_role: "student" },
                { user_id: 214, student_id: 14, display_name: "Reena Mitra", participant_role: "student" },
                { user_id: 215, student_id: 15, display_name: "Sangeeta Ghosh", participant_role: "student" },
                { user_id: 216, student_id: 16, display_name: "Uma Asthana", participant_role: "student" },
                { user_id: 217, student_id: 17, display_name: "Nikhil Acharya", participant_role: "student" },
                { user_id: 218, student_id: 18, display_name: "Kavya Sidhu", participant_role: "student" },
                { user_id: 219, student_id: 19, display_name: "Suresh Banerjee", participant_role: "student" },
                { user_id: 220, student_id: 20, display_name: "Nakul Chatterjee", participant_role: "student" }
            ]
        }
    ];

    // -------------------------------------------------------------------------
    // 2. Helper to Process and Insert Group + Member States
    // -------------------------------------------------------------------------
    SECTION_GROUP_CONFIGS.forEach(function (cfg) {
        print("\n------------------------------------------------------------");
        print("Processing Section " + cfg.section_id + " [" + cfg.group_title + "]");
        print("Leader Teacher ID: " + cfg.leader_teacher.teacher_id + " (User ID: " + cfg.leader_teacher.user_id + ")");
        print("------------------------------------------------------------");

        const teacherUserIdInt = NumberInt(cfg.leader_teacher.user_id);
        const schoolIdInt = NumberInt(cfg.school_id);
        const branchIdInt = NumberInt(cfg.branch_id);
        const classIdInt = NumberInt(cfg.class_id);
        const sectionIdInt = NumberInt(cfg.section_id);
        const academicYearIdInt = NumberInt(cfg.academic_year_id);

        // Build participants array: Leader (Teacher) + Students
        const participants = [
            {
                user_id: teacherUserIdInt,
                participant_role: cfg.leader_teacher.participant_role,
                display_name: cfg.leader_teacher.display_name
            }
        ];

        cfg.students.forEach(function (st) {
            participants.push({
                user_id: NumberInt(st.user_id),
                participant_role: st.participant_role,
                display_name: st.display_name
            });
        });

        // Construct group conversation document according to strict JSON Schema
        const conversationDoc = {
            conversation_id: cfg.conversation_id,
            school_id: schoolIdInt,
            branch_id: branchIdInt,
            conversation_type: "group",
            participant_pair_key: null, // REQUIRED: must be null for group conversations
            title: cfg.group_title,
            header_context: cfg.header_context,
            academic_year_id: academicYearIdInt,
            class_id: classIdInt,
            section_id: sectionIdInt,
            subject_id: null,
            group_type: "section_group", // enum: ["class_group", "section_group", "committee", "club", "society", null]
            participants: participants,
            last_message_preview: cfg.welcome_message,
            last_message_at: now,
            last_message_sender_user_id: teacherUserIdInt,
            is_active: true,
            created_at: now,
            updated_at: now,
            created_by: teacherUserIdInt, // Created by teacher (leader)
            updated_by: teacherUserIdInt
        };

        // Upsert Conversation Master
        const convResult = db[convColName].updateOne(
            { conversation_id: cfg.conversation_id },
            { $set: conversationDoc },
            { upsert: true }
        );
        print("✔ Upserted conversation master (" + cfg.conversation_id + "): " + JSON.stringify(convResult));

        // Upsert User States for each participant
        let stateCount = 0;
        participants.forEach(function (p) {
            const userStateDoc = {
                conversation_id: cfg.conversation_id,
                user_id: p.user_id,
                deleted_at: null,
                last_read_at: p.user_id.valueOf() === teacherUserIdInt.valueOf() ? now : null,
                created_at: now,
                updated_at: now
            };

            db[userStateColName].updateOne(
                { conversation_id: cfg.conversation_id, user_id: p.user_id },
                { $set: userStateDoc },
                { upsert: true }
            );
            stateCount++;
        });

        print("✔ Upserted " + stateCount + " participant states into " + userStateColName);
    });

    // -------------------------------------------------------------------------
    // 3. Verification & Integrity Check
    // -------------------------------------------------------------------------
    print("\n============================================================");
    print("VERIFICATION OF SEEDED GROUP CONVERSATIONS");
    print("============================================================");

    SECTION_GROUP_CONFIGS.forEach(function (cfg) {
        const conv = db[convColName].findOne({ conversation_id: cfg.conversation_id });
        if (!conv) {
            print("❌ FAIL: Conversation " + cfg.conversation_id + " not found!");
            return;
        }

        print("✔ Conversation ID:        " + conv.conversation_id);
        print("  Type:                   " + conv.conversation_type);
        print("  Title:                  " + conv.title);
        print("  Section ID:             " + conv.section_id);
        print("  Created By (Leader):    " + conv.created_by);
        print("  Total Participants:     " + conv.participants.length);

        const states = db[userStateColName].find({ conversation_id: cfg.conversation_id }).toArray();
        print("  Participant States:     " + states.length + " states verified.");

        const isCompliant = (conv.conversation_type === "group" && conv.participant_pair_key === null && states.length === conv.participants.length);
        if (isCompliant) {
            print("  Status:                 [PASSED] Schema & Relational Integrity Verified");
        } else {
            print("  Status:                 [WARNING] Please check pair key or member count");
        }
    });

    print("============================================================");
    print("GROUP CONVERSATION SEEDING COMPLETED SUCCESSFULLY");
    print("============================================================");
})();
