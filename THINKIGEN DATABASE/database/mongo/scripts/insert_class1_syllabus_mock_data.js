/**
 * ==============================================================================
 * MongoDB Seed Script: Class Subject Syllabus Mock Data
 * Target Collection : class_subject_syllabus
 * Target Scope      :
 *   - school_id        = 1
 *   - branch_id        = 1
 *   - academic_year_id = 1
 *   - class_id         = 1
 *   - syllabus_version = 1
 *   - subject_ids      = [1, 2, 4, 5, 6] (English, Mathematics, Social Science,
 *                                        Computer Science, Physical Education)
 * Note: Subject 3 (Science) already exists and is preserved untouched.
 *
 * Curriculum Matrix:
 *   - 5 Subjects
 *   - 3 Chapters per Subject (15 Chapters total)
 *   - 3 Topics per Chapter (45 Topics total)
 *
 * Strict Validation : 100% compliant with 004_class_subject_syllabus.js
 *                      $jsonSchema validator and unique indexes.
 *
 * Usage:
 *   mongosh "mongodb://<connection_string>/<db_name>" insert_class1_syllabus_mock_data.js
 * ==============================================================================
 */

(function () {
    "use strict";

    const col = db.class_subject_syllabus;
    print(`\n==============================================================================`);
    print(`Target Collection: class_subject_syllabus`);
    print(`Target Scope     : School 1, Branch 1, Class 1, Academic Year 1, Version 1`);
    print(`Subjects to Seed : 1 (English), 2 (Mathematics), 4 (Social Science), 5 (Computer Science), 6 (Physical Education)`);
    print(`==============================================================================\n`);

    const now = new Date("2026-04-01T08:00:00.000Z");

    // 1. Inspect existing Science subject document (subject_id = 3) to match its exact type convention
    const existingScienceDoc = col.findOne({
        $or: [
            { subject_id: "3" },
            { subject_id: 3 },
            { subject_id: NumberInt(3) }
        ]
    });

    // Check if science doc uses numeric or string type for scope IDs.
    // Default to string as defined in 004_class_subject_syllabus.js validator.
    const useNumericScope = (existingScienceDoc && typeof existingScienceDoc.school_id !== "string");

    print(`Existing Science Subject (3) found: ${existingScienceDoc ? "YES" : "NO"}`);
    print(`Scope ID Representation: ${useNumericScope ? "NumberInt" : "String"}\n`);

    function toScopeId(val) {
        return useNumericScope ? NumberInt(val) : String(val);
    }

    const adminUserId = useNumericScope ? "1" : "1";

    // 2. Syllabus data definition for the 5 requested subjects
    const syllabi = [
        // =========================================================================
        // Subject 1: English
        // =========================================================================
        {
            subject_id: toScopeId(1),
            subject_name: "English",
            chapters: [
                {
                    chapter_id: "eng_ch_001",
                    title: "English Literature & Comprehension",
                    display_order: NumberInt(1),
                    is_locked: false,
                    topics: [
                        {
                            topic_id: "eng_topic_001",
                            number: "1.1",
                            title: "Poetry and Prose",
                            description: "Comprehensive analysis of classical and contemporary poetry and prose forms, stylistic structures, and expressive devices.",
                            learning_objective: "Understand poetic meters, verse forms, and differentiate prose narratives from structured poetry.",
                            display_order: NumberInt(1)
                        },
                        {
                            topic_id: "eng_topic_002",
                            number: "1.2",
                            title: "Literary Devices",
                            description: "Identification and interpretation of figurative language including metaphors, similes, personification, and alliteration.",
                            learning_objective: "Identify and analyze key literary devices in unseen texts to interpret underlying authorial meaning.",
                            display_order: NumberInt(2)
                        },
                        {
                            topic_id: "eng_topic_003",
                            number: "1.3",
                            title: "Character Analysis",
                            description: "Frameworks for examining character motivations, internal conflicts, dialogue cues, and character progression arcs.",
                            learning_objective: "Evaluate complex literary characters using textual citations, dialogue analysis, and psychological context.",
                            display_order: NumberInt(3)
                        }
                    ]
                },
                {
                    chapter_id: "eng_ch_002",
                    title: "Essay Writing & Creative Composition",
                    display_order: NumberInt(2),
                    is_locked: false,
                    topics: [
                        {
                            topic_id: "eng_topic_004",
                            number: "2.1",
                            title: "Essay Structure",
                            description: "Architecting structured essays featuring introduction hooks, thesis statements, body development, and syntheses.",
                            learning_objective: "Construct five-paragraph expository and persuasive essays with coherent thematic progression.",
                            display_order: NumberInt(1)
                        },
                        {
                            topic_id: "eng_topic_005",
                            number: "2.2",
                            title: "Creative Writing",
                            description: "Techniques for sensory descriptions, dynamic world-building, dialogue pacing, and creative narrative prose.",
                            learning_objective: "Draft original narrative stories utilizing sensory imagery, plot twists, and varied narrative voices.",
                            display_order: NumberInt(2)
                        },
                        {
                            topic_id: "eng_topic_006",
                            number: "2.3",
                            title: "Paragraph Development",
                            description: "Drafting unified paragraphs utilizing topic sentences, supporting data, and logical transitional markers.",
                            learning_objective: "Ensure paragraph unity and logical flow through effective transitional phrases and evidence synthesis.",
                            display_order: NumberInt(3)
                        }
                    ]
                },
                {
                    chapter_id: "eng_ch_003",
                    title: "Grammar: Tenses, Active & Passive Voice",
                    display_order: NumberInt(3),
                    is_locked: false,
                    topics: [
                        {
                            topic_id: "eng_topic_007",
                            number: "3.1",
                            title: "Present, Past and Future Tenses",
                            description: "Systematic exploration of simple, continuous, perfect, and perfect continuous tenses across timelines.",
                            learning_objective: "Apply correct grammatical tenses consistently across academic writing and formal correspondence.",
                            display_order: NumberInt(1)
                        },
                        {
                            topic_id: "eng_topic_008",
                            number: "3.2",
                            title: "Active Voice",
                            description: "Sentence mechanics where the subject performs the verb action directly to produce concise, dynamic sentences.",
                            learning_objective: "Construct assertive, direct sentences using active voice constructions in expository compositions.",
                            display_order: NumberInt(2)
                        },
                        {
                            topic_id: "eng_topic_009",
                            number: "3.3",
                            title: "Passive Voice",
                            description: "Converting active sentences into passive voice, emphasizing the recipient of action and handling omitted agents.",
                            learning_objective: "Identify appropriate contexts for passive voice in scientific reporting, news headlines, and formal notices.",
                            display_order: NumberInt(3)
                        }
                    ]
                }
            ]
        },

        // =========================================================================
        // Subject 2: Mathematics
        // =========================================================================
        {
            subject_id: toScopeId(2),
            subject_name: "Mathematics",
            chapters: [
                {
                    chapter_id: "mat_ch_001",
                    title: "Number Systems & Rational Numbers",
                    display_order: NumberInt(1),
                    is_locked: false,
                    topics: [
                        {
                            topic_id: "mat_topic_001",
                            number: "1.1",
                            title: "Natural and Whole Numbers",
                            description: "Fundamental properties of counting numbers, zero, closure, commutativity, and associativity under basic operations.",
                            learning_objective: "Distinguish natural numbers from whole numbers and verify fundamental algebraic arithmetic laws.",
                            display_order: NumberInt(1)
                        },
                        {
                            topic_id: "mat_topic_002",
                            number: "1.2",
                            title: "Integers",
                            description: "Operations on positive and negative integers, magnitude concepts, absolute values, and number line geometry.",
                            learning_objective: "Execute signed integer operations accurately and solve real-world problems involving directed numbers.",
                            display_order: NumberInt(2)
                        },
                        {
                            topic_id: "mat_topic_003",
                            number: "1.3",
                            title: "Rational Numbers",
                            description: "Representation, simplification, and four arithmetic operations on rational numbers in p/q form where q is non-zero.",
                            learning_objective: "Perform arithmetic operations on rational numbers and plot terminating/repeating values on a number line.",
                            display_order: NumberInt(3)
                        }
                    ]
                },
                {
                    chapter_id: "mat_ch_002",
                    title: "Linear Equations & Algebra",
                    display_order: NumberInt(2),
                    is_locked: false,
                    topics: [
                        {
                            topic_id: "mat_topic_004",
                            number: "2.1",
                            title: "Algebraic Expressions",
                            description: "Constants, variables, terms, coefficients, degree, and algebraic formulation of word problems.",
                            learning_objective: "Formulate and evaluate algebraic expressions by substituting numerical values for unknown variables.",
                            display_order: NumberInt(1)
                        },
                        {
                            topic_id: "mat_topic_005",
                            number: "2.2",
                            title: "Linear Equations",
                            description: "Solving first-degree linear equations in one variable using transposition, inverse operations, and balancing.",
                            learning_objective: "Solve single-variable linear equations and verify solutions through backward substitution.",
                            display_order: NumberInt(2)
                        },
                        {
                            topic_id: "mat_topic_006",
                            number: "2.3",
                            title: "Polynomials",
                            description: "Classification of polynomials into monomials, binomials, and trinomials, alongside polynomial addition and subtraction.",
                            learning_objective: "Classify polynomials by degree and number of terms, performing addition and subtraction of like terms.",
                            display_order: NumberInt(3)
                        }
                    ]
                },
                {
                    chapter_id: "mat_ch_003",
                    title: "Geometry: Triangles & Constructions",
                    display_order: NumberInt(3),
                    is_locked: false,
                    topics: [
                        {
                            topic_id: "mat_topic_007",
                            number: "3.1",
                            title: "Types of Triangles",
                            description: "Classification of triangles by sides (equilateral, isosceles, scalene) and by angles (acute, right, obtuse).",
                            learning_objective: "Classify triangles accurately and apply the angle sum property (interior angles sum to 180°).",
                            display_order: NumberInt(1)
                        },
                        {
                            topic_id: "mat_topic_008",
                            number: "3.2",
                            title: "Properties of Triangles",
                            description: "Exterior angle theorem, triangle inequality theorem, altitudes, medians, and Pythagorean right-triangle theorem.",
                            learning_objective: "Apply geometric theorems regarding exterior angles and side length inequalities to solve angle problems.",
                            display_order: NumberInt(2)
                        },
                        {
                            topic_id: "mat_topic_009",
                            number: "3.3",
                            title: "Geometrical Constructions",
                            description: "Step-by-step compass and straightedge constructions of parallel lines, angle bisectors, and congruent triangles.",
                            learning_objective: "Construct triangles using SSS, SAS, ASA, and RHS criteria with compass and ruler precision.",
                            display_order: NumberInt(3)
                        }
                    ]
                }
            ]
        },

        // =========================================================================
        // Subject 4: Social Science
        // =========================================================================
        {
            subject_id: toScopeId(4),
            subject_name: "Social Science",
            chapters: [
                {
                    chapter_id: "sst_ch_001",
                    title: "Climate & Weather Patterns",
                    display_order: NumberInt(1),
                    is_locked: false,
                    topics: [
                        {
                            topic_id: "sst_topic_001",
                            number: "1.1",
                            title: "Climate Zones",
                            description: "Classification of Earth's major climatic regions: Torrid, Temperate, and Frigid zones based on solar insolation.",
                            learning_objective: "Identify the geographical boundaries and weather characteristics of major global climatic zones.",
                            display_order: NumberInt(1)
                        },
                        {
                            topic_id: "sst_topic_002",
                            number: "1.2",
                            title: "Weather Patterns",
                            description: "Daily meteorological factors including humidity, air pressure, precipitation, and measuring instruments.",
                            learning_objective: "Analyze isobaric weather maps, interpret barometer readings, and explain seasonal monsoons.",
                            display_order: NumberInt(2)
                        },
                        {
                            topic_id: "sst_topic_003",
                            number: "1.3",
                            title: "Factors Affecting Climate",
                            description: "Impact of latitude, altitude, distance from the sea (continentality), ocean currents, and relief features.",
                            learning_objective: "Evaluate how geographical factors modify regional temperature variations and rainfall distribution.",
                            display_order: NumberInt(3)
                        }
                    ]
                },
                {
                    chapter_id: "sst_ch_002",
                    title: "Democracy & Elections",
                    display_order: NumberInt(2),
                    is_locked: false,
                    topics: [
                        {
                            topic_id: "sst_topic_004",
                            number: "2.1",
                            title: "Meaning of Democracy",
                            description: "Evolution of democratic systems, rule of law, majority rule with minority protections, and direct vs representative systems.",
                            learning_objective: "Define democratic principles and contrast representative democracies with authoritarian regimes.",
                            display_order: NumberInt(1)
                        },
                        {
                            topic_id: "sst_topic_005",
                            number: "2.2",
                            title: "Election Process",
                            description: "Functions of the Election Commission, voter registration, constituencies, secret ballot voting, and campaign rules.",
                            learning_objective: "Explain the step-by-step electoral lifecycle from model code of conduct to vote tabulation.",
                            display_order: NumberInt(2)
                        },
                        {
                            topic_id: "sst_topic_006",
                            number: "2.3",
                            title: "Role of Citizens",
                            description: "Civic engagement, voting responsibilities, constructive public dissent, media literacy, and community participation.",
                            learning_objective: "Recognize citizen responsibilities and effective mechanisms for holding elected representatives accountable.",
                            display_order: NumberInt(3)
                        }
                    ]
                },
                {
                    chapter_id: "sst_ch_003",
                    title: "Indian Federal Constitution",
                    display_order: NumberInt(3),
                    is_locked: false,
                    topics: [
                        {
                            topic_id: "sst_topic_007",
                            number: "3.1",
                            title: "Constitutional Principles",
                            description: "Preamble values: sovereignty, socialism, secularism, democracy, republic, justice, liberty, equality, and fraternity.",
                            learning_objective: "Interpret the philosophical foundation and institutional checks and balances enshrined in the Constitution.",
                            display_order: NumberInt(1)
                        },
                        {
                            topic_id: "sst_topic_008",
                            number: "3.2",
                            title: "Fundamental Rights",
                            description: "The six constitutional guarantees under Part III, reasonable restrictions, and judicial enforcement via writ petitions.",
                            learning_objective: "Explain the six Fundamental Rights and the judicial mechanism of constitutional remedies under Article 32.",
                            display_order: NumberInt(2)
                        },
                        {
                            topic_id: "sst_topic_009",
                            number: "3.3",
                            title: "Union and State Government",
                            description: "Division of legislative and executive powers across Union List, State List, and Concurrent List under federalism.",
                            learning_objective: "Distinguish federal jurisdictions between the Union Parliament and State Legislative Assemblies.",
                            display_order: NumberInt(3)
                        }
                    ]
                }
            ]
        },

        // =========================================================================
        // Subject 5: Computer Science
        // =========================================================================
        {
            subject_id: toScopeId(5),
            subject_name: "Computer Science",
            chapters: [
                {
                    chapter_id: "csc_ch_001",
                    title: "Algorithms & Python Programming",
                    display_order: NumberInt(1),
                    is_locked: false,
                    topics: [
                        {
                            topic_id: "csc_topic_001",
                            number: "1.1",
                            title: "Introduction to Algorithms",
                            description: "Algorithmic problem-solving, flowchart symbols, pseudocode conventions, sequencing, and step-by-step logic.",
                            learning_objective: "Design logical algorithms and structured flowcharts to solve computational problems systematically.",
                            display_order: NumberInt(1)
                        },
                        {
                            topic_id: "csc_topic_002",
                            number: "1.2",
                            title: "Variables and Data Types",
                            description: "Python variable declaration, identifier naming rules, and basic types: int, float, string, and boolean.",
                            learning_objective: "Write clean Python code declaring variables, performing type conversions, and using standard I/O functions.",
                            display_order: NumberInt(2)
                        },
                        {
                            topic_id: "csc_topic_003",
                            number: "1.3",
                            title: "Conditional Statements",
                            description: "Decision-making structures using if, if-else, and if-elif-else statements with logical and comparison operators.",
                            learning_objective: "Implement branching control logic in Python programs using comparison and Boolean operators.",
                            display_order: NumberInt(3)
                        }
                    ]
                },
                {
                    chapter_id: "csc_ch_002",
                    title: "Databases & SQL Basics",
                    display_order: NumberInt(2),
                    is_locked: false,
                    topics: [
                        {
                            topic_id: "csc_topic_004",
                            number: "2.1",
                            title: "Introduction to Databases",
                            description: "Relational database concepts, tables, records, fields, primary keys, and benefits over flat spreadsheets.",
                            learning_objective: "Understand relational database structure, schema design, and primary key uniqueness constraints.",
                            display_order: NumberInt(1)
                        },
                        {
                            topic_id: "csc_topic_005",
                            number: "2.2",
                            title: "SQL SELECT Queries",
                            description: "Syntax and usage of SQL SELECT statements, column aliasing, and retrieving complete or subset table rows.",
                            learning_objective: "Compose syntactically correct SQL SELECT queries to retrieve targeted columns from relational tables.",
                            display_order: NumberInt(2)
                        },
                        {
                            topic_id: "csc_topic_006",
                            number: "2.3",
                            title: "Filtering and Sorting Data",
                            description: "Utilizing WHERE clauses, comparison operators, logical AND/OR, and sorting result sets using ORDER BY ASC/DESC.",
                            learning_objective: "Filter query results with conditional criteria and organize result sets in ascending or descending order.",
                            display_order: NumberInt(3)
                        }
                    ]
                },
                {
                    chapter_id: "csc_ch_003",
                    title: "Cybersecurity & Digital Safety",
                    display_order: NumberInt(3),
                    is_locked: false,
                    topics: [
                        {
                            topic_id: "csc_topic_007",
                            number: "3.1",
                            title: "Online Safety",
                            description: "Safe internet browsing habits, digital footprint awareness, privacy settings on social networks, and cyberbullying.",
                            learning_objective: "Demonstrate safe online browsing behaviors and manage privacy settings on digital platforms.",
                            display_order: NumberInt(1)
                        },
                        {
                            topic_id: "csc_topic_008",
                            number: "3.2",
                            title: "Passwords and Authentication",
                            description: "Password complexity requirements, entropy, multi-factor authentication (MFA/2FA), and password manager tools.",
                            learning_objective: "Construct robust credentials and explain how two-factor authentication safeguards user accounts.",
                            display_order: NumberInt(2)
                        },
                        {
                            topic_id: "csc_topic_009",
                            number: "3.3",
                            title: "Recognizing Online Threats",
                            description: "Identification of phishing emails, suspicious URLs, spyware, trojans, ransomware, and social engineering attacks.",
                            learning_objective: "Identify signs of deceptive phishing attempts and execute standard incident reporting procedures.",
                            display_order: NumberInt(3)
                        }
                    ]
                }
            ]
        },

        // =========================================================================
        // Subject 6: Physical Education
        // =========================================================================
        {
            subject_id: toScopeId(6),
            subject_name: "Physical Education",
            chapters: [
                {
                    chapter_id: "pe_ch_001",
                    title: "Athletics & Sprint Training",
                    display_order: NumberInt(1),
                    is_locked: false,
                    topics: [
                        {
                            topic_id: "pe_topic_001",
                            number: "1.1",
                            title: "Sprint Techniques",
                            description: "Proper biomechanics of sprinting: posture, arm swing, knee lift, stride frequency, and foot strike positioning.",
                            learning_objective: "Demonstrate optimal sprint biomechanics to maximize velocity while reducing aerodynamic drag.",
                            display_order: NumberInt(1)
                        },
                        {
                            topic_id: "pe_topic_002",
                            number: "1.2",
                            title: "Starting and Acceleration",
                            description: "Three-point and block start setups, reaction time off the whistle, and transition from drive phase to upright stride.",
                            learning_objective: "Execute explosive starting block departures and maintain low-angle acceleration during the drive phase.",
                            display_order: NumberInt(2)
                        },
                        {
                            topic_id: "pe_topic_003",
                            number: "1.3",
                            title: "Endurance Training",
                            description: "Aerobic conditioning, pacing strategies for middle and long-distance running, and cardiovascular stamina.",
                            learning_objective: "Apply steady pacing techniques and breath control during prolonged cardiovascular endurance runs.",
                            display_order: NumberInt(3)
                        }
                    ]
                },
                {
                    chapter_id: "pe_ch_002",
                    title: "Badminton & Racket Sports",
                    display_order: NumberInt(2),
                    is_locked: false,
                    topics: [
                        {
                            topic_id: "pe_topic_004",
                            number: "2.1",
                            title: "Racket Grip and Stance",
                            description: "Mastering forehand (shakehand) and backhand grips, ready stance at mid-court, and racket head positioning.",
                            learning_objective: "Switch fluidly between forehand and backhand grips based on shuttlecock trajectory.",
                            display_order: NumberInt(1)
                        },
                        {
                            topic_id: "pe_topic_005",
                            number: "2.2",
                            title: "Serving Techniques",
                            description: "Rules, trajectories, and wrist action for high singles serves, low doubles serves, and flick serves.",
                            learning_objective: "Deliver legal, accurate low and high serves conforming to Badminton World Federation (BWF) guidelines.",
                            display_order: NumberInt(2)
                        },
                        {
                            topic_id: "pe_topic_006",
                            number: "2.3",
                            title: "Footwork and Court Movement",
                            description: "Chassé steps, scissor lunges, split-step recovery, and transitioning efficiently between all four corners.",
                            learning_objective: "Execute balanced split-step court coverage and recover promptly to the central base position.",
                            display_order: NumberInt(3)
                        }
                    ]
                },
                {
                    chapter_id: "pe_ch_003",
                    title: "Yoga & Flexibility Training",
                    display_order: NumberInt(3),
                    is_locked: false,
                    topics: [
                        {
                            topic_id: "pe_topic_007",
                            number: "3.1",
                            title: "Basic Yoga Postures",
                            description: "Foundational standing and seated asanas: Tadasana, Vrikshasana, Bhujangasana, and Paschimottanasana alignment.",
                            learning_objective: "Perform foundational yoga postures with correct spinal alignment and joint stability.",
                            display_order: NumberInt(1)
                        },
                        {
                            topic_id: "pe_topic_008",
                            number: "3.2",
                            title: "Breathing Techniques",
                            description: "Pranayama practices including Anulom Vilom (alternate nostril) and Kapalabhati, focusing on mindfulness and lung volume.",
                            learning_objective: "Coordinate diaphragmatic breathing with physical movements to lower resting heart rate and mental stress.",
                            display_order: NumberInt(2)
                        },
                        {
                            topic_id: "pe_topic_009",
                            number: "3.3",
                            title: "Flexibility Exercises",
                            description: "Static and dynamic stretching routines targeting hamstrings, hip flexors, shoulder girdle, and core mobility.",
                            learning_objective: "Design safe pre-workout dynamic stretching and post-workout static flexibility cooldown routines.",
                            display_order: NumberInt(3)
                        }
                    ]
                }
            ]
        }
    ];

    // 3. Construct syllabus documents
    const documents = syllabi.map((item) => {
        return {
            school_id: toScopeId(1),
            branch_id: toScopeId(1),
            academic_year_id: toScopeId(1),
            class_id: toScopeId(1),
            subject_id: item.subject_id,
            syllabus_version: NumberInt(1),
            chapters: item.chapters,
            is_active: true,
            created_at: now,
            updated_at: now,
            created_by: adminUserId,
            updated_by: adminUserId
        };
    });

    // 4. Idempotent Upsert for each subject syllabus
    print(`Processing ${documents.length} syllabus documents...`);

    let insertedCount = 0;
    let modifiedCount = 0;

    documents.forEach((doc) => {
        const filter = {
            school_id: doc.school_id,
            branch_id: doc.branch_id,
            academic_year_id: doc.academic_year_id,
            class_id: doc.class_id,
            subject_id: doc.subject_id,
            syllabus_version: doc.syllabus_version
        };

        const result = col.updateOne(
            filter,
            { $set: doc },
            { upsert: true }
        );

        if (result.upsertedCount > 0) {
            insertedCount += result.upsertedCount;
            print(`  [+] Inserted Syllabus for Subject ID: ${doc.subject_id}`);
        } else if (result.modifiedCount > 0) {
            modifiedCount += result.modifiedCount;
            print(`  [*] Updated Syllabus for Subject ID: ${doc.subject_id}`);
        } else {
            print(`  [-] Existing Syllabus already up to date for Subject ID: ${doc.subject_id}`);
        }
    });

    print(`\n✓ SUCCESS: ${insertedCount} inserted, ${modifiedCount} updated in 'class_subject_syllabus'.\n`);

    // 5. Verification Report
    print("==============================================================================");
    print("VERIFICATION & SYLLABUS AUDIT REPORT");
    print("==============================================================================");

    const verifiedDocs = col.find({
        school_id: toScopeId(1),
        branch_id: toScopeId(1),
        academic_year_id: toScopeId(1),
        class_id: toScopeId(1),
        syllabus_version: NumberInt(1)
    }).sort({ subject_id: 1 }).toArray();

    print(`Total Active Syllabi for Class 1 (including Science): ${verifiedDocs.length}`);
    verifiedDocs.forEach((s) => {
        const chCount = s.chapters ? s.chapters.length : 0;
        let topCount = 0;
        if (s.chapters) {
            s.chapters.forEach((c) => {
                if (c.topics) topCount += c.topics.length;
            });
        }
        print(`  - Subject ID [${s.subject_id}]: ${chCount} chapters, ${topCount} total topics | is_active: ${s.is_active}`);
    });

    print("==============================================================================\n");
})();
