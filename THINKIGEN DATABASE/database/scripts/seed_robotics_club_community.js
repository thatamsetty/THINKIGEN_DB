/* ============================================================================
   THINKIGEN Connect — Community Mock Seeder
   Script:    seed_robotics_club_community.js
   Database:  MongoDB (Prasad / thinkigen)
   Purpose:   Create "Robotics & Artificial Intelligence Club" (community_id: 2)
              in connect_community with Faculty Priya as owner and 8 student members
              in connect_community_member.
   Compliance: Strict BSON Schema, branch-scoped, 32-bit Integer format (NumberInt).
   ============================================================================ */

(function () {
    const communityId = NumberInt(2);
    const schoolId = NumberInt(1);
    const branchId = NumberInt(1);
    const ownerUserId = NumberInt(4); // Teacher 2: Priya Faculty (Mathematics / STEM)
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
        name: "Robotics & Artificial Intelligence Club",
        community_type: "club",
        description: "A student-driven hub for robotics engineering, IoT prototyping, autonomous systems, and AI/ML project competitions.",
        owner_user_id: ownerUserId,
        member_count: NumberInt(9), // 1 Faculty Owner + 8 Student Members
        is_trending: true,
        is_active: true,
        created_at: now,
        updated_at: now,
        created_by: ownerUserId,
        updated_by: ownerUserId
    };

    const commRes = db.connect_community.updateOne(
        { community_id: communityId },
        { $set: communityDoc },
        { upsert: true }
    );
    print("✔ Upserted connect_community (community_id: 2):", JSON.stringify(commRes));

    // -------------------------------------------------------------------------
    // 2. Insert / Upsert Members into connect_community_member
    // -------------------------------------------------------------------------
    const members = [
        // 1. Faculty Coordinator & Club Owner
        {
            community_id: communityId,
            user_id: ownerUserId,
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Priya Faculty",
            user_role: "teacher",
            member_role: "owner",
            membership_status: "joined",
            joined_at: now,
            left_at: null
        },
        // 2. Student Members from existing SSMS mock data
        {
            community_id: communityId,
            user_id: NumberInt(5), // Student 3: Vihaan Kumar
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Vihaan Kumar",
            user_role: "student",
            member_role: "moderator",
            membership_status: "joined",
            joined_at: now,
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(7), // Student 4: Diya Kumar
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Diya Kumar",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: now,
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(9), // Student 5: Aditya Kumar
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Aditya Kumar",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: now,
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(11), // Student 6: Ishita Kumar
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Ishita Kumar",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: now,
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(13), // Student 7: Kabir Kumar
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Kabir Kumar",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: now,
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(15), // Student 8: Saanvi Kumar
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Saanvi Kumar",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: now,
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(17), // Student 9: Arnav Kumar
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Arnav Kumar",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: now,
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(19), // Student 10: Navya Kumar
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Navya Kumar",
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

    print(`✔ Seeded ${insertedCount} members (1 Teacher Owner + 8 Student Members) into connect_community_member.`);
    print("=================================================================");
    print("Robotics & AI Club creation completed successfully (all IDs as Int)!");
    print("=================================================================");
})();
