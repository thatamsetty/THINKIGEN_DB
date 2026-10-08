/*
    Collection: career_industries & career_paths
    Purpose: Career Explorer domain storing industry categories, key sectors, skills used, and detailed career paths matching UI.
*/

// ============================================================
// 1. CREATE COLLECTION: career_industries
// ============================================================
if (!db.getCollectionNames().includes("career_industries")) {
    db.createCollection("career_industries", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "industry_id",
                    "industry_name",
                    "summary",
                    "about_industry",
                    "why_explore",
                    "key_sectors",
                    "skills_used",
                    "relevant_subjects",
                    "related_industries",
                    "career_path_ids"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    industry_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    industry_name: { bsonType: "string", minLength: 1, maxLength: 150 },
                    summary: { bsonType: "string" },
                    about_industry: { bsonType: "string" },
                    why_explore: {
                        bsonType: "array",
                        items: {
                            bsonType: "object",
                            required: ["title", "description"],
                            properties: {
                                title: { bsonType: "string" },
                                description: { bsonType: "string" }
                            }
                        }
                    },
                    key_sectors: {
                        bsonType: "array",
                        items: {
                            bsonType: "object",
                            required: ["sector_id", "title", "description"],
                            properties: {
                                sector_id: { bsonType: "string" },
                                title: { bsonType: "string" },
                                description: { bsonType: "string" }
                            }
                        }
                    },
                    skills_used: {
                        bsonType: "object",
                        required: ["technical", "transferable"],
                        properties: {
                            technical: { bsonType: "array", items: { bsonType: "string" } },
                            transferable: { bsonType: "array", items: { bsonType: "string" } }
                        }
                    },
                    relevant_subjects: { bsonType: "array", items: { bsonType: "string" } },
                    related_industries: {
                        bsonType: "array",
                        items: {
                            bsonType: "object",
                            required: ["industry_id", "industry_name"],
                            properties: {
                                industry_id: { bsonType: "string" },
                                industry_name: { bsonType: "string" }
                            }
                        }
                    },
                    career_path_ids: { bsonType: "array", items: { bsonType: "string" } },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
}

if (!db.career_industries.getIndexes().some(idx => idx.name === "uq_career_industry_id")) {
    db.career_industries.createIndex(
        { industry_id: 1 },
        { unique: true, name: "uq_career_industry_id" }
    );
}

// ============================================================
// 2. CREATE COLLECTION: career_paths
// ============================================================
if (!db.getCollectionNames().includes("career_paths")) {
    db.createCollection("career_paths", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "career_id",
                    "industry_id",
                    "industry_name",
                    "category",
                    "title",
                    "subtitle",
                    "about_role",
                    "what_it_involves",
                    "where_it_can_lead",
                    "skills_used",
                    "relevant_subjects"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    career_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    industry_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    industry_name: { bsonType: "string", minLength: 1, maxLength: 150 },
                    category: { bsonType: "string", minLength: 1, maxLength: 100 },
                    title: { bsonType: "string", minLength: 1, maxLength: 150 },
                    subtitle: { bsonType: "string" },
                    about_role: { bsonType: "string" },
                    what_it_involves: {
                        bsonType: "array",
                        items: { bsonType: "string" }
                    },
                    where_it_can_lead: {
                        bsonType: "array",
                        items: { bsonType: "string" }
                    },
                    skills_used: {
                        bsonType: "object",
                        required: ["technical", "transferable"],
                        properties: {
                            technical: { bsonType: "array", items: { bsonType: "string" } },
                            transferable: { bsonType: "array", items: { bsonType: "string" } }
                        }
                    },
                    relevant_subjects: { bsonType: "array", items: { bsonType: "string" } },
                    match_tag: { bsonType: ["string", "null"] },
                    connected_subjects_tag: { bsonType: ["string", "null"] },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
}

if (!db.career_paths.getIndexes().some(idx => idx.name === "uq_career_path_id")) {
    db.career_paths.createIndex(
        { career_id: 1 },
        { unique: true, name: "uq_career_path_id" }
    );
}

if (!db.career_paths.getIndexes().some(idx => idx.name === "ix_career_path_industry")) {
    db.career_paths.createIndex(
        { industry_id: 1, title: 1 },
        { name: "ix_career_path_industry" }
    );
}

// ============================================================
// 3. SEED INITIAL DATA: Technology & Analytics Industry
// ============================================================
db.career_industries.updateOne(
    { industry_id: "ind_technology_analytics" },
    {
        $set: {
            industry_name: "Technology & Analytics",
            summary: "Explore the landscape of tech, from software engineering to data science and cybersecurity. This industry is the digital nervous system of the modern world, translating complex problems into scalable solutions and driving innovation across every sector.",
            about_industry: "Software Engineers apply principles of computer science and mathematical analysis to the design, development, testing, and evaluation of the software and systems that make computers work. They create everything from business applications and operating systems to network control systems and social networks.",
            why_explore: [
                {
                    title: "Matches your interest in Problem Solving",
                    description: "Tech careers rely heavily on breaking down complex challenges into logical, step-by-step solutions."
                },
                {
                    title: "Strong alignment with Mathematics",
                    description: "Your aptitude for math provides a solid foundation for algorithms, data modeling, and cryptography."
                }
            ],
            key_sectors: [
                {
                    sector_id: "sec_sw_dev",
                    title: "Software Development",
                    description: "Building applications, operating systems, and platforms that power digital experiences."
                },
                {
                    sector_id: "sec_data_ai",
                    title: "Data & AI",
                    description: "Extracting insights from vast datasets and training intelligent machine learning models."
                },
                {
                    sector_id: "sec_cybersecurity",
                    title: "Cybersecurity",
                    description: "Protecting networks, devices, and data from unauthorized access or criminal use."
                },
                {
                    sector_id: "sec_cloud",
                    title: "Cloud Computing",
                    description: "Managing distributed infrastructure for scalable cloud services."
                }
            ],
            skills_used: {
                technical: ["Programming", "Mathematics", "Systems Design"],
                transferable: ["Analytical thinking", "Communication", "Problem solving", "Teamwork"]
            },
            relevant_subjects: ["Computer Science", "Mathematics", "Physics"],
            related_industries: [
                { industry_id: "ind_engineering", industry_name: "Engineering" },
                { industry_id: "ind_data_science", industry_name: "Data Science" }
            ],
            career_path_ids: ["car_sw_engineer", "car_ml_engineer", "car_robotics_engineer"],
            created_at: new Date("2026-09-16T16:30:00Z"),
            updated_at: new Date("2026-09-16T16:30:00Z")
        }
    },
    { upsert: true }
);

// Seed Career Path: Software Engineer
db.career_paths.updateOne(
    { career_id: "car_sw_engineer" },
    {
        $set: {
            industry_id: "ind_technology_analytics",
            industry_name: "Technology & Analytics",
            category: "Engineering",
            title: "Software Engineer",
            subtitle: "Designs, develops and maintains software applications and systems.",
            about_role: "Software Engineers apply principles of computer science and mathematical analysis to the design, development, testing, and evaluation of the software and systems that make computers work. They create everything from business applications and operating systems to network control systems and social networks.",
            what_it_involves: [
                "Writing clean, maintainable, and efficient code.",
                "Testing software and fixing bugs to ensure reliability.",
                "Collaborating with cross-functional teams to design new features.",
                "Solving complex technical problems to improve system performance."
            ],
            where_it_can_lead: [
                "Data Scientist",
                "Product Engineer",
                "AI Engineer",
                "Cybersecurity Analyst"
            ],
            skills_used: {
                technical: ["Programming", "Mathematics", "Systems Design"],
                transferable: ["Analytical thinking", "Communication", "Problem solving", "Teamwork"]
            },
            relevant_subjects: ["Computer Science", "Mathematics", "Physics"],
            match_tag: "Connects with your interest in technology, problem solving and Computer Science.",
            connected_subjects_tag: "Connected to Mathematics + Physics",
            created_at: new Date("2026-09-16T16:30:00Z"),
            updated_at: new Date("2026-09-16T16:30:00Z")
        }
    },
    { upsert: true }
);

// Seed Career Path: Machine Learning Engineer
db.career_paths.updateOne(
    { career_id: "car_ml_engineer" },
    {
        $set: {
            industry_id: "ind_technology_analytics",
            industry_name: "Technology & Analytics",
            category: "Technology",
            title: "Machine Learning Engineer",
            subtitle: "Develops algorithms that allow computers to learn from data.",
            about_role: "Machine Learning Engineers combine data science and software engineering to research, build, and deploy self-learning artificial intelligence models into production systems.",
            what_it_involves: [
                "Designing and training machine learning and deep learning neural networks.",
                "Cleaning, structuring, and optimizing large datasets for training.",
                "Deploying AI models to cloud APIs and monitoring performance metrics.",
                "Evaluating accuracy, precision, and bias in predictive models."
            ],
            where_it_can_lead: [
                "AI Research Scientist",
                "Chief Data Officer",
                "NLP Specialist",
                "Autonomous Systems Architect"
            ],
            skills_used: {
                technical: ["Coding", "Math", "Research"],
                transferable: ["Analytical thinking", "Problem solving"]
            },
            relevant_subjects: ["Computer Science", "Mathematics", "Physics"],
            match_tag: "Matches your interests in AI & Tech",
            connected_subjects_tag: "Connected to Mathematics + Physics",
            created_at: new Date("2026-09-16T16:30:00Z"),
            updated_at: new Date("2026-09-16T16:30:00Z")
        }
    },
    { upsert: true }
);

// Seed Career Path: Robotics Engineer
db.career_paths.updateOne(
    { career_id: "car_robotics_engineer" },
    {
        $set: {
            industry_id: "ind_technology_analytics",
            industry_name: "Technology & Analytics",
            category: "Engineering",
            title: "Robotics Engineer",
            subtitle: "Designs and builds robots and robotic systems.",
            about_role: "Robotics Engineers create mechanical systems and autonomous software that perform tasks safely, efficiently, and intelligently across manufacturing, healthcare, and exploration.",
            what_it_involves: [
                "Designing mechanical structures, actuators, and motor controls.",
                "Writing embedded software for real-time sensor processing and navigation.",
                "Testing robotic arms, drones, and autonomous rovers under field conditions.",
                "Integrating microcontrollers, sensors, and computer vision cameras."
            ],
            where_it_can_lead: [
                "Automation Architect",
                "Aerospace Systems Engineer",
                "Surgical Robotics Lead"
            ],
            skills_used: {
                technical: ["Mechanics", "Electronics", "Programming"],
                transferable: ["Problem solving", "Teamwork"]
            },
            relevant_subjects: ["Physics", "Mathematics", "Computer Science"],
            match_tag: "Connected to Mathematics + Physics",
            connected_subjects_tag: "Connected to Mathematics + Physics",
            created_at: new Date("2026-09-16T16:30:00Z"),
            updated_at: new Date("2026-09-16T16:30:00Z")
        }
    },
    { upsert: true }
);
