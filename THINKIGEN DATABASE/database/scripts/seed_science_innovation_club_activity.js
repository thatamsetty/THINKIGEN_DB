/* ============================================================================
   THINKIGEN Connect — Community Activity Seeder
   Script:      seed_science_innovation_club_activity.js
   Database:    MongoDB (thinkigen)
   Target:      Science & Innovation Club (community_id: 1)
   Author:      Teacher / Community Owner (user_id: 101)
   Description: Seeds / updates 4 Posts, 4 Discussions, and 4 Polls for
                community_id: 1 where ALL items are created by user_id: 101.
                Strictly complies with BSON NumberInt, multi-tenant boundaries
                (school_id, branch_id), and dynamic schema rules.
   ============================================================================ */

(function () {
    const communityId = NumberInt(1);
    const schoolId = NumberInt(1);
    const branchId = NumberInt(1);
    const ownerUserId = NumberInt(101); // Teacher / Community Owner (faculty mentor)

    print("=================================================================");
    print("THINKIGEN CONNECT — SEEDING SCIENCE & INNOVATION CLUB ACTIVITY");
    print("Community ID: " + communityId + " | School ID: " + schoolId + " | Branch ID: " + branchId);
    print("Owner / Creator: user_id " + ownerUserId);
    print("=================================================================");

    // -------------------------------------------------------------------------
    // 0. Ensure target collections exist
    // -------------------------------------------------------------------------
    const requiredCollections = [
        "connect_community",
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
    // 1. Ensure Community Document exists in connect_community
    // -------------------------------------------------------------------------
    const communityDoc = {
        community_id: communityId,
        branch_id: branchId,
        community_type: "club",
        created_at: ISODate("2026-09-22T13:21:07.022Z"),
        created_by: ownerUserId,
        description: "Campus club dedicated to hands-on science experiments, STEM projects, and scientific discovery under faculty mentorship.",
        is_active: true,
        is_trending: true,
        member_count: NumberInt(6),
        name: "Science & Innovation Club",
        owner_user_id: ownerUserId,
        school_id: schoolId,
        updated_at: ISODate("2026-09-22T13:21:07.022Z"),
        updated_by: ownerUserId
    };

    const commRes = db.connect_community.updateOne(
        { community_id: communityId },
        { $set: communityDoc },
        { upsert: true }
    );
    print("✔ Upserted connect_community (community_id: 1): " + JSON.stringify(commRes));

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
    // 2. Insert / Upsert 4 Posts into connect_community_post (All author: 101)
    // -------------------------------------------------------------------------
    const postColInfo = db.getCollectionInfos({ name: "connect_community_post" })[0];
    const postValidator = postColInfo && postColInfo.options && postColInfo.options.validator;
    const postSchema = postValidator && postValidator.$jsonSchema ? postValidator.$jsonSchema : null;
    const postProps = postSchema && postSchema.properties ? postSchema.properties : null;

    const posts = [
        {
            post_id: NumberInt(1),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            author_user_id: ownerUserId,
            content: "Welcome to the Science & Innovation Club! Our laboratory stations have been upgraded with digital spectrometers, breadboards, and multi-sensor telemetry kits. Weekly hands-on lab sessions will be held every Wednesday afternoon. Let's explore, experiment, and innovate together!",
            attachments: [
                {
                    attachment_id: "att_sci_001",
                    attachment_type: "image",
                    file_name: "science_lab_orientation.jpg",
                    file_size_label: "2.4 MB",
                    object_key: "communities/1/posts/science_lab_orientation.jpg"
                }
            ],
            like_count: NumberInt(18),
            is_active: true,
            created_at: ISODate("2026-09-23T08:30:00.000Z"),
            updated_at: null
        },
        {
            post_id: NumberInt(2),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            author_user_id: ownerUserId,
            content: "Commendable progress in today's lab! Team Eco-Tech successfully calibrated their solar-powered automated soil moisture and irrigation monitor using Arduino and capacitive sensors. Sensor logs are now syncing seamlessly via telemetry. We will review the live demo during Wednesday's session!",
            attachments: [
                {
                    attachment_id: "att_sci_002",
                    attachment_type: "image",
                    file_name: "automated_irrigation_prototype.jpg",
                    file_size_label: "3.1 MB",
                    object_key: "communities/1/posts/automated_irrigation_prototype.jpg"
                }
            ],
            like_count: NumberInt(27),
            is_active: true,
            created_at: ISODate("2026-09-26T11:15:00.000Z"),
            updated_at: null
        },
        {
            post_id: NumberInt(3),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            author_user_id: ownerUserId,
            content: "Mandatory safety refresher: Please review the updated Lab Safety & Reagent Handling Protocol before Friday's exothermic reactions session. Lab coats, nitrile gloves, and splash goggles are required at all times across all benches.",
            attachments: [
                {
                    attachment_id: "att_sci_003",
                    attachment_type: "document",
                    file_name: "Lab_Safety_Protocol_2026.pdf",
                    file_size_label: "1.2 MB",
                    object_key: "communities/1/posts/Lab_Safety_Protocol_2026.pdf"
                }
            ],
            like_count: NumberInt(14),
            is_active: true,
            created_at: ISODate("2026-09-29T09:00:00.000Z"),
            updated_at: null
        },
        {
            post_id: NumberInt(4),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            author_user_id: ownerUserId,
            content: "Stargazing night confirmed! The weather forecast for Tuesday evening shows completely clear skies. We will set up the club's 8-inch Dobsonian reflector telescope on the north observatory deck to track Jupiter's Galilean moons and the Orion Nebula. All registered members are welcome to attend!",
            attachments: null,
            like_count: NumberInt(35),
            is_active: true,
            created_at: ISODate("2026-10-02T15:45:00.000Z"),
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
    print("✔ Seeded / Updated " + postUpsertCount + " posts into connect_community_post (author: 101).");

    // -------------------------------------------------------------------------
    // 3. Insert / Upsert 4 Discussions into connect_community_discussion (All author: 101)
    // -------------------------------------------------------------------------
    const discussions = [
        {
            discussion_id: NumberInt(1),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            title: "Flagship Project for Regional Science Congress: Clean Energy vs. Bio-Plastics",
            description: "Let's brainstorm our community's primary entry for the upcoming Inter-School Regional Science Congress. Should we build a dual-axis solar parabolic concentrator or formulate biodegradable food packaging from chitin/starch? Share your project feasibility ideas, material costs, and mentorship requirements.",
            author_user_id: ownerUserId,
            is_trending: true,
            is_active: true,
            created_at: ISODate("2026-09-24T10:00:00.000Z"),
            updated_at: null
        },
        {
            discussion_id: NumberInt(2),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            title: "Deploying Edge AI on Raspberry Pi for Campus Biodiversity Tracking",
            description: "We are exploring the deployment of an ultra-lightweight YOLO vision model on a Raspberry Pi 5 with a solar battery shield. The goal is to detect and catalog bird and pollinator species visiting the campus botanical garden without disturbing wildlife. Looking for member input on camera optics, frame rates, and dataset annotation.",
            author_user_id: ownerUserId,
            is_trending: true,
            is_active: true,
            created_at: ISODate("2026-09-27T14:20:00.000Z"),
            updated_at: null
        },
        {
            discussion_id: NumberInt(3),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            title: "Junior STEM Fair: Mentorship Program & Experiment Ideas",
            description: "High school club members have been invited to mentor Grade 6-8 students for their introductory STEM exhibition. Which experiment concepts offer the best visual engagement and scientific rigor while remaining completely non-hazardous for beginners? Post your demonstration proposals here.",
            author_user_id: ownerUserId,
            is_trending: false,
            is_active: true,
            created_at: ISODate("2026-09-30T16:00:00.000Z"),
            updated_at: null
        },
        {
            discussion_id: NumberInt(4),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            title: "DIY Optical Spectroscopy: Calibrating Low-Cost Diffraction Gratings",
            description: "Can we build laboratory-grade spectrometers using 3D-printed slits and optical CD/DVD diffraction gratings? We are testing whether smartphone camera sensors can resolve spectral emission lines of alkali metals (sodium, potassium, calcium) during flame ionization tests. Share your calibration readings.",
            author_user_id: ownerUserId,
            is_trending: false,
            is_active: true,
            created_at: ISODate("2026-10-03T11:30:00.000Z"),
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
    print("✔ Seeded / Updated " + discUpsertCount + " discussions into connect_community_discussion (author: 101).");

    // -------------------------------------------------------------------------
    // 4. Insert / Upsert 4 Polls into connect_community_poll (All created_by: 101)
    // -------------------------------------------------------------------------
    const polls = [
        {
            poll_id: NumberInt(1),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            question: "Which technical workshop track should the club host next month?",
            options: [
                {
                    option_id: NumberInt(1),
                    label: "Microcontroller Prototyping & Sensor Interfacing (ESP32 / Arduino)",
                    vote_count: NumberInt(16)
                },
                {
                    option_id: NumberInt(2),
                    label: "Bioinformatics & DNA Extraction from Plant Tissue",
                    vote_count: NumberInt(10)
                },
                {
                    option_id: NumberInt(3),
                    label: "Aerodynamics & Water Rocket Flight Stabilization",
                    vote_count: NumberInt(14)
                },
                {
                    option_id: NumberInt(4),
                    label: "Renewable Energy & Dye-Sensitized Solar Cells (DSSC)",
                    vote_count: NumberInt(8)
                }
            ],
            total_votes: NumberInt(48),
            expires_at: ISODate("2026-10-25T23:59:59.000Z"),
            is_active: true,
            created_at: ISODate("2026-09-25T12:00:00.000Z"),
            updated_at: null,
            created_by: ownerUserId
        },
        {
            poll_id: NumberInt(2),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            question: "What is your preferred weekly time slot for hands-on laboratory sessions?",
            options: [
                {
                    option_id: NumberInt(1),
                    label: "Wednesday afternoons (3:30 PM - 5:00 PM)",
                    vote_count: NumberInt(19)
                },
                {
                    option_id: NumberInt(2),
                    label: "Friday afternoons (3:30 PM - 5:00 PM)",
                    vote_count: NumberInt(12)
                },
                {
                    option_id: NumberInt(3),
                    label: "Saturday mornings (9:30 AM - 11:30 AM)",
                    vote_count: NumberInt(15)
                }
            ],
            total_votes: NumberInt(46),
            expires_at: ISODate("2026-10-15T23:59:59.000Z"),
            is_active: true,
            created_at: ISODate("2026-09-28T09:30:00.000Z"),
            updated_at: null,
            created_by: ownerUserId
        },
        {
            poll_id: NumberInt(3),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            question: "Vote for your primary domain of interest for the Annual Science Fair:",
            options: [
                {
                    option_id: NumberInt(1),
                    label: "Applied Robotics, Automation & IoT",
                    vote_count: NumberInt(18)
                },
                {
                    option_id: NumberInt(2),
                    label: "Clean Energy, Water Purification & Climate Tech",
                    vote_count: NumberInt(15)
                },
                {
                    option_id: NumberInt(3),
                    label: "Biotechnology & Computational Health",
                    vote_count: NumberInt(9)
                },
                {
                    option_id: NumberInt(4),
                    label: "Astrophysics, Optics & Space Exploration",
                    vote_count: NumberInt(12)
                }
            ],
            total_votes: NumberInt(54),
            expires_at: ISODate("2026-10-31T23:59:59.000Z"),
            is_active: true,
            created_at: ISODate("2026-10-01T10:15:00.000Z"),
            updated_at: null,
            created_by: ownerUserId
        },
        {
            poll_id: NumberInt(4),
            community_id: communityId,
            school_id: schoolId,
            branch_id: branchId,
            question: "Which guest researcher domain would you like for our next university webinar?",
            options: [
                {
                    option_id: NumberInt(1),
                    label: "Astrophysics & Deep Space Observation (JWST & Radio Astronomy)",
                    vote_count: NumberInt(22)
                },
                {
                    option_id: NumberInt(2),
                    label: "Quantum Computing Principles & Quantum Sensors",
                    vote_count: NumberInt(14)
                },
                {
                    option_id: NumberInt(3),
                    label: "Synthetic Biology & CRISPR Gene Editing Applications",
                    vote_count: NumberInt(10)
                },
                {
                    option_id: NumberInt(4),
                    label: "Advanced Nanomaterials & Graphene Applications",
                    vote_count: NumberInt(11)
                }
            ],
            total_votes: NumberInt(57),
            expires_at: ISODate("2026-11-10T23:59:59.000Z"),
            is_active: true,
            created_at: ISODate("2026-10-04T14:00:00.000Z"),
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
    print("✔ Seeded / Updated " + pollUpsertCount + " polls into connect_community_poll (created_by: 101).");

    print("=================================================================");
    print("All 4 Posts, 4 Discussions, and 4 Polls successfully seeded/updated!");
    print("All items authored/created by user_id: 101 (Faculty Owner / Mentor).");
    print("=================================================================");
})();
