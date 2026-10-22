/**
 * ==============================================================================
 * MongoDB Seed Script: Learning Resources Mock Data
 * Target Collection : Learning_resource(documents)
 * Target Scope      :
 *   - school_id        = 1
 *   - branch_id        = 1
 *   - academic_year_id = 1
 *   - class_id         = 1
 *   - section_id       = 1
 *   - syllabus_version = 1
 *   - subject_ids      = [1, 2, 4, 5, 6] (English, Mathematics, Social Science,
 *                                        Computer Science, Physical Education)
 * Note: Subject 3 (Science) already exists in this collection and is preserved 100% UNTOUCHED.
 *
 * Curriculum Matrix:
 *   - 5 Subjects
 *   - 3 Chapters per Subject (15 Chapters total)
 *   - 3 Topics per Chapter (45 Topics total)
 *   - 3 Resources per Topic:
 *       1. VIDEO + TEACHER   (Teacher masterclass video lecture)
 *       2. NOTE  + TEACHER   (Teacher lecture notes & formula guide)
 *       3. NOTE  + COMPASS   (Compass AI quick revision & exam cards)
 * Total Documents   : 45 Topics * 3 Resources = 135 Documents
 *
 * Strict Validation : 100% compliant with collection $jsonSchema validator
 *                      and partial unique indexes.
 *
 * Usage:
 *   mongosh "mongodb://<connection_string>/<db_name>" insert_class1_learning_resources_mock_data.js
 * ==============================================================================
 */

(function () {
    "use strict";

    // 1. Explicitly target collection: Learning_resource(documents)
    // Note: In MongoDB / JavaScript, collections with special characters (like parentheses)
    // must be accessed using db.getCollection("...") or db["..."].
    const targetCollectionName = "Learning_resource(documents)";
    const col = db.getCollection(targetCollectionName);

    print(`\n==============================================================================`);
    print(`Target Collection: ${targetCollectionName}`);
    print(`Target Scope     : School 1, Branch 1, Class 1, Section 1, Academic Year 1`);
    print(`Subjects to Seed : 1 (English), 2 (Mathematics), 4 (Social Science), 5 (Computer Science), 6 (Physical Education)`);
    print(`==============================================================================\n`);

    const now = new Date("2026-04-01T08:00:00.000Z");
    const adminUserId = NumberInt(101); // Class 1 Section 1 Teacher

    // 2. Audit existing Science (Subject 3) documents in Learning_resource(documents)
    const existingScienceCount = col.countDocuments({
        school_id: { $in: [1, NumberInt(1)] },
        branch_id: { $in: [1, NumberInt(1)] },
        academic_year_id: { $in: [1, NumberInt(1)] },
        class_id: { $in: [1, NumberInt(1)] },
        section_id: { $in: [1, NumberInt(1)] },
        subject_id: { $in: [3, NumberInt(3)] }
    });
    print(`Existing Science (Subject 3) documents detected: ${existingScienceCount}`);
    print(`Note: Science documents are strictly isolated and will remain 100% untouched.\n`);

    // 3. Define curriculum taxonomy for subjects 1, 2, 4, 5, 6
    const curriculumData = [
        // =========================================================================
        // Subject 1: English
        // =========================================================================
        {
            subject_id: 1,
            subject_code: "eng",
            subject_name: "English",
            chapters: [
                {
                    chapter_id: "eng_ch_001",
                    chapter_title: "English Literature & Comprehension",
                    topics: [
                        {
                            topic_id: "eng_topic_001",
                            title: "Poetry and Prose",
                            description: "Comprehensive analysis of classical and contemporary poetry and prose forms, stylistic structures, and expressive devices.",
                            duration: 780,
                            takeaways: [
                                "Differentiate structural poetic devices from narrative prose forms.",
                                "Analyze meter, stanza schemes, and tone in selected poems.",
                                "Examine prose excerpts for character motivations and thematic progression."
                            ]
                        },
                        {
                            topic_id: "eng_topic_002",
                            title: "Literary Devices",
                            description: "Identification and interpretation of figurative language including metaphors, similes, personification, and alliteration.",
                            duration: 840,
                            takeaways: [
                                "Identify similes, metaphors, hyperbole, and personification in unseen texts.",
                                "Explain how imagery and alliteration heighten emotional and aesthetic impact.",
                                "Interpret symbolic motifs in classical and contemporary literature."
                            ]
                        },
                        {
                            topic_id: "eng_topic_003",
                            title: "Character Analysis",
                            description: "Frameworks for examining character motivations, internal conflicts, dialogue cues, and character progression arcs.",
                            duration: 900,
                            takeaways: [
                                "Evaluate protagonists and antagonists using textual citations and dialogue analysis.",
                                "Trace character arcs through key exposition, conflict, and resolution moments.",
                                "Contrast dynamic characters with static character archetypes."
                            ]
                        }
                    ]
                },
                {
                    chapter_id: "eng_ch_002",
                    chapter_title: "Essay Writing & Creative Composition",
                    topics: [
                        {
                            topic_id: "eng_topic_004",
                            title: "Essay Structure",
                            description: "Architecting structured essays featuring introduction hooks, thesis statements, body development, and syntheses.",
                            duration: 860,
                            takeaways: [
                                "Formulate clear thesis statements that anchor whole-essay arguments.",
                                "Construct cohesive body paragraphs with evidence and analytical reasoning.",
                                "Draft effective conclusions that synthesize arguments without repetitive restatement."
                            ]
                        },
                        {
                            topic_id: "eng_topic_005",
                            title: "Creative Writing",
                            description: "Techniques for sensory descriptions, dynamic world-building, dialogue pacing, and creative narrative prose.",
                            duration: 980,
                            takeaways: [
                                "Employ multi-sensory imagery to build immersive narrative settings.",
                                "Write natural dialogue that drives plot progression and reveals character traits.",
                                "Apply pacing techniques to heighten tension and suspense in storytelling."
                            ]
                        },
                        {
                            topic_id: "eng_topic_006",
                            title: "Paragraph Development",
                            description: "Drafting unified paragraphs utilizing topic sentences, supporting data, and logical transitional markers.",
                            duration: 790,
                            takeaways: [
                                "Craft focused topic sentences providing singular thematic clarity.",
                                "Utilize transitional connectives for smooth flow between ideas.",
                                "Ensure paragraph unity through relevant supporting sentences and examples."
                            ]
                        }
                    ]
                },
                {
                    chapter_id: "eng_ch_003",
                    chapter_title: "Grammar: Tenses, Active & Passive Voice",
                    topics: [
                        {
                            topic_id: "eng_topic_007",
                            title: "Present, Past and Future Tenses",
                            description: "Systematic exploration of simple, continuous, perfect, and perfect continuous tenses across timelines.",
                            duration: 920,
                            takeaways: [
                                "Master the 12 grammatical tense forms and their precise temporal applications.",
                                "Maintain consistent verb tense across multi-clause sentences and paragraphs.",
                                "Avoid common irregular past-tense conjugation pitfalls."
                            ]
                        },
                        {
                            topic_id: "eng_topic_008",
                            title: "Active Voice",
                            description: "Sentence mechanics where the subject performs the verb action directly to produce concise, dynamic sentences.",
                            duration: 810,
                            takeaways: [
                                "Identify subject-verb-object structures characteristic of active voice.",
                                "Revise wordy passive clauses into direct, energetic active sentences.",
                                "Apply active voice in persuasive essays and narrative prose."
                            ]
                        },
                        {
                            topic_id: "eng_topic_009",
                            title: "Passive Voice",
                            description: "Converting active sentences into passive voice, emphasizing the recipient of action and handling omitted agents.",
                            duration: 880,
                            takeaways: [
                                "Convert active sentences to passive voice using auxiliary verbs and past participles.",
                                "Recognize appropriate uses for passive voice in scientific and formal reports.",
                                "Determine when omitting the agent ('by...') clarifies emphasis on the action."
                            ]
                        }
                    ]
                }
            ]
        },

        // =========================================================================
        // Subject 2: Mathematics
        // =========================================================================
        {
            subject_id: 2,
            subject_code: "mat",
            subject_name: "Mathematics",
            chapters: [
                {
                    chapter_id: "mat_ch_001",
                    chapter_title: "Number Systems & Rational Numbers",
                    topics: [
                        {
                            topic_id: "mat_topic_001",
                            title: "Natural and Whole Numbers",
                            description: "Fundamental properties of counting numbers, zero, closure, commutativity, and associativity under basic operations.",
                            duration: 840,
                            takeaways: [
                                "Distinguish natural numbers (N) from whole numbers (W).",
                                "Verify commutative, associative, and distributive arithmetic laws.",
                                "Apply the multiplicative and additive identity properties of zero and one."
                            ]
                        },
                        {
                            topic_id: "mat_topic_002",
                            title: "Integers",
                            description: "Operations on positive and negative integers, magnitude concepts, absolute values, and number line geometry.",
                            duration: 900,
                            takeaways: [
                                "Perform signed integer addition, subtraction, multiplication, and division.",
                                "Interpret absolute value as geometric distance from zero.",
                                "Solve multi-step real-world problems with negative quantities."
                            ]
                        },
                        {
                            topic_id: "mat_topic_003",
                            title: "Rational Numbers",
                            description: "Representation, simplification, and four arithmetic operations on rational numbers in p/q form where q is non-zero.",
                            duration: 960,
                            takeaways: [
                                "Express terminating and repeating decimals in rational p/q fraction form.",
                                "Find rational numbers between any two given rational values.",
                                "Apply BODMAS / PEMDAS rules on composite rational expressions."
                            ]
                        }
                    ]
                },
                {
                    chapter_id: "mat_ch_002",
                    chapter_title: "Linear Equations & Algebra",
                    topics: [
                        {
                            topic_id: "mat_topic_004",
                            title: "Algebraic Expressions",
                            description: "Constants, variables, terms, coefficients, degree, and algebraic formulation of word problems.",
                            duration: 860,
                            takeaways: [
                                "Translate verbal problem statements into algebraic expressions.",
                                "Identify like terms and combine them across polynomial expressions.",
                                "Evaluate algebraic expressions by substituting numerical values."
                            ]
                        },
                        {
                            topic_id: "mat_topic_005",
                            title: "Linear Equations",
                            description: "Solving first-degree linear equations in one variable using transposition, inverse operations, and balancing.",
                            duration: 1020,
                            takeaways: [
                                "Solve linear equations with variables on one and both sides.",
                                "Clear fractions and parentheses using the distributive property.",
                                "Verify solutions by substituting roots back into the original equation."
                            ]
                        },
                        {
                            topic_id: "mat_topic_006",
                            title: "Polynomials",
                            description: "Classification of polynomials into monomials, binomials, and trinomials, alongside polynomial addition and subtraction.",
                            duration: 910,
                            takeaways: [
                                "Classify polynomials by number of terms and highest exponent degree.",
                                "Perform horizontal and vertical addition and subtraction of polynomials.",
                                "Multiply binomials using FOIL / distributive expansion methods."
                            ]
                        }
                    ]
                },
                {
                    chapter_id: "mat_ch_003",
                    chapter_title: "Geometry: Triangles & Constructions",
                    topics: [
                        {
                            topic_id: "mat_topic_007",
                            title: "Types of Triangles",
                            description: "Classification of triangles by sides (equilateral, isosceles, scalene) and by angles (acute, right, obtuse).",
                            duration: 870,
                            takeaways: [
                                "Classify triangles by side length and internal angle measurements.",
                                "Apply the angle sum property: the three interior angles sum to 180°.",
                                "Identify symmetrical axes and angle properties of isosceles triangles."
                            ]
                        },
                        {
                            topic_id: "mat_topic_008",
                            title: "Properties of Triangles",
                            description: "Exterior angle theorem, triangle inequality theorem, altitudes, medians, and Pythagorean right-triangle theorem.",
                            duration: 1040,
                            takeaways: [
                                "Apply the exterior angle theorem to compute missing exterior angles.",
                                "Use the triangle inequality theorem to determine if three side lengths form a valid triangle.",
                                "Calculate hypotenuse and leg lengths using the Pythagorean theorem."
                            ]
                        },
                        {
                            topic_id: "mat_topic_009",
                            title: "Geometrical Constructions",
                            description: "Step-by-step compass and straightedge constructions of parallel lines, angle bisectors, and congruent triangles.",
                            duration: 980,
                            takeaways: [
                                "Construct angle bisectors and perpendicular bisectors using a compass and straightedge.",
                                "Construct triangles given side and angle specifications (SSS, SAS, ASA).",
                                "Verify congruent construction accuracy with protractor and ruler measurements."
                            ]
                        }
                    ]
                }
            ]
        },

        // =========================================================================
        // Subject 4: Social Science
        // =========================================================================
        {
            subject_id: 4,
            subject_code: "sst",
            subject_name: "Social Science",
            chapters: [
                {
                    chapter_id: "sst_ch_001",
                    chapter_title: "Climate & Weather Patterns",
                    topics: [
                        {
                            topic_id: "sst_topic_001",
                            title: "Climate Zones",
                            description: "Classification of Earth's major climatic regions: Torrid, Temperate, and Frigid zones based on solar insolation.",
                            duration: 830,
                            takeaways: [
                                "Locate the Torrid, Temperate, and Frigid zones on world globes and maps.",
                                "Explain how sunlight angle of incidence causes regional temperature differences.",
                                "Correlate global climatic zones with biomes and agricultural patterns."
                            ]
                        },
                        {
                            topic_id: "sst_topic_002",
                            title: "Weather Patterns",
                            description: "Daily meteorological factors including humidity, air pressure, precipitation, and measuring instruments.",
                            duration: 890,
                            takeaways: [
                                "Interpret weather station models, isotherms, and isobaric maps.",
                                "Explain the mechanism of atmospheric pressure belts and prevailing winds.",
                                "Distinguish convectional, orographic, and cyclonic rainfall mechanisms."
                            ]
                        },
                        {
                            topic_id: "sst_topic_003",
                            title: "Factors Affecting Climate",
                            description: "Impact of latitude, altitude, distance from the sea (continentality), ocean currents, and relief features.",
                            duration: 920,
                            takeaways: [
                                "Analyze how altitude decreases ambient temperature at the normal lapse rate.",
                                "Explain maritime moderation vs continental climate temperature extremes.",
                                "Evaluate how mountain ranges create wet windward and dry leeward rain shadows."
                            ]
                        }
                    ]
                },
                {
                    chapter_id: "sst_ch_002",
                    chapter_title: "Democracy & Elections",
                    topics: [
                        {
                            topic_id: "sst_topic_004",
                            title: "Meaning of Democracy",
                            description: "Evolution of democratic systems, rule of law, majority rule with minority protections, and direct vs representative systems.",
                            duration: 850,
                            takeaways: [
                                "Define democracy as government of, by, and for the people.",
                                "Differentiate direct Athenian democracy from modern representative democracies.",
                                "Identify essential pillars: free speech, independent judiciary, and periodic elections."
                            ]
                        },
                        {
                            topic_id: "sst_topic_005",
                            title: "Election Process",
                            description: "Functions of the Election Commission, voter registration, constituencies, secret ballot voting, and campaign rules.",
                            duration: 960,
                            takeaways: [
                                "Outline the lifecycle of general elections from voter rolls to result declaration.",
                                "Explain the constitutional powers of the independent Election Commission.",
                                "Understand the purpose of the Model Code of Conduct during campaigns."
                            ]
                        },
                        {
                            topic_id: "sst_topic_006",
                            title: "Role of Citizens",
                            description: "Civic engagement, voting responsibilities, constructive public dissent, media literacy, and community participation.",
                            duration: 880,
                            takeaways: [
                                "Recognize informed voting as both a democratic right and civic responsibility.",
                                "Analyze peaceful civic participation methods in public policy formulation.",
                                "Develop critical media literacy to identify political disinformation."
                            ]
                        }
                    ]
                },
                {
                    chapter_id: "sst_ch_003",
                    chapter_title: "Indian Federal Constitution",
                    topics: [
                        {
                            topic_id: "sst_topic_007",
                            title: "Constitutional Principles",
                            description: "Preamble values: sovereignty, socialism, secularism, democracy, republic, justice, liberty, equality, and fraternity.",
                            duration: 940,
                            takeaways: [
                                "Interpret the core ideals articulated in the Preamble to the Indian Constitution.",
                                "Explain secularism and equal state respect for all faiths.",
                                "Describe how the separation of powers prevents state overreach."
                            ]
                        },
                        {
                            topic_id: "sst_topic_008",
                            title: "Fundamental Rights",
                            description: "The six constitutional guarantees under Part III, reasonable restrictions, and judicial enforcement via writ petitions.",
                            duration: 1050,
                            takeaways: [
                                "Examine the six Fundamental Rights guaranteeing equality, freedom, and protection.",
                                "Understand judicial enforcement through writ remedies under Article 32.",
                                "Recognize reasonable restrictions balanced with national security and public order."
                            ]
                        },
                        {
                            topic_id: "sst_topic_009",
                            title: "Union and State Government",
                            description: "Division of legislative and executive powers across Union List, State List, and Concurrent List under federalism.",
                            duration: 970,
                            takeaways: [
                                "Differentiate legislative jurisdictions under Union, State, and Concurrent Lists.",
                                "Describe the dual federal executive structure: President/PM and Governor/CM.",
                                "Explain how federalism accommodates regional diversity while maintaining unity."
                            ]
                        }
                    ]
                }
            ]
        },

        // =========================================================================
        // Subject 5: Computer Science
        // =========================================================================
        {
            subject_id: 5,
            subject_code: "csc",
            subject_name: "Computer Science",
            chapters: [
                {
                    chapter_id: "csc_ch_001",
                    chapter_title: "Algorithms & Python Programming",
                    topics: [
                        {
                            topic_id: "csc_topic_001",
                            title: "Introduction to Algorithms",
                            description: "Algorithmic problem-solving, flowchart symbols, pseudocode conventions, sequencing, and step-by-step logic.",
                            duration: 850,
                            takeaways: [
                                "Formulate sequential, unambiguous algorithmic steps for computation.",
                                "Draw standard flowchart diagrams using start, process, decision, and I/O symbols.",
                                "Evaluate algorithm efficiency and correctness through dry runs and test tables."
                            ]
                        },
                        {
                            topic_id: "csc_topic_002",
                            title: "Variables and Data Types",
                            description: "Python variable declaration, identifier naming rules, and basic types: int, float, string, and boolean.",
                            duration: 910,
                            takeaways: [
                                "Declare and reassign Python variables following PEP 8 identifier rules.",
                                "Distinguish integer, float, string, and boolean primitive data types.",
                                "Perform explicit type casting between strings and numeric types."
                            ]
                        },
                        {
                            topic_id: "csc_topic_003",
                            title: "Conditional Statements",
                            description: "Decision-making structures using if, if-else, and if-elif-else statements with logical and comparison operators.",
                            duration: 990,
                            takeaways: [
                                "Construct compound boolean expressions using comparison and logical operators.",
                                "Implement multi-way decision branching with if-elif-else ladders.",
                                "Avoid common indentation and logical pitfalls in nested conditionals."
                            ]
                        }
                    ]
                },
                {
                    chapter_id: "csc_ch_002",
                    chapter_title: "Databases & SQL Basics",
                    topics: [
                        {
                            topic_id: "csc_topic_004",
                            title: "Introduction to Databases",
                            description: "Relational database concepts, tables, records, fields, primary keys, and benefits over flat spreadsheets.",
                            duration: 880,
                            takeaways: [
                                "Explain relational database architecture: tables, records, and attributes.",
                                "Identify candidate, primary, and foreign keys in database schemas.",
                                "Understand the advantages of relational databases over flat files."
                            ]
                        },
                        {
                            topic_id: "csc_topic_005",
                            title: "SQL SELECT Queries",
                            description: "Syntax and usage of SQL SELECT statements, column aliasing, and retrieving complete or subset table rows.",
                            duration: 940,
                            takeaways: [
                                "Write basic SELECT statements retrieving all or specific columns from a table.",
                                "Use column aliasing (AS) to format output headers intuitively.",
                                "Retrieve unique row values using the DISTINCT keyword."
                            ]
                        },
                        {
                            topic_id: "csc_topic_006",
                            title: "Filtering and Sorting Data",
                            description: "Utilizing WHERE clauses, comparison operators, logical AND/OR, and sorting result sets using ORDER BY ASC/DESC.",
                            duration: 1020,
                            takeaways: [
                                "Filter table rows using WHERE clauses with comparison and pattern matching (LIKE).",
                                "Combine multiple filtering conditions using logical AND, OR, and NOT.",
                                "Sort queried result sets in ascending and descending order using ORDER BY."
                            ]
                        }
                    ]
                },
                {
                    chapter_id: "csc_ch_003",
                    chapter_title: "Cybersecurity & Digital Safety",
                    topics: [
                        {
                            topic_id: "csc_topic_007",
                            title: "Online Safety",
                            description: "Safe internet browsing habits, digital footprint awareness, privacy settings on social networks, and cyberbullying.",
                            duration: 860,
                            takeaways: [
                                "Identify personal information that must never be shared publicly online.",
                                "Understand how digital footprints are created and tracked across sites.",
                                "Recognize cyberbullying behaviors and follow appropriate reporting protocols."
                            ]
                        },
                        {
                            topic_id: "csc_topic_008",
                            title: "Passwords and Authentication",
                            description: "Password complexity requirements, entropy, multi-factor authentication (MFA/2FA), and password manager tools.",
                            duration: 910,
                            takeaways: [
                                "Generate high-entropy passphrases combining random words, numbers, and symbols.",
                                "Explain how multi-factor authentication (MFA) blocks credential stuffing attacks.",
                                "Understand password manager functions and avoid credential reuse across websites."
                            ]
                        },
                        {
                            topic_id: "csc_topic_009",
                            title: "Recognizing Online Threats",
                            description: "Identification of phishing emails, suspicious URLs, spyware, trojans, ransomware, and social engineering attacks.",
                            duration: 950,
                            takeaways: [
                                "Identify common phishing cues: urgent language, spoofed domains, and unsolicited attachments.",
                                "Distinguish viruses, spyware, worms, and ransomware attack vectors.",
                                "Follow safe download guidelines and keep security patches up to date."
                            ]
                        }
                    ]
                }
            ]
        },

        // =========================================================================
        // Subject 6: Physical Education
        // =========================================================================
        {
            subject_id: 6,
            subject_code: "pe",
            subject_name: "Physical Education",
            chapters: [
                {
                    chapter_id: "pe_ch_001",
                    chapter_title: "Athletics & Sprint Training",
                    topics: [
                        {
                            topic_id: "pe_topic_001",
                            title: "Sprint Techniques",
                            description: "Proper biomechanics of sprinting: posture, arm swing, knee lift, stride frequency, and foot strike positioning.",
                            duration: 840,
                            takeaways: [
                                "Maintain forward torso alignment and 90-degree elbow drive while sprinting.",
                                "Execute explosive knee lifts and dorsiflexed mid-foot strikes.",
                                "Avoid over-striding to maintain maximum velocity through the finish line."
                            ]
                        },
                        {
                            topic_id: "pe_topic_002",
                            title: "Starting and Acceleration",
                            description: "Three-point and block start setups, reaction time off the whistle, and transition from drive phase to upright stride.",
                            duration: 890,
                            takeaways: [
                                "Set up starting blocks with correct pedal distance and body weight distribution.",
                                "React promptly to the starting signal without false starting.",
                                "Maintain low body angles during the initial 15-meter acceleration drive phase."
                            ]
                        },
                        {
                            topic_id: "pe_topic_003",
                            title: "Endurance Training",
                            description: "Aerobic conditioning, pacing strategies for middle and long-distance running, and cardiovascular stamina.",
                            duration: 930,
                            takeaways: [
                                "Calculate aerobic target heart rate zones for steady-state training.",
                                "Apply consistent lap split pacing to avoid premature muscular fatigue.",
                                "Practice controlled rhythmic breathing coordinated with running strides."
                            ]
                        }
                    ]
                },
                {
                    chapter_id: "pe_ch_002",
                    chapter_title: "Badminton & Racket Sports",
                    topics: [
                        {
                            topic_id: "pe_topic_004",
                            title: "Racket Grip and Stance",
                            description: "Mastering forehand (shakehand) and backhand grips, ready stance at mid-court, and racket head positioning.",
                            duration: 860,
                            takeaways: [
                                "Hold the racket with relaxed V-grip for forehand and thumb bevel support for backhand.",
                                "Assume balanced athletic ready stance with knees slightly bent at court center.",
                                "Keep racket head elevated above waist level to intercept fast shuttlecock trajectories."
                            ]
                        },
                        {
                            topic_id: "pe_topic_005",
                            title: "Serving Techniques",
                            description: "Rules, trajectories, and wrist action for high singles serves, low doubles serves, and flick serves.",
                            duration: 910,
                            takeaways: [
                                "Execute legal below-waist underhand serves conforming to BWF regulations.",
                                "Deliver tight low serves skimming the net tape in doubles gameplay.",
                                "Hit deep, high clears to push opponents behind their singles baseline."
                            ]
                        },
                        {
                            topic_id: "pe_topic_006",
                            title: "Footwork and Court Movement",
                            description: "Chassé steps, scissor lunges, split-step recovery, and transitioning efficiently between all four corners.",
                            duration: 970,
                            takeaways: [
                                "Perform split-step timing just as opponent makes contact with the shuttlecock.",
                                "Execute chassé and cross-behind footwork across forecourt and rear court corners.",
                                "Lunge on the racket leg with proper knee alignment to absorb impact safely."
                            ]
                        }
                    ]
                },
                {
                    chapter_id: "pe_ch_003",
                    chapter_title: "Yoga & Flexibility Training",
                    topics: [
                        {
                            topic_id: "pe_topic_007",
                            title: "Basic Yoga Postures",
                            description: "Foundational standing and seated asanas: Tadasana, Vrikshasana, Bhujangasana, and Paschimottanasana alignment.",
                            duration: 880,
                            takeaways: [
                                "Align spine and engage core in mountain pose (Tadasana).",
                                "Improve balance and ankle strength in standing tree pose (Vrikshasana).",
                                "Promote spinal extension and chest opening in cobra pose (Bhujangasana)."
                            ]
                        },
                        {
                            topic_id: "pe_topic_008",
                            title: "Breathing Techniques",
                            description: "Pranayama practices including Anulom Vilom (alternate nostril) and Kapalabhati, focusing on mindfulness and lung volume.",
                            duration: 850,
                            takeaways: [
                                "Perform alternate nostril breathing (Anulom Vilom) to regulate autonomic nervous function.",
                                "Coordinate smooth inhalations and exhalations with physical movement sequences.",
                                "Utilize diaphragmatic breathing to enhance mental focus and alleviate stress."
                            ]
                        },
                        {
                            topic_id: "pe_topic_009",
                            title: "Flexibility Exercises",
                            description: "Static and dynamic stretching routines targeting hamstrings, hip flexors, shoulder girdle, and core mobility.",
                            duration: 920,
                            takeaways: [
                                "Perform dynamic leg swings and arm circles for pre-workout joint warm-up.",
                                "Hold static stretches for 20-30 seconds post-workout to increase muscular length.",
                                "Improve hip flexor and hamstring mobility to prevent sports-related injuries."
                            ]
                        }
                    ]
                }
            ]
        }
    ];

    // 4. Assemble documents array adhering strictly to $jsonSchema validator
    const documents = [];

    curriculumData.forEach((sub) => {
        sub.chapters.forEach((ch, chIdx) => {
            const chNum = chIdx + 1;
            ch.topics.forEach((top, topIdx) => {
                const topNum = topIdx + 1;
                const paddedCh = String(chNum).padStart(2, "0");
                const paddedTop = String(topNum).padStart(2, "0");

                const s3Prefix = `schools/1/branches/1/academic_years/1/classes/1/sections/1/subjects/${sub.subject_id}/chapters/${ch.chapter_id}/topics/${top.topic_id}`;

                // -------------------------------------------------------------
                // RESOURCE 1: VIDEO + TEACHER
                // Satisfies anyOf[0]: VIDEO + TEACHER (requires description, duration_seconds, storage_reference)
                // -------------------------------------------------------------
                const videoResourceId = `lr_${sub.subject_code}_ch${paddedCh}_top${paddedTop}_vid_01`;
                documents.push({
                    resource_id: videoResourceId,
                    school_id: NumberInt(1),
                    branch_id: NumberInt(1),
                    academic_year_id: NumberInt(1),
                    class_id: NumberInt(1),
                    section_id: NumberInt(1),
                    subject_id: NumberInt(sub.subject_id),
                    syllabus_version: NumberInt(1),
                    chapter_id: ch.chapter_id,
                    topic_id: top.topic_id,
                    resource_type: "VIDEO",
                    source_type: "TEACHER",
                    title: `${sub.subject_name}: ${top.title} - Video Lecture`,
                    description: top.description,
                    storage_reference: {
                        provider: "AWS_S3",
                        bucket: "thinkigen",
                        object_key: `${s3Prefix}/${videoResourceId}.mp4`
                    },
                    duration_seconds: top.duration,
                    key_takeaways: top.takeaways,
                    file_metadata: {
                        original_file_name: `${videoResourceId}.mp4`,
                        mime_type: "video/mp4",
                        file_size_bytes: NumberLong(top.duration * 185000)
                    },
                    status: "PUBLISHED",
                    created_at: now,
                    updated_at: now,
                    created_by: adminUserId,
                    updated_by: adminUserId
                });

                // -------------------------------------------------------------
                // RESOURCE 2: NOTE + TEACHER
                // Satisfies anyOf[1]: NOTE + TEACHER (requires storage_reference)
                // Satisfies index: uq_learning_resource_current_teacher_note (unique per topic)
                // -------------------------------------------------------------
                const teacherNoteResourceId = `lr_${sub.subject_code}_ch${paddedCh}_top${paddedTop}_note_teacher`;
                documents.push({
                    resource_id: teacherNoteResourceId,
                    school_id: NumberInt(1),
                    branch_id: NumberInt(1),
                    academic_year_id: NumberInt(1),
                    class_id: NumberInt(1),
                    section_id: NumberInt(1),
                    subject_id: NumberInt(sub.subject_id),
                    syllabus_version: NumberInt(1),
                    chapter_id: ch.chapter_id,
                    topic_id: top.topic_id,
                    resource_type: "NOTE",
                    source_type: "TEACHER",
                    title: `${sub.subject_name}: ${top.title} - Teacher Lecture Notes`,
                    description: `Official comprehensive teacher lecture notes, detailed reference definitions, and worked examples for ${top.title}.`,
                    storage_reference: {
                        provider: "AWS_S3",
                        bucket: "thinkigen",
                        object_key: `${s3Prefix}/${teacherNoteResourceId}.pdf`
                    },
                    duration_seconds: null,
                    key_takeaways: top.takeaways,
                    file_metadata: {
                        original_file_name: `${teacherNoteResourceId}.pdf`,
                        mime_type: "application/pdf",
                        file_size_bytes: NumberLong(2485000)
                    },
                    status: "PUBLISHED",
                    created_at: now,
                    updated_at: now,
                    created_by: adminUserId,
                    updated_by: adminUserId
                });

                // -------------------------------------------------------------
                // RESOURCE 3: NOTE + COMPASS
                // Satisfies anyOf[2]: NOTE + COMPASS (requires storage_reference)
                // Satisfies index: uq_learning_resource_current_compass_note (unique per topic)
                // -------------------------------------------------------------
                const compassNoteResourceId = `lr_${sub.subject_code}_ch${paddedCh}_top${paddedTop}_note_compass`;
                documents.push({
                    resource_id: compassNoteResourceId,
                    school_id: NumberInt(1),
                    branch_id: NumberInt(1),
                    academic_year_id: NumberInt(1),
                    class_id: NumberInt(1),
                    section_id: NumberInt(1),
                    subject_id: NumberInt(sub.subject_id),
                    syllabus_version: NumberInt(1),
                    chapter_id: ch.chapter_id,
                    topic_id: top.topic_id,
                    resource_type: "NOTE",
                    source_type: "COMPASS",
                    title: `${sub.subject_name}: ${top.title} - Compass AI Quick Revision Guide`,
                    description: `Curated Compass AI revision summary featuring key formulas, memory aids, and high-yield exam practice questions for ${top.title}.`,
                    storage_reference: {
                        provider: "AWS_S3",
                        bucket: "thinkigen",
                        object_key: `${s3Prefix}/${compassNoteResourceId}.pdf`
                    },
                    duration_seconds: null,
                    key_takeaways: top.takeaways,
                    file_metadata: {
                        original_file_name: `${compassNoteResourceId}.pdf`,
                        mime_type: "application/pdf",
                        file_size_bytes: NumberLong(1620000)
                    },
                    status: "PUBLISHED",
                    created_at: now,
                    updated_at: now,
                    created_by: NumberInt(1), // System/Compass bot user ID
                    updated_by: NumberInt(1)
                });
            });
        });
    });

    print(`Constructed ${documents.length} learning resource documents across subjects 1, 2, 4, 5, and 6.`);

    // 5. Clean existing documents ONLY for subjects 1, 2, 4, 5, 6 (ensures subject 3 is NEVER touched)
    const deleteFilter = {
        school_id: NumberInt(1),
        branch_id: NumberInt(1),
        academic_year_id: NumberInt(1),
        class_id: NumberInt(1),
        section_id: NumberInt(1),
        subject_id: { 
            $in: [NumberInt(1), NumberInt(2), NumberInt(4), NumberInt(5), NumberInt(6)],
            $ne: NumberInt(3) // Explicit isolation guard for Science
        }
    };

    const deleteResult = col.deleteMany(deleteFilter);
    print(`Idempotent cleanup: Removed ${deleteResult.deletedCount} existing documents for subjects 1, 2, 4, 5, 6.`);

    // 6. Insert documents with strict ordering and schema validation
    const insertResult = col.insertMany(documents, { ordered: true });
    print(`\n✓ SUCCESS: Successfully inserted ${insertResult.insertedCount} documents into '${targetCollectionName}'!\n`);

    // 7. Verification and Audit Report
    print("==============================================================================");
    print("VERIFICATION & AUDIT REPORT");
    print("==============================================================================");

    const subjectBreakdown = col.aggregate([
        { $match: { school_id: NumberInt(1), branch_id: NumberInt(1), class_id: NumberInt(1), section_id: NumberInt(1) } },
        {
            $group: {
                _id: { subject_id: "$subject_id", resource_type: "$resource_type", source_type: "$source_type" },
                count: { $sum: 1 }
            }
        },
        { $sort: { "_id.subject_id": 1, "_id.resource_type": 1, "_id.source_type": 1 } }
    ]).toArray();

    const subjectNames = {
        1: "English",
        2: "Mathematics",
        3: "Science (Preserved)",
        4: "Social Science",
        5: "Computer Science",
        6: "Physical Education"
    };

    print("\nTotal Active Resources in Collection by Subject and Type:");
    subjectBreakdown.forEach((item) => {
        const sName = subjectNames[item._id.subject_id] || "Subject " + item._id.subject_id;
        print(`  - Subject [${item._id.subject_id}] ${sName.padEnd(23)} | ${item._id.resource_type.padEnd(6)} | ${item._id.source_type.padEnd(8)} : ${item.count} docs`);
    });

    const finalScienceCount = col.countDocuments({
        school_id: { $in: [1, NumberInt(1)] },
        branch_id: { $in: [1, NumberInt(1)] },
        academic_year_id: { $in: [1, NumberInt(1)] },
        class_id: { $in: [1, NumberInt(1)] },
        section_id: { $in: [1, NumberInt(1)] },
        subject_id: { $in: [3, NumberInt(3)] }
    });

    const newSubjectsCount = col.countDocuments(deleteFilter);

    print(`\nSummary:`);
    print(`  - New Documents Added (Subjects 1, 2, 4, 5, 6): ${newSubjectsCount}`);
    print(`  - Science Documents Preserved (Subject 3)     : ${finalScienceCount} (strictly untouched)`);
    print(`  - Total Active Learning Resources in Scope    : ${newSubjectsCount + finalScienceCount}`);
    print("==============================================================================\n");
})();
