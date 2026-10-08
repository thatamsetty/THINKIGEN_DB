/* ============================================================================
   THINKIGEN Connect — Community Mock Seeder
   Script:    seed_literary_society_community.js
   Database:  MongoDB (Prasad / thinkigen)
   Purpose:   Create "Literary & Debate Society" (community_id: 3)
              in connect_community with Teacher Arjun Faculty as head (owner),
              and 4 student members (student_id: 1, 2, 3, 4) in connect_community_member.
   Compliance: Strict BSON Schema, branch-scoped, 32-bit Integer format (NumberInt).
   ============================================================================ */

(function () {
    const communityId = NumberInt(3);
    const schoolId = NumberInt(1);
    const branchId = NumberInt(1);
    const teacherArjunUserId = NumberInt(2); // teacher_id: 1 (Arjun Faculty, English Dept)
    const now = new Date();

    // -------------------------------------------------------------------------
    // 0. Ensure target collections exist
    // -------------------------------------------------------------------------
    if (!db.getCollectionNames().includes("connect_community")) {
        print("Creating connect_community collection...");
        db.createCollection("connect_community");
    }
    if (!db.getCollectionNames().includes("connect_community_member")) {
        print("Creating connect_community_member collection...");
        db.createCollection("connect_community_member");
    }

    // -------------------------------------------------------------------------
    // 1. Insert / Upsert Community Document into connect_community
    // -------------------------------------------------------------------------
    const communityDoc = {
        community_id: communityId,
        school_id: schoolId,
        branch_id: branchId,
        name: "Literary & Debate Society",
        community_type: "club",
        description: "A forum for students passionate about public speaking, parliamentary debate, creative writing, and literary competitions under faculty mentorship.",
        owner_user_id: teacherArjunUserId,
        member_count: NumberInt(5), // 1 Teacher Head + 4 Student Members
        is_trending: true,
        is_active: true,
        created_at: now,
        updated_at: now,
        created_by: teacherArjunUserId,
        updated_by: teacherArjunUserId
    };

    const commRes = db.connect_community.updateOne(
        { community_id: communityId },
        { $set: communityDoc },
        { upsert: true }
    );
    print("✔ Upserted connect_community (community_id: 3):", JSON.stringify(commRes));

    // -------------------------------------------------------------------------
    // 2. Insert / Upsert Members into connect_community_member
    //    1 Teacher Head + 4 Student Members using authentic SSMS mock data IDs
    // -------------------------------------------------------------------------
    const members = [
        // 1. Teacher Head (Owner) -> teacher_id: 1, user_id: 2
        {
            community_id: communityId,
            user_id: teacherArjunUserId,
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Arjun Faculty",
            user_role: "teacher",
            member_role: "owner",
            membership_status: "joined",
            joined_at: now,
            left_at: null
        },
        // 2. Student Member 1 -> student_id: 1, user_id: 1 (Aarav Kumar)
        {
            community_id: communityId,
            user_id: NumberInt(1),
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Aarav Kumar",
            user_role: "student",
            member_role: "moderator",
            membership_status: "joined",
            joined_at: now,
            left_at: null
        },
        // 3. Student Member 2 -> student_id: 2, user_id: 3 (Anika Kumar)
        {
            community_id: communityId,
            user_id: NumberInt(3),
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Anika Kumar",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: now,
            left_at: null
        },
        // 4. Student Member 3 -> student_id: 3, user_id: 5 (Vihaan Kumar)
        {
            community_id: communityId,
            user_id: NumberInt(5),
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Vihaan Kumar",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: now,
            left_at: null
        },
        // 5. Student Member 4 -> student_id: 4, user_id: 7 (Diya Kumar)
        {
            community_id: communityId,
            user_id: NumberInt(7),
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Diya Kumar",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: now,
            left_at: null
        }
    ];

    let insertedCount = 0;
    members.forEach(function (m) {
        db.connect_community_member.updateOne(
            { community_id: m.community_id, user_id: m.user_id },
            { $set: m },
            { upsert: true }
        );
        insertedCount++;
    });

    print(`✔ Seeded ${insertedCount} members (1 Teacher Head + 4 Student Members) into connect_community_member.`);
    print("=================================================================");
    print("Literary & Debate Society creation completed successfully (all IDs as Int)!");
    print("=================================================================");
})();
