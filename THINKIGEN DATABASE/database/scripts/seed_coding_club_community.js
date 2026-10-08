/* ============================================================================
   THINKIGEN Connect — Community Activity Seeder
   Script:      seed_coding_club_community.js
   Database:    MongoDB (thinkigen)
   Target:      Coding & Cyber Innovation Club (community_id: 2)
   Owner:       Teacher / Community Owner (user_id: 102)
   Description: Creates community_id: 2 with owner user_id: 102 and seeds:
                - 7 Members (1 Teacher Owner + 6 Students) in connect_community_member,
                - 5 Posts (post_id: 4..8) in connect_community_post,
                - 5 Discussions (discussion_id: 5..9) in connect_community_discussion,
                - 5 Polls (poll_id: 5..9) in connect_community_poll,
                all activity authored/created by user_id: 102.
                Conforms strictly to MongoDB Atlas schema rules, tenant
                boundaries (school_id: 1, branch_id: 1), and BSON NumberInt.
   ============================================================================ */

(function () {
    const communityId = NumberInt(2);
    const schoolId = NumberInt(1);
    const branchId = NumberInt(1);
    const ownerUserId = NumberInt(102); // Teacher Radhika Pillai (owner)

    print("=================================================================");
    print("THINKIGEN CONNECT — SEEDING CODING & CYBER INNOVATION CLUB");
    print("Community ID: " + communityId + " | School ID: " + schoolId + " | Branch ID: " + branchId);
    print("Owner / Creator: user_id " + ownerUserId);
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
    // 1. Define Members for Community 2 (1 Teacher Owner + 5 Student Members = 6 total)
    // -------------------------------------------------------------------------
    const members = [
        {
            community_id: communityId,
            user_id: ownerUserId, // 102
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Radhika Pillai",
            user_role: "teacher",
            member_role: "owner",
            membership_status: "joined",
            joined_at: ISODate("2026-09-22T14:00:00.000Z"),
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(201),
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Karishma Shaik",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: ISODate("2026-09-22T14:02:00.000Z"),
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(206),
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Sravan Kumar",
            user_role: "student",
            member_role: "moderator",
            membership_status: "joined",
            joined_at: ISODate("2026-09-22T14:05:00.000Z"),
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(207),
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Gaurav Joshi",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: ISODate("2026-09-22T14:10:00.000Z"),
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(208),
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Manish Talwar",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: ISODate("2026-09-22T14:15:00.000Z"),
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(209),
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Zara Tiwari",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: ISODate("2026-09-22T14:20:00.000Z"),
            left_at: null
        },
        {
            community_id: communityId,
            user_id: NumberInt(210),
            school_id: schoolId,
            branch_id: branchId,
            display_name: "Sarita Sengupta",
            user_role: "student",
            member_role: "member",
            membership_status: "joined",
            joined_at: ISODate("2026-09-22T14:25:00.000Z"),
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
        name: "Coding & Cyber Innovation Club",
        description: "Campus community for algorithmic programming, web and mobile app prototyping, open-source projects, and cybersecurity awareness under faculty mentorship.",
        owner_user_id: ownerUserId,
        member_count: NumberInt(members.length), // Exactly 6 members
        is_trending: true,
        is_active: true,
        created_at: ISODate("2026-09-22T14:00:00.000Z"),
        updated_at: ISODate("2026-09-22T14:00:00.000Z"),
        created_by: ownerUserId,
        updated_by: ownerUserId
    };

    const commRes = db.connect_community.updateOne(
        { community_id: communityId },
        { $set: communityDoc },
        { upsert: true }
    );
    print("✔ Upserted connect_community (community_id: 2): " + JSON.stringify(commRes));

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
    // 3. Insert / Upsert 5 Posts (post_id: 4..8) into connect_community_post
    // -------------------------------------------------------------------------
    const postColInfo = db.getCollectionInfos({ name: "connect_community_post" })[0];
    const postValidator = postColInfo && postColInfo.options && postColInfo.options.validator;
    const postSchema = postValidator && postValidator.$jsonSchema ? postValidator.$jsonSchema : null;
    const postProps = postSchema && postSchema.properties ? postSchema.properties : null;

    const posts = [
        {
            post_id: NumberInt(4),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            author_user_id: ownerUserId,
            content: "Welcome to the Coding & Cyber Innovation Club! Our computer lab sessions commence this Friday afternoon. We will focus on Python programming, clean coding standards, algorithm problem solving, and modern web application development.",
            attachments: [
                {
                    attachment_id: "att_code_001",
                    attachment_type: "image",
                    file_name: "coding_club_orientation_roadmap.jpg",
                    file_size_label: "2.1 MB",
                    object_key: "communities/2/posts/coding_club_orientation_roadmap.jpg"
                }
            ],
            like_count: NumberInt(18),
            is_active: true,
            created_at: ISODate("2026-09-23T09:00:00.000Z"),
            updated_at: null
        },
        {
            post_id: NumberInt(5),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            author_user_id: ownerUserId,
            content: "All registered members can now activate their GitHub Student Developer Pack. This includes free cloud credits, domain registration, and professional IDE tools. Review the setup guide attached below to get your student developer environment ready.",
            attachments: [
                {
                    attachment_id: "att_code_002",
                    attachment_type: "document",
                    file_name: "GitHub_Student_Developer_Pack_Guide.pdf",
                    file_size_label: "1.4 MB",
                    object_key: "communities/2/posts/GitHub_Student_Developer_Pack_Guide.pdf"
                }
            ],
            like_count: NumberInt(24),
            is_active: true,
            created_at: ISODate("2026-09-26T11:30:00.000Z"),
            updated_at: null
        },
        {
            post_id: NumberInt(6),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            author_user_id: ownerUserId,
            content: "October is Cybersecurity Awareness Month! As part of our campus cyber defense initiative, remember to enable Multi-Factor Authentication (MFA) on student portals and never share credentials over unsecured networks.",
            attachments: [
                {
                    attachment_id: "att_code_003",
                    attachment_type: "image",
                    file_name: "cyber_safety_and_hygiene_checklist.jpg",
                    file_size_label: "2.8 MB",
                    object_key: "communities/2/posts/cyber_safety_and_hygiene_checklist.jpg"
                }
            ],
            like_count: NumberInt(21),
            is_active: true,
            created_at: ISODate("2026-09-29T14:15:00.000Z"),
            updated_at: null
        },
        {
            post_id: NumberInt(7),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            author_user_id: ownerUserId,
            content: "Registration is now open for our Inter-School 24-Hour Civic Tech Hackathon! Student teams of 3 to 4 will build web applications addressing campus energy conservation and student learning tools. Faculty mentorship provided throughout the event.",
            attachments: [
                {
                    attachment_id: "att_code_004",
                    attachment_type: "document",
                    file_name: "InterSchool_CivicTech_Hackathon_2026.pdf",
                    file_size_label: "3.2 MB",
                    object_key: "communities/2/posts/InterSchool_CivicTech_Hackathon_2026.pdf"
                }
            ],
            like_count: NumberInt(32),
            is_active: true,
            created_at: ISODate("2026-10-02T10:00:00.000Z"),
            updated_at: null
        },
        {
            post_id: NumberInt(8),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            author_user_id: ownerUserId,
            content: "Project Spotlight: Congratulations to our student team for successfully prototyping the campus library book catalog search tool using Node.js and React. The test build demonstrates great component hierarchy and clean API calls!",
            attachments: [
                {
                    attachment_id: "att_code_005",
                    attachment_type: "image",
                    file_name: "library_search_prototype_preview.jpg",
                    file_size_label: "1.7 MB",
                    object_key: "communities/2/posts/library_search_prototype_preview.jpg"
                }
            ],
            like_count: NumberInt(29),
            is_active: true,
            created_at: ISODate("2026-10-04T15:30:00.000Z"),
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
    print("✔ Seeded " + postUpsertCount + " posts into connect_community_post (community_id: 2, post_id: 4..8).");

    // -------------------------------------------------------------------------
    // 4. Insert / Upsert 5 Discussions (discussion_id: 5..9)
    // -------------------------------------------------------------------------
    const discussions = [
        {
            discussion_id: NumberInt(5),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            title: "Best Starter Language for High Schoolers: Python vs. JavaScript vs. C++",
            description: "Which programming language gives beginners the clearest conceptual grasp of control flow, data structures, and computational thinking without cognitive overload from boilerplate syntax?",
            author_user_id: ownerUserId,
            is_trending: true,
            is_active: true,
            created_at: ISODate("2026-09-24T10:00:00.000Z"),
            updated_at: null
        },
        {
            discussion_id: NumberInt(6),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            title: "Brainstorming Civic Tech Themes for the Annual Campus Hackathon",
            description: "Let's gather student proposals for this year's hackathon tracks. Suggested areas include smart campus navigation, student peer well-being trackers, and automated recycling monitors. Share your ideas and technical feasibility thoughts.",
            author_user_id: ownerUserId,
            is_trending: true,
            is_active: true,
            created_at: ISODate("2026-09-27T12:00:00.000Z"),
            updated_at: null
        },
        {
            discussion_id: NumberInt(7),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            title: "Defending School IoT & Lab Wi-Fi: Practical Cybersecurity Measures",
            description: "With the rise of connected microcontrollers and sensors across school laboratories, what lightweight encryption and network isolation protocols should students implement to secure local sensor telemetry?",
            author_user_id: ownerUserId,
            is_trending: false,
            is_active: true,
            created_at: ISODate("2026-09-30T14:30:00.000Z"),
            updated_at: null
        },
        {
            discussion_id: NumberInt(8),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            title: "Cross-Platform Mobile Apps (Flutter/React Native) vs. Progressive Web Apps (PWAs)",
            description: "Comparing modern frontend distribution strategies for student projects: When does a school project justify native mobile compilation versus a lightweight, responsive Progressive Web App with offline service workers?",
            author_user_id: ownerUserId,
            is_trending: false,
            is_active: true,
            created_at: ISODate("2026-10-02T16:00:00.000Z"),
            updated_at: null
        },
        {
            discussion_id: NumberInt(9),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            title: "Open Source Contribution Guide: Finding Beginner-Friendly GitHub Issues",
            description: "Contributing to open source software accelerates engineering maturity. Let's curate beginner-friendly public repositories with labeled 'good first issues' in documentation, unit testing, and bug triage.",
            author_user_id: ownerUserId,
            is_trending: true,
            is_active: true,
            created_at: ISODate("2026-10-04T11:45:00.000Z"),
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
    print("✔ Seeded " + discUpsertCount + " discussions into connect_community_discussion (community_id: 2, discussion_id: 5..9).");

    // -------------------------------------------------------------------------
    // 5. Insert / Upsert 5 Polls (poll_id: 5..9)
    // -------------------------------------------------------------------------
    const polls = [
        {
            poll_id: NumberInt(5),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            question: "Which core tech stack should we use for our collaborative club web portal?",
            options: [
                {
                    option_id: NumberInt(1),
                    label: "Next.js (React) + Node.js Backend",
                    vote_count: NumberInt(18)
                },
                {
                    option_id: NumberInt(2),
                    label: "Python FastAPI + Tailwind CSS",
                    vote_count: NumberInt(14)
                },
                {
                    option_id: NumberInt(3),
                    label: "MERN Stack (MongoDB, Express, React, Node)",
                    vote_count: NumberInt(12)
                },
                {
                    option_id: NumberInt(4),
                    label: "Django Full-Stack with Python",
                    vote_count: NumberInt(8)
                }
            ],
            total_votes: NumberInt(52),
            expires_at: ISODate("2026-10-25T23:59:59.000Z"),
            is_active: true,
            created_at: ISODate("2026-09-25T12:00:00.000Z"),
            updated_at: null,
            created_by: ownerUserId
        },
        {
            poll_id: NumberInt(6),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            question: "What is your primary personal focus area in the Coding Club?",
            options: [
                {
                    option_id: NumberInt(1),
                    label: "Competitive Programming & Algorithmic Problem Solving",
                    vote_count: NumberInt(16)
                },
                {
                    option_id: NumberInt(2),
                    label: "Full-Stack Web & Mobile App Development",
                    vote_count: NumberInt(22)
                },
                {
                    option_id: NumberInt(3),
                    label: "Cybersecurity, Network Defense & Cryptography",
                    vote_count: NumberInt(15)
                },
                {
                    option_id: NumberInt(4),
                    label: "Artificial Intelligence & Data Analytics",
                    vote_count: NumberInt(11)
                }
            ],
            total_votes: NumberInt(64),
            expires_at: ISODate("2026-10-28T23:59:59.000Z"),
            is_active: true,
            created_at: ISODate("2026-09-27T09:30:00.000Z"),
            updated_at: null,
            created_by: ownerUserId
        },
        {
            poll_id: NumberInt(7),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            question: "Which weekly time slot works best for our collaborative coding sprint labs?",
            options: [
                {
                    option_id: NumberInt(1),
                    label: "Wednesday afternoons (3:30 PM - 5:00 PM)",
                    vote_count: NumberInt(19)
                },
                {
                    option_id: NumberInt(2),
                    label: "Friday afternoons (3:30 PM - 5:00 PM)",
                    vote_count: NumberInt(24)
                },
                {
                    option_id: NumberInt(3),
                    label: "Saturday mornings (10:00 AM - 12:00 PM)",
                    vote_count: NumberInt(13)
                }
            ],
            total_votes: NumberInt(56),
            expires_at: ISODate("2026-10-15T23:59:59.000Z"),
            is_active: true,
            created_at: ISODate("2026-09-29T10:00:00.000Z"),
            updated_at: null,
            created_by: ownerUserId
        },
        {
            poll_id: NumberInt(8),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            question: "Which database engine would you like to master in our backend development track?",
            options: [
                {
                    option_id: NumberInt(1),
                    label: "PostgreSQL (Relational SQL)",
                    vote_count: NumberInt(21)
                },
                {
                    option_id: NumberInt(2),
                    label: "MongoDB (Document NoSQL)",
                    vote_count: NumberInt(19)
                },
                {
                    option_id: NumberInt(3),
                    label: "Redis (In-Memory Key-Value Caching)",
                    vote_count: NumberInt(9)
                }
            ],
            total_votes: NumberInt(49),
            expires_at: ISODate("2026-10-31T23:59:59.000Z"),
            is_active: true,
            created_at: ISODate("2026-10-01T14:15:00.000Z"),
            updated_at: null,
            created_by: ownerUserId
        },
        {
            poll_id: NumberInt(9),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            question: "Select your preferred primary track for the upcoming Inter-School Hackathon:",
            options: [
                {
                    option_id: NumberInt(1),
                    label: "Campus Sustainability & Carbon Footprint Tracking",
                    vote_count: NumberInt(17)
                },
                {
                    option_id: NumberInt(2),
                    label: "Student Well-Being & Collaborative Study Tools",
                    vote_count: NumberInt(14)
                },
                {
                    option_id: NumberInt(3),
                    label: "Interactive STEM Learning & Quiz Gamification",
                    vote_count: NumberInt(18)
                },
                {
                    option_id: NumberInt(4),
                    label: "Smart Bus Routing & Fleet Management",
                    vote_count: NumberInt(9)
                }
            ],
            total_votes: NumberInt(58),
            expires_at: ISODate("2026-11-05T23:59:59.000Z"),
            is_active: true,
            created_at: ISODate("2026-10-03T11:00:00.000Z"),
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
    print("✔ Seeded " + pollUpsertCount + " polls into connect_community_poll (community_id: 2, poll_id: 5..9).");

    print("=================================================================");
    print("Community 2 (Coding & Cyber Innovation Club) initialized!");
    print("✔ 7 Members (1 Owner + 6 Students) seeded into connect_community_member.");
    print("✔ 5 Posts (post_id: 4..8) seeded into connect_community_post.");
    print("✔ 5 Discussions (discussion_id: 5..9) seeded into connect_community_discussion.");
    print("✔ 5 Polls (poll_id: 5..9) seeded into connect_community_poll.");
    print("All community activity authored/created by owner user_id: 102.");
    print("=================================================================");
})();
