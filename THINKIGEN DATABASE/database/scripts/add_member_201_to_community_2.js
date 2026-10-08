/* ============================================================================
   THINKIGEN Connect — Add Member to Community
   Script:      add_member_201_to_community_2.js
   Database:    MongoDB (Thinkigen)
   Target:      Add user_id: 201 (Karishma Shaik) to community_id: 2
   Action:      1. Insert/Upsert membership in connect_community_member
                2. Resolve any pending join request in connect_community_join_request
                3. Recalculate and update member_count and updated_at in connect_community
   Compliance:  Strict BSON Schema, NumberInt for integers, tenant boundaries.
   ============================================================================ */

(function () {
    const communityId = NumberInt(2);
    const targetUserId = NumberInt(201);
    const schoolId = NumberInt(1);
    const branchId = NumberInt(1);
    const now = new Date();

    print("=================================================================");
    print("THINKIGEN CONNECT — ADDING MEMBER TO COMMUNITY 2");
    print("Community ID: " + communityId + " | Target User ID: " + targetUserId);
    print("=================================================================");

    // 1. Verify community exists
    const community = db.connect_community.findOne({ community_id: communityId });
    if (!community) {
        throw new Error("Community with community_id: " + communityId + " not found!");
    }
    print("✔ Found community: \"" + community.name + "\" (current member_count: " + community.member_count + ")");

    // 2. Determine display name and role (lookup from existing membership or default)
    let displayName = "Karishma Shaik";
    let userRole = "student";

    const existingMemberInfo = db.connect_community_member.findOne({ user_id: targetUserId });
    if (existingMemberInfo) {
        if (existingMemberInfo.display_name) displayName = existingMemberInfo.display_name;
        if (existingMemberInfo.user_role) userRole = existingMemberInfo.user_role;
        print("✔ Found user profile in database: \"" + displayName + "\" (" + userRole + ")");
    } else {
        print("ℹ Using default profile: \"" + displayName + "\" (" + userRole + ")");
    }

    // 3. Upsert into connect_community_member
    const memberDoc = {
        community_id: communityId,
        user_id: targetUserId,
        school_id: schoolId,
        branch_id: branchId,
        display_name: displayName,
        user_role: userRole,
        member_role: "member",
        membership_status: "joined",
        joined_at: now,
        left_at: null
    };

    try {
        const memberRes = db.connect_community_member.updateOne(
            { community_id: communityId, user_id: targetUserId },
            { $set: memberDoc },
            { upsert: true }
        );
        print("✔ Upserted connect_community_member: " + JSON.stringify(memberRes));
    } catch (err) {
        print("❌ Validation failed on connect_community_member:");
        if (err.errInfo && err.errInfo.details) {
            print(JSON.stringify(err.errInfo.details, null, 2));
        } else {
            print(err.message);
        }
        throw err;
    }

    // 4. Resolve any pending join request for this user & community if it exists
    if (db.getCollectionNames().includes("connect_community_join_request")) {
        const reqRes = db.connect_community_join_request.updateMany(
            { community_id: communityId, user_id: targetUserId, status: "pending" },
            { $set: { status: "accepted", updated_at: now } }
        );
        if (reqRes.matchedCount > 0) {
            print("✔ Accepted " + reqRes.modifiedCount + " pending join request(s) in connect_community_join_request.");
        }
    }

    // 5. Recalculate exact total joined members in connect_community_member
    const totalJoinedMembers = db.connect_community_member.countDocuments({
        community_id: communityId,
        membership_status: "joined"
    });
    print("✔ Actual joined member count in database for community " + communityId + ": " + totalJoinedMembers);

    // 6. Update connect_community with new member_count, updated_at, and updated_by
    const updateRes = db.connect_community.updateOne(
        { community_id: communityId },
        {
            $set: {
                member_count: NumberInt(totalJoinedMembers),
                updated_at: now,
                updated_by: targetUserId
            }
        }
    );
    print("✔ Updated connect_community metadata: " + JSON.stringify(updateRes));

    // 7. Verification output
    const updatedCommunity = db.connect_community.findOne(
        { community_id: communityId },
        { community_id: 1, name: 1, member_count: 1, updated_at: 1, updated_by: 1, _id: 0 }
    );
    print("\n-----------------------------------------------------------------");
    print("VERIFICATION RESULT:");
    print(JSON.stringify(updatedCommunity, null, 2));

    const verifyMember = db.connect_community_member.findOne(
        { community_id: communityId, user_id: targetUserId },
        { _id: 0 }
    );
    print("\nMEMBER RECORD:");
    print(JSON.stringify(verifyMember, null, 2));
    print("-----------------------------------------------------------------");
    print("SUCCESS: user_id: 201 added as member to community_id: 2!");
    print("=================================================================");
})();
