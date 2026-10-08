/* ============================================================================
   THINKIGEN Connect — Community Activity Seeder
   Script:      seed_robotics_ai_club_community.js
   Database:    MongoDB (Thinkigen)
   Target:      Robotics & AI Innovation Club (community_id: 3)
   Owner:       Teacher / Community Owner: Mayank Mukherjee (user_id: 103)
   Description: Creates community_id: 3 with owner user_id: 103 and seeds:
                - 6 Members (1 Teacher Owner + 5 Students) in connect_community_member,
                - 2 Posts (post_id: 9, 10) in connect_community_post,
                - 3 Discussions (discussion_id: 10, 11, 12) in connect_community_discussion,
                - 3 Polls (poll_id: 10, 11, 12) in connect_community_poll,
                all activity authored/created by user_id: 103.
                Conforms strictly to MongoDB Atlas schema rules, tenant
                boundaries (school_id: 1, branch_id: 1), and BSON NumberInt.
   ============================================================================ */

(function () {
    const communityId = NumberInt(3);
    const schoolId = NumberInt(1);
    const branchId = NumberInt(1);
    const ownerUserId = NumberInt(103); // Teacher Mayank Mukherjee (owner)

    print("=================================================================");
    print("THINKIGEN CONNECT — SEEDING ROBOTICS & AI INNOVATION CLUB");
    print("Community ID: " + communityId + " | School ID: " + schoolId + " | Branch ID: " + branchId);
    print("Owner / Creator: user_id " + ownerUserId + " (Teacher Mayank Mukherjee)");
    print("=================================================================");

    // -------------------------------------------------------------------------
    // 0. Ensure target collections exist
    // -------------------------------------------------------------------------
    const requiredCollections = [
        "connect_community",
        "connect_community_member",
        "connect_community_post",
        "connect_community_discussion",
        "connect_community_poll"
    ];

    requiredCollections.forEach(function (colName) {
        if (!db.getCollectionNames().includes(colName)) {
            print("Creating collection: " + colName);
            db.createCollection(colName);
        }
    });

    // -------------------------------------------------------------------------
    // 1. Define Members for Community 3 (1 Teacher Owner + 5 Student Members = 6 total)
    // -------------------------------------------------------------------------
    const members = [
        {
            community_id: communityId,
            user_id: ownerUserId, // 103
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Mayank Mukherjee",
            user_role: "teacher",
            member_role: "owner",
            membership_status: "joined",
            joined_at: ISODate("2026-09-22T14:30:00.000Z"),
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(211),
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Gurpreet Pillai",
            user_role: "student",
            member_role: "moderator",
            membership_status: "joined",
            joined_at: ISODate("2026-09-22T14:35:00.000Z"),
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(212),
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Deepika Pathak",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: ISODate("2026-09-22T14:40:00.000Z"),
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(213),
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Varun Venkataraman",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: ISODate("2026-09-22T14:45:00.000Z"),
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(214),
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Reena Mitra",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: ISODate("2026-09-22T14:50:00.000Z"),
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(215),
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Sangeeta Ghosh",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: ISODate("2026-09-22T14:55:00.000Z"),
            left_at: null
        }
    ];

    // -------------------------------------------------------------------------
    // 2. Insert / Upsert Community Document into connect_community
    // -------------------------------------------------------------------------
    const communityDoc = {
        community_id: communityId,
        branch_id: branchId,
        school_id: schoolId,
        community_type: "club",
        name: "Robotics & AI Innovation Club",
        description: "Hands-on makerspace for autonomous mobile robotics, sensor telemetry, microcontrollers (Arduino/Raspberry Pi), computer vision, and applied machine learning.",
        owner_user_id: ownerUserId,
        member_count: NumberInt(members.length), // 6 members
        is_trending: true,
        is_active: true,
        created_at: ISODate("2026-09-22T14:30:00.000Z"),
        updated_at: ISODate("2026-09-22T14:30:00.000Z"),
        created_by: ownerUserId,
        updated_by: ownerUserId
    };

    const commRes = db.connect_community.updateOne(
        { community_id: communityId },
        { $set: communityDoc },
        { upsert: true }
    );
    print("✔ Upserted connect_community (community_id: 3): " + JSON.stringify(commRes));

    // -------------------------------------------------------------------------
    // 3. Insert / Upsert Members into connect_community_member
    // -------------------------------------------------------------------------
    let memberUpsertCount = 0;
    members.forEach(function (m) {
        try {
            db.connect_community_member.updateOne(
                { community_id: m.community_id, user_id: m.user_id },
                { $set: m },
                { upsert: true }
            );
            memberUpsertCount++;
        } catch (err) {
            print("❌ Validation failed on connect_community_member (user_id: " + m.user_id + "):");
            if (err.errInfo && err.errInfo.details) {
                print(JSON.stringify(err.errInfo.details, null, 2));
            } else {
                print(err.message);
            }
            throw err;
        }
    });
    print("✔ Seeded " + memberUpsertCount + " members (1 Teacher Owner + 5 Students) into connect_community_member.");

    // Helper to dynamically adapt documents to the active collection validator
    function adaptToSchema(doc, schema) {
        if (!schema) {
            doc.branch_id = branchId;
            return;
        }
        const req = schema.required || [];
        const props = schema.properties || {};

        if (req.includes("branch_id") || props.branch_id || schema.additionalProperties !== false) {
            doc.branch_id = branchId;
        }
        if (req.includes("school_id") || props.school_id || schema.additionalProperties !== false) {
            doc.school_id = schoolId;
        }
        if (req.includes("share_count")) {
            doc.share_count = NumberInt(0);
        }
        if (req.includes("updated_at") && doc.updated_at === undefined) {
            doc.updated_at = null;
        }
    }

    // -------------------------------------------------------------------------
    // 4. Insert / Upsert 2 Posts (post_id: 9, 10) into connect_community_post
    // -------------------------------------------------------------------------
    const postColInfo = db.getCollectionInfos({ name: "connect_community_post" })[0];
    const postValidator = postColInfo && postColInfo.options && postColInfo.options.validator;
    const postSchema = postValidator && postValidator.$jsonSchema ? postValidator.$jsonSchema : null;
    const postProps = postSchema && postSchema.properties ? postSchema.properties : null;

    const posts = [
        {
            post_id: NumberInt(9),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            author_user_id: ownerUserId,
            content: "Welcome to the Robotics & AI Innovation Club! Our laboratory has received new robotic chassis kits, LiDAR modules, and ESP32 microcontrollers. Orientation and tool safety briefing starts this Thursday at 3:30 PM in the Mechatronics Lab.",
            attachments: [
                {
                    attachment_id: "att_robo_001",
                    attachment_type: "image",
                    file_name: "robotics_lab_chassis_and_sensors.jpg",
                    file_size_label: "2.4 MB",
                    object_key: "communities/3/posts/robotics_lab_chassis_and_sensors.jpg"
                }
            ],
            like_count: NumberInt(27),
            is_active: true,
            created_at: ISODate("2026-09-24T09:30:00.000Z"),
            updated_at: null
        },
        {
            post_id: NumberInt(10),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            author_user_id: ownerUserId,
            content: "Milestone Achievement: Our autonomous obstacle-avoidance rover prototype successfully passed its navigational waypoint trials today with 98.4% accuracy! Download the complete wiring schematic and PID motor calibration log below.",
            attachments: [
                {
                    attachment_id: "att_robo_002",
                    attachment_type: "document",
                    file_name: "Autonomous_Rover_PID_Calibration_Report.pdf",
                    file_size_label: "3.1 MB",
                    object_key: "communities/3/posts/Autonomous_Rover_PID_Calibration_Report.pdf"
                }
            ],
            like_count: NumberInt(35),
            is_active: true,
            created_at: ISODate("2026-09-28T14:00:00.000Z"),
            updated_at: null
        }
    ];

    let postUpsertCount = 0;
    posts.forEach(function (p) {
        adaptToSchema(p, postSchema);

        if (p.attachments === null && postProps && postProps.attachments) {
            const attBson = postProps.attachments.bsonType;
            if (Array.isArray(attBson) && !attBson.includes("null")) {
                p.attachments = [];
            }
        }

        try {
            db.connect_community_post.updateOne(
                { post_id: p.post_id },
                { $set: p },
                { upsert: true }
            );
            postUpsertCount++;
        } catch (err) {
            print("❌ Validation failed on connect_community_post (post_id: " + p.post_id + "):");
            if (err.errInfo && err.errInfo.details) {
                print(JSON.stringify(err.errInfo.details, null, 2));
            } else {
                print(err.message);
            }
            throw err;
        }
    });
    print("✔ Seeded " + postUpsertCount + " posts into connect_community_post (community_id: 3, post_id: 9, 10).");

    // -------------------------------------------------------------------------
    // 5. Insert / Upsert 3 Discussions (discussion_id: 10, 11, 12)
    // -------------------------------------------------------------------------
    const discussions = [
        {
            discussion_id: NumberInt(10),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            title: "Microcontroller Selection for Autonomous Navigation: ESP32 vs. Raspberry Pi Pico",
            description: "When designing battery-powered autonomous rovers, which controller provides the best trade-off between dual-core processing, real-time PWM motor driving, and Wi-Fi telemetry latency?",
            author_user_id: ownerUserId,
            is_trending: true,
            is_active: true,
            created_at: ISODate("2026-09-25T11:00:00.000Z"),
            updated_at: null
        },
        {
            discussion_id: NumberInt(11),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            title: "Computer Vision at the Edge: Deploying TinyYOLO vs. MobileNet on Raspberry Pi 5",
            description: "Let's review frame rates, thermal throttling, and inference accuracy when running quantized neural network models for real-time object detection and lane following in the robotics arena.",
            author_user_id: ownerUserId,
            is_trending: true,
            is_active: true,
            created_at: ISODate("2026-09-29T15:30:00.000Z"),
            updated_at: null
        },
        {
            discussion_id: NumberInt(12),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            title: "RoboCup Junior & National Robotics Olympiad 2027: Strategy & Team Allocation",
            description: "Planning our school's competitive strategy for the upcoming National Robotics Olympiad. Share your interest in Rescue Rover, Maze Solver, or Soccer Bot divisions and preferred engineering roles.",
            author_user_id: ownerUserId,
            is_trending: false,
            is_active: true,
            created_at: ISODate("2026-10-02T13:45:00.000Z"),
            updated_at: null
        }
    ];

    const discColInfo = db.getCollectionInfos({ name: "connect_community_discussion" })[0];
    const discValidator = discColInfo && discColInfo.options && discColInfo.options.validator;
    const discSchema = discValidator && discValidator.$jsonSchema ? discValidator.$jsonSchema : null;

    let discUpsertCount = 0;
    discussions.forEach(function (d) {
        adaptToSchema(d, discSchema);
        try {
            db.connect_community_discussion.updateOne(
                { discussion_id: d.discussion_id },
                { $set: d },
                { upsert: true }
            );
            discUpsertCount++;
        } catch (err) {
            print("❌ Validation failed on connect_community_discussion (discussion_id: " + d.discussion_id + "):");
            if (err.errInfo && err.errInfo.details) {
                print(JSON.stringify(err.errInfo.details, null, 2));
            } else {
                print(err.message);
            }
            throw err;
        }
    });
    print("✔ Seeded " + discUpsertCount + " discussions into connect_community_discussion (community_id: 3, discussion_id: 10..12).");

    // -------------------------------------------------------------------------
    // 6. Insert / Upsert 3 Polls (poll_id: 10, 11, 12)
    // -------------------------------------------------------------------------
    const polls = [
        {
            poll_id: NumberInt(10),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            question: "Which competitive division should our robotics team prioritize this academic year?",
            options: [
                { option_id: NumberInt(1), label: "Autonomous Line Follower & Maze Solver", vote_count: NumberInt(19) },
                { option_id: NumberInt(2), label: "RoboCup Junior Search & Rescue Rover", vote_count: NumberInt(23) },
                { option_id: NumberInt(3), label: "AI Computer Vision Drone Obstacle Course", vote_count: NumberInt(15) },
                { option_id: NumberInt(4), label: "Combat Robot Engineering (1.5 kg Beetleweight)", vote_count: NumberInt(11) }
            ],
            total_votes: NumberInt(68),
            expires_at: ISODate("2026-10-29T23:59:59.000Z"),
            is_active: true,
            created_at: ISODate("2026-09-26T10:00:00.000Z"),
            updated_at: null,
            created_by: ownerUserId
        },
        {
            poll_id: NumberInt(11),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            question: "Which primary CAD & 3D prototyping software would you like training on?",
            options: [
                { option_id: NumberInt(1), label: "Autodesk Fusion 360", vote_count: NumberInt(25) },
                { option_id: NumberInt(2), label: "SolidWorks", vote_count: NumberInt(18) },
                { option_id: NumberInt(3), label: "Onshape (Cloud CAD)", vote_count: NumberInt(12) },
                { option_id: NumberInt(4), label: "Blender (for 3D mesh rendering)", vote_count: NumberInt(7) }
            ],
            total_votes: NumberInt(62),
            expires_at: ISODate("2026-10-31T23:59:59.000Z"),
            is_active: true,
            created_at: ISODate("2026-09-30T12:30:00.000Z"),
            updated_at: null,
            created_by: ownerUserId
        },
        {
            poll_id: NumberInt(12),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            question: "What is your preferred weekly day for 3D printer calibration and CNC milling sessions?",
            options: [
                { option_id: NumberInt(1), label: "Tuesday Afternoons (3:30 PM - 5:00 PM)", vote_count: NumberInt(17) },
                { option_id: NumberInt(2), label: "Thursday Afternoons (3:30 PM - 5:00 PM)", vote_count: NumberInt(26) },
                { option_id: NumberInt(3), label: "Saturday Mornings (9:00 AM - 11:30 AM)", vote_count: NumberInt(14) }
            ],
            total_votes: NumberInt(57),
            expires_at: ISODate("2026-11-05T23:59:59.000Z"),
            is_active: true,
            created_at: ISODate("2026-10-03T09:15:00.000Z"),
            updated_at: null,
            created_by: ownerUserId
        }
    ];

    const pollColInfo = db.getCollectionInfos({ name: "connect_community_poll" })[0];
    const pollValidator = pollColInfo && pollColInfo.options && pollColInfo.options.validator;
    const pollSchema = pollValidator && pollValidator.$jsonSchema ? pollValidator.$jsonSchema : null;

    let pollUpsertCount = 0;
    polls.forEach(function (pl) {
        adaptToSchema(pl, pollSchema);
        try {
            db.connect_community_poll.updateOne(
                { poll_id: pl.poll_id },
                { $set: pl },
                { upsert: true }
            );
            pollUpsertCount++;
        } catch (err) {
            print("❌ Validation failed on connect_community_poll (poll_id: " + pl.poll_id + "):");
            if (err.errInfo && err.errInfo.details) {
                print(JSON.stringify(err.errInfo.details, null, 2));
            } else {
                print(err.message);
            }
            throw err;
        }
    });
    print("✔ Seeded " + pollUpsertCount + " polls into connect_community_poll (community_id: 3, poll_id: 10..12).");

    print("=================================================================");
    print("Community 3 (Robotics & AI Innovation Club) initialized!");
    print("✔ 6 Members (1 Owner + 5 Students) seeded into connect_community_member.");
    print("✔ 2 Posts (post_id: 9, 10) seeded into connect_community_post.");
    print("✔ 3 Discussions (discussion_id: 10, 11, 12) seeded into connect_community_discussion.");
    print("✔ 3 Polls (poll_id: 10, 11, 12) seeded into connect_community_poll.");
    print("All community activity authored/created by owner user_id: 103 (Mayank Mukherjee).");
    print("=================================================================");
})();
