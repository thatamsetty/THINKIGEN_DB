/*
    ================================================================================
    THINKIGEN LIBRARY MODULE — REALISTIC MOCK DATA SEED SCRIPT (200 BOOK CATALOG)
    ================================================================================
    File: database/seeds/005_library_mock_data.sql
    Target Tables:
      1. library_schema.library_book        (200 catalog titles across 4 branches)
      2. library_schema.library_book_copy   (600 physical copies across 7 statuses)
      3. library_schema.library_book_borrow (Rich circulation transactions)

    Integrity & Architecture:
      - 100% multi-tenant composite scope consistency:
        (school_id, branch_id, book_id, book_copy_id) matches exact student placement
        (school_id, branch_id, academic_year_id, class_id, section_id, student_id).
      - Covers all 7 copy statuses:
        AVAILABLE, BORROWED, OVERDUE, LOST, DAMAGED, MAINTENANCE, RETIRED.
      - Covers all 4 borrow statuses:
        ACTIVE, OVERDUE, RETURNED, LOST.
      - Enforces zero duplicate active loans on any physical copy (UX_library_book_borrow_active_copy).
      - Available inventory counters (available_copies) dynamically synchronized
        to physical copies with copy_status = 'AVAILABLE'.
      - Idempotent and safely wrapped in a database transaction with XACT_ABORT.
    ================================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRANSACTION;
BEGIN TRY
    PRINT N'======================================================================';
    PRINT N'1. CLEARING EXISTING LIBRARY DATA (CHILD TO PARENT)';
    PRINT N'======================================================================';

    DELETE FROM library_schema.library_book_borrow;
    DELETE FROM library_schema.library_book_copy;
    DELETE FROM library_schema.library_book;

    PRINT N'Cleared existing records from library_schema tables.';

    PRINT N'======================================================================';
    PRINT N'2. INSERTING 200 CATALOG BOOK TITLES ACROSS 4 BRANCHES';
    PRINT N'======================================================================';

    SET IDENTITY_INSERT library_schema.library_book ON;

    INSERT INTO library_schema.library_book
    (
        book_id, school_id, branch_id, title, author, subject, category,
        language, edition, description, total_copies, available_copies,
        is_active, created_at, created_by, updated_at
    )
    VALUES
    (1, 1, 1, N'Advanced Pure Mathematics: Algebra & Calculus', N'Dr. R. K. Sharma', N'Mathematics', N'Textbook', N'English', N'4th Edition', N'Comprehensive reference for senior secondary mathematics curriculum.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (2, 1, 1, N'Concepts of Modern Physics: Volume I', N'Prof. M. N. Sen', N'Physics', N'Science', N'English', N'2nd Edition', N'Mechanics, thermodynamics, wave theory, and classical electromagnetism.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (3, 1, 1, N'Inorganic & Organic Chemistry Laboratory Guide', N'Dr. Ananya Roy', N'Chemistry', N'Science', N'English', N'3rd Edition', N'Practical manual with reaction stoichiometry and laboratory safety procedures.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (4, 1, 1, N'The Oxford Anthology of English Literature', N'Margaret H. Thomas', N'English', N'Literature', N'English', N'Revised 5th', N'Selected prose, dramatic monologues, and analytical literary essays.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (5, 1, 1, N'Medieval and Modern Indian History & Governance', N'V. K. Agnihotri', N'Social Science', N'History', N'English', N'2nd Edition', N'Comprehensive overview of political systems and cultural heritage.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (6, 1, 1, N'Computer Systems & Python Data Structures', N'S. Sundaram', N'Computer Science', N'Technology', N'English', N'1st Edition', N'Foundational algorithms, object-oriented principles, and data management.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (7, 1, 1, N'Linear Algebra and Vector Calculus', N'Erwin Kreyszig', N'Mathematics', N'Textbook', N'English', N'10th Edition', N'Vector spaces, linear transformations, matrices, and eigenvalues.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (8, 1, 1, N'Discrete Mathematics with Graph Theory', N'Kenneth H. Rosen', N'Mathematics', N'Textbook', N'English', N'8th Edition', N'Set theory, combinatorics, recurrence relations, and graph algorithms.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (9, 1, 1, N'Differential Equations and Boundary Value Problems', N'C. Henry Edwards', N'Mathematics', N'Textbook', N'English', N'5th Edition', N'First-order equations, linear systems, and Fourier transform techniques.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (10, 1, 1, N'Introduction to Probability and Statistics', N'Sheldon M. Ross', N'Mathematics', N'Textbook', N'English', N'6th Edition', N'Probability distributions, hypothesis testing, and statistical estimation.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (11, 1, 1, N'Fundamentals of Physics: Mechanics & Relativity', N'David Halliday & Robert Resnick', N'Physics', N'Science', N'English', N'11th Edition', N'Classical Newtonian mechanics, fluid dynamics, and special relativity.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (12, 1, 1, N'Electromagnetism and Circuit Theory', N'David J. Griffiths', N'Physics', N'Science', N'English', N'4th Edition', N'Electrostatics, magnetostatics, Maxwell equations, and electromagnetic waves.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (13, 1, 1, N'Optics and Optical Instruments', N'Eugene Hecht', N'Physics', N'Science', N'English', N'5th Edition', N'Geometric optics, diffraction grating, interference, and laser physics.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (14, 1, 1, N'Thermodynamics, Kinetic Theory and Statistical Mechanics', N'Francis W. Sears', N'Physics', N'Science', N'English', N'3rd Edition', N'Laws of thermodynamics, entropy, and statistical particle ensembles.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (15, 1, 1, N'Quantum Physics for Beginners', N'Alastair I. M. Rae', N'Physics', N'Science', N'English', N'2nd Edition', N'Wave-particle duality, Schrodinger equation, and atomic structure.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (16, 1, 1, N'Astrophysics and Planetary Systems', N'Bradley W. Carroll', N'Physics', N'Science', N'English', N'2nd Edition', N'Stellar evolution, orbital mechanics, and cosmic nucleosynthesis.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (17, 1, 1, N'Experimental Physics Laboratory Manual', N'R. K. Shukla', N'Physics', N'Practical', N'English', N'1st Edition', N'Hands-on experiments in optics, electricity, and harmonic oscillation.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (18, 1, 1, N'Solid State Electronics and Semiconductors', N'Ben G. Streetman', N'Physics', N'Technology', N'English', N'7th Edition', N'Semiconductor crystal lattices, p-n junctions, and transistors.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (19, 1, 1, N'Physical Chemistry: Principles and Applications', N'Peter Atkins & Julio de Paula', N'Chemistry', N'Science', N'English', N'11th Edition', N'Thermodynamics, quantum chemistry, and chemical kinetics.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (20, 1, 1, N'Advanced Organic Reaction Mechanisms', N'Jerry March', N'Chemistry', N'Science', N'English', N'7th Edition', N'Electrophilic substitution, nucleophilic addition, and stereochemistry.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (21, 1, 1, N'Concise Inorganic Chemistry', N'J. D. Lee', N'Chemistry', N'Science', N'English', N'5th Edition', N'Periodic table trends, coordination compounds, and bonding theories.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (22, 1, 1, N'Analytical Chemistry and Instrumental Techniques', N'Douglas A. Skoog', N'Chemistry', N'Science', N'English', N'9th Edition', N'Spectrophotometry, chromatography, and electrochemical analysis.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (23, 1, 1, N'Biochemistry: Molecular Basis of Life', N'Trudy McKee & James R. McKee', N'Chemistry', N'Science', N'English', N'6th Edition', N'Enzyme kinetics, metabolic pathways, and nucleic acid synthesis.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (24, 1, 1, N'Environmental Chemistry and Toxicology', N'Stanley E. Manahan', N'Chemistry', N'Science', N'English', N'10th Edition', N'Atmospheric chemistry, water pollution, and ecological chemical cycles.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (25, 1, 1, N'Practical Organic Chemistry Techniques', N'A. I. Vogel', N'Chemistry', N'Practical', N'English', N'5th Edition', N'Laboratory synthesis, purification, and organic compound characterization.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (26, 1, 1, N'Campbell Biology: Life on Earth', N'Lisa A. Urry & Michael L. Cain', N'Biology', N'Science', N'English', N'12th Edition', N'Cell biology, genetics, evolutionary ecology, and plant-animal physiology.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (27, 1, 1, N'Genetics: Analysis of Genes and Genomes', N'Daniel L. Hartl', N'Biology', N'Science', N'English', N'9th Edition', N'Mendelian inheritance, chromosome mapping, and CRISPR technology.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (28, 1, 1, N'Microbiology: Principles and Explorations', N'Jacquelyn G. Black', N'Biology', N'Science', N'English', N'10th Edition', N'Bacterial structures, viral replication, and immunological host defense.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (29, 1, 1, N'Plant Anatomy and Physiology', N'Lincoln Taiz & Eduardo Zeiger', N'Biology', N'Science', N'English', N'6th Edition', N'Photosynthesis, transpiration, mineral nutrition, and plant hormones.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (30, 1, 1, N'Human Anatomy and Physiology', N'Elaine N. Marieb', N'Biology', N'Science', N'English', N'11th Edition', N'Cardiovascular, nervous, respiratory, and endocrine organ systems.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (31, 1, 1, N'Ecology: Concepts and Applications', N'Manuel C. Molles', N'Biology', N'Science', N'English', N'8th Edition', N'Population ecology, biomes, nutrient cycling, and conservation biology.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (32, 1, 1, N'Zoology: Animal Diversity and Morphology', N'Stephen A. Miller', N'Biology', N'Science', N'English', N'10th Edition', N'Invertebrate and vertebrate evolution, taxonomy, and comparative anatomy.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (33, 1, 1, N'Introduction to Algorithms and Complexity', N'Thomas H. Cormen', N'Computer Science', N'Technology', N'English', N'3rd Edition', N'Sorting, search trees, dynamic programming, and greedy algorithms.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (34, 1, 1, N'Database System Concepts', N'Abraham Silberschatz & Henry F. Korth', N'Computer Science', N'Technology', N'English', N'7th Edition', N'Relational database schema design, SQL querying, and transaction ACID rules.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (35, 1, 1, N'Computer Networks: A Systems Approach', N'Larry L. Peterson', N'Computer Science', N'Technology', N'English', N'5th Edition', N'TCP/IP architecture, socket programming, routing, and network security.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (36, 1, 1, N'Operating System Principles', N'Peter B. Galvin & Greg Gagne', N'Computer Science', N'Technology', N'English', N'9th Edition', N'Process scheduling, thread concurrency, virtual memory, and file systems.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (37, 1, 1, N'Web Development with HTML5, CSS3, and JavaScript', N'Robin Nixon', N'Computer Science', N'Technology', N'English', N'6th Edition', N'Modern responsive web architecture, DOM manipulation, and asynchronous APIs.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (38, 1, 1, N'Artificial Intelligence: A Modern Approach', N'Stuart Russell & Peter Norvig', N'Computer Science', N'Technology', N'English', N'4th Edition', N'Heuristic search, probabilistic inference, neural networks, and reinforcement learning.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (39, 1, 1, N'Cybersecurity Fundamentals and Cryptography', N'William Stallings', N'Computer Science', N'Technology', N'English', N'7th Edition', N'Symmetric encryption, public key infrastructure, and firewall architectures.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (40, 1, 1, N'Data Science and Machine Learning with Python', N'Jake VanderPlas', N'Computer Science', N'Technology', N'English', N'2nd Edition', N'Pandas, NumPy, Scikit-Learn pipelines, and exploratory data visualization.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (41, 1, 1, N'World History: From Civilization to Modernity', N'William J. Duiker', N'Social Science', N'History', N'English', N'9th Edition', N'Global historical transitions, revolutions, and world conflicts.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (42, 1, 1, N'Indian Polity and Constitutional Framework', N'M. Laxmikanth', N'Social Science', N'Civics', N'English', N'6th Edition', N'Parliamentary structure, constitutional amendments, and fundamental duties.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (43, 1, 1, N'Principles of Microeconomics', N'N. Gregory Mankiw', N'Economics', N'Commerce', N'English', N'9th Edition', N'Supply and demand, market structures, elasticity, and consumer choice theory.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (44, 1, 1, N'Principles of Macroeconomics', N'N. Gregory Mankiw', N'Economics', N'Commerce', N'English', N'9th Edition', N'National income, inflation indices, monetary policies, and international trade.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (45, 1, 1, N'Financial Accounting and Balance Sheet Analysis', N'P. C. Tulsian', N'Commerce', N'Commerce', N'English', N'5th Edition', N'Ledger posting, trail balance reconciliation, and corporate final accounts.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (46, 1, 1, N'Business Studies: Principles and Practice', N'C. B. Gupta', N'Business Studies', N'Commerce', N'English', N'4th Edition', N'Strategic planning, personnel management, marketing mix, and business ethics.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (47, 1, 1, N'Sociology: Understanding Human Society', N'Anthony Giddens', N'Sociology', N'Social Science', N'English', N'8th Edition', N'Social structures, stratification, cultural globalization, and deviance.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (48, 1, 1, N'Psychology: The Science of Mind and Behavior', N'Richard Gross', N'Psychology', N'Social Science', N'English', N'7th Edition', N'Cognitive psychology, developmental stages, learning theory, and personality.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (49, 1, 1, N'Shakespeare: Selected Comedies and Tragedies', N'William Shakespeare', N'English', N'Literature', N'English', N'Annotated Ed.', N'Critical annotated texts of Twelfth Night, Macbeth, and Julius Caesar.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (50, 1, 1, N'Complete English Grammar and Composition', N'John Eastwood', N'English', N'Reference', N'English', N'Revised Ed.', N'Systematic grammar rules, sentence diagrams, idioms, and formal composition.', 3, 0, 1, '2026-06-01 09:00:00', 2, '2026-06-01 09:00:00'),
    (51, 1, 2, N'Applied Mathematics for Secondary Schools', N'H. K. Dass', N'Mathematics', N'Textbook', N'English', N'3rd Edition', N'Algebraic methods, coordinate geometry, and statistics.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (52, 1, 2, N'Introductory Number Theory', N'David M. Burton', N'Mathematics', N'Textbook', N'English', N'7th Edition', N'Prime distribution, congruences, Fermat''s little theorem, and cryptography.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (53, 1, 2, N'Trigonometry and Analytical Geometry', N'S. L. Loney', N'Mathematics', N'Textbook', N'English', N'Classic Ed.', N'Foundations of plane trigonometry and Cartesian coordinates.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (54, 1, 2, N'College Algebra and Polynomial Equations', N'James Stewart', N'Mathematics', N'Textbook', N'English', N'7th Edition', N'Functions, rational graphs, logarithmic identities, and matrix solvers.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (55, 1, 2, N'Elementary Real Analysis', N'Brian S. Thomson', N'Mathematics', N'Textbook', N'English', N'2nd Edition', N'Real number topology, sequences, continuous functions, and Riemann integration.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (56, 1, 2, N'University Physics: Waves and Acoustics', N'Hugh D. Young', N'Physics', N'Science', N'English', N'14th Edition', N'Oscillatory motion, acoustic resonance, Doppler effect, and seismic waves.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (57, 1, 2, N'Modern Atomic and Nuclear Physics', N'Fujia Yang', N'Physics', N'Science', N'English', N'3rd Edition', N'Rutherford scattering, nuclear fission, radioactive decay, and reactors.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (58, 1, 2, N'Optics in Engineering and Modern Technology', N'Miles V. Klein', N'Physics', N'Technology', N'English', N'2nd Edition', N'Fiber optics, lasers, holography, and optical data transmission.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (59, 1, 2, N'General Chemistry: Principles and Modern Applications', N'Ralph H. Petrucci', N'Chemistry', N'Science', N'English', N'11th Edition', N'Atomic theory, molecular geometry, gas laws, and solution chemistry.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (60, 1, 2, N'Polymer Chemistry and Material Science', N'Malcolm P. Stevens', N'Chemistry', N'Science', N'English', N'3rd Edition', N'Synthetic polymers, polymerization kinetics, and biodegradable materials.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (61, 1, 2, N'Biophysical Chemistry: Techniques and Applications', N'Alan Cooper', N'Chemistry', N'Science', N'English', N'2nd Edition', N'Spectroscopy of proteins, thermodynamics of folding, and membrane kinetics.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (62, 1, 2, N'General Botany and Plant Morphology', N'Peter H. Raven', N'Biology', N'Science', N'English', N'8th Edition', N'Vascular plant anatomy, gymnosperms, angiosperms, and bryophytes.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (63, 1, 2, N'Animal Physiology: Adaptation and Environment', N'Knut Schmidt-Nielsen', N'Biology', N'Science', N'English', N'5th Edition', N'Osmoregulation, respiration, excretion, and metabolic thermal adaptation.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (64, 1, 2, N'Evolutionary Biology and Speciation', N'Douglas J. Futuyma', N'Biology', N'Science', N'English', N'4th Edition', N'Natural selection, phylogenetics, genetic drift, and fossil records.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (65, 1, 2, N'Immunology and Serology Fundamentals', N'Thomas J. Kindt', N'Biology', N'Science', N'English', N'6th Edition', N'Antibody diversity, cellular immunity, allergies, and vaccine science.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (66, 1, 2, N'Object-Oriented Programming with C++', N'E. Balagurusamy', N'Computer Science', N'Technology', N'English', N'8th Edition', N'Encapsulation, inheritance, polymorphism, templates, and exception handling.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (67, 1, 2, N'Java: The Complete Reference', N'Herbert Schildt', N'Computer Science', N'Technology', N'English', N'12th Edition', N'Java core runtime, multithreading, collections framework, and lambda streams.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (68, 1, 2, N'Software Engineering: A Practitioner''s Approach', N'Roger S. Pressman', N'Computer Science', N'Technology', N'English', N'9th Edition', N'Agile methodologies, UML modeling, software testing, and DevOps.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (69, 1, 2, N'Cloud Computing and Distributed Systems', N'Rajkumar Buyya', N'Computer Science', N'Technology', N'English', N'1st Edition', N'Virtualization, infrastructure as a service, microservices, and containerization.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (70, 1, 2, N'Digital Logic Design and Computer Architecture', N'M. Morris Mano', N'Computer Science', N'Technology', N'English', N'5th Edition', N'Boolean algebra, combinational circuits, flip-flops, and CPU registers.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (71, 1, 2, N'World Geography: Physical and Human Landscape', N'Savindra Singh', N'Social Science', N'Geography', N'English', N'4th Edition', N'Geomorphology, climatology, oceanography, and demographic distributions.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (72, 1, 2, N'Contemporary World Politics and Global Affairs', N'Andrew Heywood', N'Social Science', N'Political Science', N'English', N'5th Edition', N'International relations, global governance, diplomacy, and trade blocs.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (73, 1, 2, N'Macroeconomic Policy and Fiscal Management', N'Olivier Blanchard', N'Economics', N'Commerce', N'English', N'8th Edition', N'Inflation targeting, public debt, sovereign monetary policy, and exchange rates.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (74, 1, 2, N'Cost and Management Accounting', N'M. N. Arora', N'Commerce', N'Commerce', N'English', N'12th Edition', N'Marginal costing, budgetary controls, variance analysis, and standard cost.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (75, 1, 2, N'Marketing Management: Strategic Perspectives', N'Philip Kotler & Kevin Keller', N'Business Studies', N'Commerce', N'English', N'15th Edition', N'Brand equity, consumer behavior, market segmentation, and digital marketing.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (76, 1, 2, N'Human Resource Management and Organizational Behavior', N'Gary Dessler', N'Business Studies', N'Commerce', N'English', N'16th Edition', N'Recruitment strategies, performance appraisal, labor laws, and workplace motivation.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (77, 1, 2, N'Indian Heritage and Culture', N'Nitin Singhania', N'Social Science', N'History', N'English', N'3rd Edition', N'Architecture, classical music, dance forms, painting traditions, and literature.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (78, 1, 2, N'Anthology of Modern Indian Poetry', N'A. K. Ramanujan', N'English', N'Literature', N'English', N'Collected Ed.', N'Selected verses by major post-independence Indian English poets.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (79, 1, 2, N'Public Administration: Theories and Concepts', N'Mohit Bhattacharya', N'Social Science', N'Civics', N'English', N'5th Edition', N'Bureaucratic models, administrative accountability, and citizen charters.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (80, 1, 2, N'Introduction to Logic and Critical Thinking', N'Irving M. Copi', N'Philosophy', N'Humanities', N'English', N'14th Edition', N'Categorical syllogisms, propositional logic, and fallacy detection.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (81, 1, 2, N'Geotechnical Engineering and Soil Mechanics', N'B. C. Punmia', N'Civil Engineering', N'Technology', N'English', N'4th Edition', N'Soil compaction, shear strength, foundation stability, and earth pressure.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (82, 1, 2, N'Fluid Mechanics and Hydraulic Machinery', N'R. K. Bansal', N'Mechanical Engineering', N'Technology', N'English', N'10th Edition', N'Fluid statics, Bernoulli theorem, laminar flow, and centrifugal pumps.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (83, 1, 2, N'Basic Electrical and Electronics Engineering', N'B. L. Theraja', N'Electrical Engineering', N'Technology', N'English', N'Revised Ed.', N'AC/DC circuits, transformers, induction motors, and semiconductor diodes.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (84, 1, 2, N'Linear Systems and Signal Processing', N'B. P. Lathi', N'Computer Science', N'Technology', N'English', N'3rd Edition', N'Fourier series, Laplace transforms, Z-transforms, and digital filter design.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (85, 1, 2, N'Mobile Application Development with Android', N'Bill Phillips', N'Computer Science', N'Technology', N'English', N'4th Edition', N'Activity lifecycle, SQLite integration, fragments, and material design.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (86, 1, 2, N'Renewable Energy and Clean Technology', N'John Twidell', N'Science', N'Environmental', N'English', N'3rd Edition', N'Solar photovoltaic, wind turbine engineering, biomass, and hydro energy.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (87, 1, 2, N'Forestry, Wildlife and Biodiversity Conservation', N'Dr. H. S. Singh', N'Biology', N'Science', N'English', N'2nd Edition', N'Endangered species preservation, national parks, and biosphere reserves.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (88, 1, 2, N'Modern Sanskrit Grammar and Composition', N'M. R. Kale', N'Sanskrit', N'Language', N'Sanskrit', N'Classic Ed.', N'Declensions, conjugations, Sandhi rules, and Sanskrit syntax structures.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (89, 1, 2, N'Hindi Sahitya Ka Itihas', N'Ramchandra Shukla', N'Hindi', N'Literature', N'Hindi', N'Standard Ed.', N'Historical development of Hindi literature from Adikal to Adhunik kal.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (90, 1, 2, N'French Grammar in Context', N'Margaret Jubb', N'French', N'Language', N'French', N'4th Edition', N'Grammar analysis, conjugation tables, and conversational dialogues in French.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (91, 1, 2, N'Children''s World Encyclopedia', N'DK Publishing', N'General Knowledge', N'Reference', N'English', N'Illustrated Ed.', N'Comprehensive visual encyclopedia covering earth, space, animals, and science.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (92, 1, 2, N'Universal Atlas of the World', N'National Geographic', N'Social Science', N'Geography', N'English', N'11th Edition', N'High-precision physical, political, and thematic continental world maps.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (93, 1, 2, N'Great Inventions That Changed Civilization', N'Trevor I. Williams', N'Science', N'History', N'English', N'2nd Edition', N'Printing press, steam engine, electricity, antibiotics, and internet history.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (94, 1, 2, N'Biographies of Nobel Laureates in Science', N'George Gamow', N'Science', N'Biography', N'English', N'Collected Ed.', N'Inspiring life chronicles of Einstein, Curie, Bohr, and Feynman.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (95, 1, 2, N'Mental Ability and Logical Reasoning Guide', N'R. S. Aggarwal', N'Mathematics', N'Aptitude', N'English', N'Revised Ed.', N'Number series, analogy, verbal logic, and spatial reasoning problem sets.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (96, 1, 2, N'General Studies for Competitive Examinations', N'McGraw Hill Editorial', N'General Knowledge', N'Reference', N'English', N'2026 Edition', N'Comprehensive manual for NTSE, Olympiad, and civil services foundation.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (97, 1, 2, N'The Story of My Experiments with Truth', N'Mahatma Gandhi', N'Social Science', N'Autobiography', N'English', N'Standard Ed.', N'Autobiographical account of Mahatma Gandhi''s moral philosophy and Satyagraha.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (98, 1, 2, N'Wings of Fire: An Autobiography', N'Dr. A. P. J. Abdul Kalam', N'Science', N'Autobiography', N'English', N'1st Edition', N'Inspirational journey from Rameshwaram to leading India''s space program.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (99, 1, 2, N'Discovery of India', N'Jawaharlal Nehru', N'Social Science', N'History', N'English', N'Classic Ed.', N'Cultural, historical, and philosophic panorama of India written in Ahmednagar Fort.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (100, 1, 2, N'Gitanjali: Song Offerings', N'Rabindranath Tagore', N'Literature', N'Poetry', N'English', N'Centenary Ed.', N'Nobel prize winning collection of deeply spiritual and lyrical prose-poems.', 3, 0, 1, '2026-06-01 09:00:00', 4, '2026-06-01 09:00:00'),
    (101, 2, 3, N'Advanced Coordinate Geometry', N'S. L. Loney', N'Mathematics', N'Textbook', N'English', N'Standard Ed.', N'Conic sections, parabolas, ellipses, hyperbolas, and polar equations.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (102, 2, 3, N'Mathematical Statistics and Applications', N'John E. Freund', N'Mathematics', N'Textbook', N'English', N'8th Edition', N'Joint probability distributions, regression models, and nonparametric tests.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (103, 2, 3, N'Graph Theory and Combinatorics', N'Douglas B. West', N'Mathematics', N'Textbook', N'English', N'2nd Edition', N'Tree structures, planarity, Eulerian circuits, and chromatic polynomials.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (104, 2, 3, N'Numerical Methods for Scientists and Engineers', N'Richard W. Hamming', N'Mathematics', N'Textbook', N'English', N'2nd Edition', N'Finite difference methods, spline interpolation, and numerical integration.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (105, 2, 3, N'Vector Analysis and Field Theory', N'Murray R. Spiegel', N'Mathematics', N'Textbook', N'English', N'2nd Edition', N'Divergence, curl, Stokes theorem, and curvilinear coordinate systems.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (106, 2, 3, N'Optics, Waves and Laser Physics', N'Ajoy Ghatak', N'Physics', N'Science', N'English', N'6th Edition', N'Fiber optics, Fourier optics, polarization, and lasers in medicine.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (107, 2, 3, N'Quantum Mechanics: Concepts and Applications', N'Nouredine Zettili', N'Physics', N'Science', N'English', N'2nd Edition', N'Angular momentum, perturbation theory, and quantum measurement theory.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (108, 2, 3, N'Thermal Physics and Kinetic Theory', N'Charles Kittel', N'Physics', N'Science', N'English', N'2nd Edition', N'Gibbs distribution, Planck radiation law, and semiconductor electron gas.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (109, 2, 3, N'Classical Mechanics: Systems of Particles', N'Herbert Goldstein', N'Physics', N'Science', N'English', N'3rd Edition', N'Lagrangian and Hamiltonian formulations, rigid body dynamics, and chaos.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (110, 2, 3, N'Nuclear and Particle Physics', N'Brian R. Martin', N'Physics', N'Science', N'English', N'3rd Edition', N'Quark models, standard model electroweak theory, and neutrino oscillations.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (111, 2, 3, N'Coordination Chemistry and Organometallics', N'Robert H. Crabtree', N'Chemistry', N'Science', N'English', N'7th Edition', N'Ligand field theory, catalytic cycles, and metal carbonyl complexes.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (112, 2, 3, N'Stereochemistry of Organic Compounds', N'Ernest L. Eliel', N'Chemistry', N'Science', N'English', N'Classic Ed.', N'Conformational analysis, optical isomerism, and asymmetric synthesis.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (113, 2, 3, N'Chemical Thermodynamics for Engineers', N'J. M. Smith', N'Chemistry', N'Science', N'English', N'8th Edition', N'Phase equilibria, fugacity, activity coefficients, and chemical reaction equilibria.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (114, 2, 3, N'Spectroscopic Identification of Organic Compounds', N'Robert M. Silverstein', N'Chemistry', N'Science', N'English', N'8th Edition', N'NMR, Infrared, Mass spectrometry, and UV-Vis interpretation.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (115, 2, 3, N'Green Chemistry: Theory and Practice', N'Paul T. Anastas', N'Chemistry', N'Science', N'English', N'1st Edition', N'Atom economy, non-toxic reagent design, and renewable feedstocks.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (116, 2, 3, N'Molecular Biology of the Cell', N'Bruce Alberts', N'Biology', N'Science', N'English', N'6th Edition', N'Cell signaling, protein synthesis, cytoskeleton, and cell cycle checkpoints.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (117, 2, 3, N'Developmental Biology and Embryology', N'Scott F. Gilbert', N'Biology', N'Science', N'English', N'11th Edition', N'Morphogenesis, stem cells, embryonic germ layers, and gene regulation.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (118, 2, 3, N'Neurobiology: Molecules, Cells and Systems', N'Gordon M. Shepherd', N'Biology', N'Science', N'English', N'3rd Edition', N'Synaptic transmission, neural circuits, sensory perception, and motor control.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (119, 2, 3, N'Bioinformatics: Sequence and Genome Analysis', N'David W. Mount', N'Biology', N'Technology', N'English', N'2nd Edition', N'BLAST algorithms, multiple sequence alignments, and phylogenetic trees.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (120, 2, 3, N'Biotechnology: Principles and Applications', N'John E. Smith', N'Biology', N'Science', N'English', N'5th Edition', N'Fermentation biotechnology, recombinant DNA, and monoclonal antibodies.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (121, 2, 3, N'Automata Theory, Languages and Computation', N'John E. Hopcroft', N'Computer Science', N'Technology', N'English', N'3rd Edition', N'Deterministic finite automata, context-free grammars, and Turing machines.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (122, 2, 3, N'Compilers: Principles, Techniques and Tools', N'Alfred V. Aho', N'Computer Science', N'Technology', N'English', N'2nd Edition', N'Lexical parsing, syntax trees, intermediate code generation, and optimizations.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (123, 2, 3, N'Cryptography and Network Security', N'William Stallings', N'Computer Science', N'Technology', N'English', N'7th Edition', N'RSA algorithm, AES encryption, digital signatures, and blockchain security.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (124, 2, 3, N'Deep Learning and Neural Architectures', N'Ian Goodfellow', N'Computer Science', N'Technology', N'English', N'1st Edition', N'Convolutional nets, recurrent neural nets, autoencoders, and generative models.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (125, 2, 3, N'Natural Language Processing with Python', N'Steven Bird', N'Computer Science', N'Technology', N'English', N'1st Edition', N'Tokenization, POS tagging, sentiment classification, and semantic parsing.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (126, 2, 3, N'Macroeconomic Analysis and Public Policy', N'David Romer', N'Economics', N'Commerce', N'English', N'5th Edition', N'Dynamic stochastic general equilibrium, consumption models, and monetary shocks.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (127, 2, 3, N'Development Economics: Perspectives and Policies', N'Debraj Ray', N'Economics', N'Social Science', N'English', N'1st Edition', N'Poverty traps, rural-urban migration, inequality, and agrarian land reforms.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (128, 2, 3, N'International Trade and Global Finance', N'Paul R. Krugman', N'Economics', N'Commerce', N'English', N'11th Edition', N'Comparative advantage, tariff barriers, balance of payments, and exchange rates.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (129, 2, 3, N'Corporate Finance and Capital Budgeting', N'Stephen A. Ross', N'Commerce', N'Commerce', N'English', N'12th Edition', N'Net present value, internal rate of return, capital structure, and dividend policies.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (130, 2, 3, N'Auditing Principles and Practice', N'Kamal Gupta', N'Commerce', N'Commerce', N'English', N'6th Edition', N'Internal controls, audit sampling, statutory duties, and fraud detection.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (131, 2, 3, N'Strategic Management and Business Policy', N'Thomas L. Wheelen', N'Business Studies', N'Commerce', N'English', N'15th Edition', N'SWOT analysis, Porter''s five forces, diversification, and corporate governance.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (132, 2, 3, N'Organizational Behavior and Leadership', N'Stephen P. Robbins', N'Business Studies', N'Commerce', N'English', N'18th Edition', N'Team dynamics, conflict resolution, organizational culture, and change management.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (133, 2, 3, N'Modern Indian History: From Plassey to Partition', N'Sekhar Bandyopadhyay', N'Social Science', N'History', N'English', N'Revised Ed.', N'Colonial impact, nationalist movement, socio-religious reforms, and partition.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (134, 2, 3, N'Ancient India and Archaeology', N'Upinder Singh', N'Social Science', N'History', N'English', N'1st Edition', N'Indus Valley civilization, Vedic traditions, Mauryan Empire, and numismatics.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (135, 2, 3, N'Comparative Politics and Democratic Institutions', N'J. C. Johari', N'Social Science', N'Civics', N'English', N'4th Edition', N'Constitutionalism, political parties, electoral systems, and pressure groups.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (136, 2, 3, N'Indian Economy: Performance and Policies', N'Uma Kapila', N'Economics', N'Commerce', N'English', N'21st Edition', N'Agricultural reforms, industrial growth, banking NPA crisis, and services sector.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (137, 2, 3, N'Social Problems in India', N'Ram Ahuja', N'Social Science', N'Sociology', N'English', N'3rd Edition', N'Poverty, caste discrimination, juvenile delinquency, and communalism.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (138, 2, 3, N'Research Methodology: Methods and Techniques', N'C. R. Kothari', N'Education', N'Reference', N'English', N'4th Edition', N'Sampling designs, hypothesis testing, survey techniques, and report writing.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (139, 2, 3, N'A History of Western Philosophy', N'Bertrand Russell', N'Philosophy', N'Humanities', N'English', N'Classic Ed.', N'Survey of philosophical thought from the Pre-Socratics to 20th century analysis.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (140, 2, 3, N'Ethics: Theory and Contemporary Issues', N'Barbara MacKinnon', N'Philosophy', N'Humanities', N'English', N'9th Edition', N'Utilitarianism, Kantian deontology, virtue ethics, and bioethical dilemmas.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (141, 2, 3, N'Pride and Prejudice', N'Jane Austen', N'English', N'Literature', N'English', N'Definitive Ed.', N'Classic romantic novel exploring social class, manners, and marital expectations.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (142, 2, 3, N'Wuthering Heights', N'Emily Bronte', N'English', N'Literature', N'English', N'Illustrated Ed.', N'Passionate and tragic gothic tale set upon the Yorkshire moors.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (143, 2, 3, N'Great Expectations', N'Charles Dickens', N'English', N'Literature', N'English', N'Annotated Ed.', N'Victorian masterpiece following Pip''s maturation, wealth, and redemption.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (144, 2, 3, N'1984: A Dystopian Masterpiece', N'George Orwell', N'English', N'Literature', N'English', N'Critical Ed.', N'Cautionary political novel on totalitarian surveillance, censorship, and Newspeak.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (145, 2, 3, N'To Kill a Mockingbird', N'Harper Lee', N'English', N'Literature', N'English', N'50th Anniv.', N'Pulitzer Prize winning narrative on racial injustice and moral courage.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (146, 2, 3, N'The Old Man and the Sea', N'Ernest Hemingway', N'English', N'Literature', N'English', N'Original Ed.', N'Nobel laureate novella recounting an aging Cuban fisherman''s relentless struggle.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (147, 2, 3, N'Modern Hindi Poetry and Literary Criticism', N'Namwar Singh', N'Hindi', N'Literature', N'Hindi', N'2nd Edition', N'Critical evaluation of modern Hindi poetry movements and Chhayavad.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (148, 2, 3, N'Intermediate Sanskrit Reader and Chrestomathy', N'Charles Rockwell Lanman', N'Sanskrit', N'Language', N'Sanskrit', N'Harvard Ed.', N'Annotated classical Sanskrit extracts from the Rigveda and Mahabharata.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (149, 2, 3, N'Oxford Illustrated Science Encyclopedia', N'Oxford University Press', N'Science', N'Reference', N'English', N'Revised Ed.', N'Over 2,000 full-color scientific entries spanning astronomy, physics, and geology.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (150, 2, 3, N'World Famous Speeches That Changed History', N'Brian MacArthur', N'Social Science', N'History', N'English', N'Expanded Ed.', N'Inspirational historic orations from Pericles and Lincoln to Churchill and Mandela.', 3, 0, 1, '2026-06-01 09:00:00', 6, '2026-06-01 09:00:00'),
    (151, 2, 4, N'Pure Mathematics: Analysis and Topology', N'Walter Rudin', N'Mathematics', N'Textbook', N'English', N'3rd Edition', N'Metric spaces, compact sets, Lebesgue integration, and Fourier series.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (152, 2, 4, N'Complex Variables and Applications', N'James Ward Brown & Ruel V. Churchill', N'Mathematics', N'Textbook', N'English', N'9th Edition', N'Analytic functions, Cauchy-Goursat theorem, Laurent series, and residue calculus.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (153, 2, 4, N'Abstract Algebra: Group and Ring Theory', N'David S. Dummit & Richard M. Foote', N'Mathematics', N'Textbook', N'English', N'3rd Edition', N'Sylow theorems, polynomial rings, field extensions, and Galois theory.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (154, 2, 4, N'Differential Geometry of Curves and Surfaces', N'Manfredo P. do Carmo', N'Mathematics', N'Textbook', N'English', N'2nd Edition', N'Frenet formulas, Gaussian curvature, geodesics, and Gauss-Bonnet theorem.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (155, 2, 4, N'Operations Research: An Introduction', N'Hamdy A. Taha', N'Mathematics', N'Commerce', N'English', N'10th Edition', N'Simplex method, duality, integer programming, transportation algorithms, and queuing.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (156, 2, 4, N'Quantum Optics and Coherent Radiation', N'Marlan O. Scully', N'Physics', N'Science', N'English', N'1st Edition', N'Quantized light fields, photon statistics, and laser spectroscopy.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (157, 2, 4, N'Relativistic Mechanics and Gravitation', N'Wolfgang Rindler', N'Physics', N'Science', N'English', N'2nd Edition', N'Lorentz transformations, 4-vectors, tensor calculus, and Schwarzschild metric.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (158, 2, 4, N'Plasma Physics and Controlled Fusion', N'Francis F. Chen', N'Physics', N'Science', N'English', N'3rd Edition', N'Debye shielding, magnetohydrodynamics, plasma waves, and tokamak fusion.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (159, 2, 4, N'Condensed Matter Physics', N'Michael P. Marder', N'Physics', N'Science', N'English', N'2nd Edition', N'Electronic band structure, phononic lattices, and superconductivity.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (160, 2, 4, N'Nanotechnology and Nanoscience Fundamentals', N'Charles P. Poole Jr.', N'Physics', N'Technology', N'English', N'1st Edition', N'Carbon nanotubes, quantum dots, self-assembly, and nano-devices.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (161, 2, 4, N'Supramolecular Chemistry: Concepts and Perspectives', N'Jean-Marie Lehn', N'Chemistry', N'Science', N'English', N'1st Edition', N'Host-guest chemistry, molecular recognition, and self-organization.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (162, 2, 4, N'Polymer Science and Engineering', N'V. R. Gowariker', N'Chemistry', N'Technology', N'English', N'2nd Edition', N'Polymer synthesis, molecular weight determination, and elastomer viscoelasticity.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (163, 2, 4, N'Computational Chemistry and Molecular Modeling', N'Christopher J. Cramer', N'Chemistry', N'Science', N'English', N'2nd Edition', N'Hartree-Fock theory, density functional theory, and semi-empirical methods.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (164, 2, 4, N'Medicinal Chemistry and Drug Design', N'Graham L. Patrick', N'Chemistry', N'Science', N'English', N'6th Edition', N'Pharmacokinetics, receptor binding, antibiotic synthesis, and structure-activity.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (165, 2, 4, N'Crystallography and X-ray Diffraction', N'B. D. Cullity', N'Chemistry', N'Science', N'English', N'3rd Edition', N'Bravais lattices, Miller indices, Bragg diffraction law, and crystal indexing.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (166, 2, 4, N'Stem Cell Biology and Regenerative Medicine', N'Robert Lanza', N'Biology', N'Science', N'English', N'2nd Edition', N'Pluripotent stem cells, tissue engineering, and ethical cloning frontiers.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (167, 2, 4, N'Marine Biology: Ecology and Ocean Life', N'Peter Castro & Michael E. Huber', N'Biology', N'Science', N'English', N'10th Edition', N'Coral reef biodiversity, pelagic zones, marine food webs, and acidification.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (168, 2, 4, N'Behavioral Ecology of Animals', N'J. R. Krebs & N. B. Davies', N'Biology', N'Science', N'English', N'4th Edition', N'Foraging strategies, sexual selection, territoriality, and social cooperation.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (169, 2, 4, N'Biostatistics for Health and Medical Sciences', N'Wayne W. Daniel', N'Biology', N'Science', N'English', N'10th Edition', N'Survival analysis, clinical trial designs, odds ratios, and logistic regression.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (170, 2, 4, N'Virology: Principles and Pathogenesis', N'S. J. Flint', N'Biology', N'Science', N'English', N'4th Edition', N'Viral taxonomy, retroviruses, epidemic epidemiology, and antiviral therapeutics.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (171, 2, 4, N'Distributed Operating Systems: Principles and Paradigms', N'Andrew S. Tanenbaum', N'Computer Science', N'Technology', N'English', N'2nd Edition', N'Remote procedure calls, distributed shared memory, consensus, and fault tolerance.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (172, 2, 4, N'Computer Vision: Algorithms and Applications', N'Richard Szeliski', N'Computer Science', N'Technology', N'English', N'2nd Edition', N'Feature detection, image segmentation, optical flow, and depth estimation.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (173, 2, 4, N'Autonomous Robotics: Control and Navigation', N'Roland Siegwart', N'Computer Science', N'Technology', N'English', N'2nd Edition', N'Kinematic models, SLAM algorithms, Kalman filtering, and path planning.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (174, 2, 4, N'Big Data Analytics with Apache Spark', N'Matei Zaharia', N'Computer Science', N'Technology', N'English', N'1st Edition', N'Resilient distributed datasets, Spark SQL, MLlib pipelines, and streaming.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (175, 2, 4, N'High-Performance Computing and Parallel Programming', N'Michael J. Quinn', N'Computer Science', N'Technology', N'English', N'2nd Edition', N'OpenMP, MPI message passing, GPU CUDA programming, and cluster topologies.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (176, 2, 4, N'Econometrics: Principles and Empirical Analysis', N'Damodar N. Gujarati', N'Economics', N'Commerce', N'English', N'5th Edition', N'Ordinary least squares, heteroscedasticity, multicollinearity, and time-series.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (177, 2, 4, N'Public Finance and Taxation Economics', N'Harvey S. Rosen', N'Economics', N'Commerce', N'English', N'10th Edition', N'Public goods, externality taxation, cost-benefit analysis, and deficit budgets.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (178, 2, 4, N'Agricultural Economics and Agrarian Systems', N'Sadhu & Singh', N'Economics', N'Social Science', N'English', N'9th Edition', N'Farm management, green revolution innovations, agricultural subsidies, and MSP.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (179, 2, 4, N'Security Analysis and Portfolio Management', N'Prasanna Chandra', N'Commerce', N'Commerce', N'English', N'6th Edition', N'Capital asset pricing model, technical chart analysis, mutual funds, and hedging.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (180, 2, 4, N'International Financial Management', N'P. G. Apte', N'Commerce', N'Commerce', N'English', N'8th Edition', N'Foreign exchange markets, currency swaps, international debt, and hedging risk.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (181, 2, 4, N'Supply Chain Management and Logistics', N'Sunil Chopra', N'Business Studies', N'Commerce', N'English', N'7th Edition', N'Inventory optimization, distribution network design, bullwhip effect, and logistics.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (182, 2, 4, N'Entrepreneurship and New Venture Creation', N'Rajeev Roy', N'Business Studies', N'Commerce', N'English', N'3rd Edition', N'Business model canvas, venture capital pitching, intellectual property, and scaling.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (183, 2, 4, N'Urban Sociology and Metropolitan Studies', N'Mark Gottdiener', N'Social Science', N'Sociology', N'English', N'5th Edition', N'Urban ecology, gentrification, smart city governance, and suburban expansion.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (184, 2, 4, N'Social Psychology: Groups and Social Influence', N'David G. Myers', N'Psychology', N'Social Science', N'English', N'13th Edition', N'Attitude formation, group conformity, cognitive dissonance, and altruism.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (185, 2, 4, N'Criminology and Penology: Causes and Prevention', N'N. V. Paranjape', N'Social Science', N'Law', N'English', N'17th Edition', N'Theories of crime, juvenile justice, prison reforms, and rehabilitation ethics.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (186, 2, 4, N'Environmental Law and Policy in India', N'Shyam Divan & Armin Rosencranz', N'Social Science', N'Law', N'English', N'2nd Edition', N'Water and Air pollution acts, National Green Tribunal judgments, and forest rights.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (187, 2, 4, N'Human Rights in Constitutional Jurisprudence', N'H. O. Agarwal', N'Social Science', N'Law', N'English', N'16th Edition', N'Universal declaration, custodial violence safeguards, and international humanitarian law.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (188, 2, 4, N'Journalism and Mass Communication Fundamentals', N'Keval J. Kumar', N'Mass Media', N'Communication', N'English', N'4th Edition', N'Print media ethics, television broadcast standards, digital journalism, and censorship.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (189, 2, 4, N'Creative Writing and Narrative Storytelling', N'Janet Burroway', N'English', N'Literature', N'English', N'10th Edition', N'Character development, plot pacing, sensory imagery, and revision strategies.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (190, 2, 4, N'The Complete Works of Rabindranath Tagore', N'Rabindranath Tagore', N'Literature', N'Anthology', N'English', N'Centennial Ed.', N'Comprehensive treasury of Nobel laureate Tagore''s poems, plays, and stories.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (191, 2, 4, N'Classic Indian Short Stories', N'R. K. Narayan', N'English', N'Literature', N'English', N'Malgudi Ed.', N'Beloved tales set in the fictional southern Indian town of Malgudi.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (192, 2, 4, N'Midnight''s Children', N'Salman Rushdie', N'English', N'Literature', N'English', N'Booker Winner', N'Magical realist epic chronicling India''s post-independence tumultuous transition.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (193, 2, 4, N'A Suitable Boy', N'Vikram Seth', N'English', N'Literature', N'English', N'Standard Ed.', N'Expansive multi-family saga set across post-colonial northern India.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (194, 2, 4, N'God of Small Things', N'Arundhati Roy', N'English', N'Literature', N'English', N'Original Ed.', N'Poignant narrative on caste, social taboo, and tragic childhood in Ayemenem.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (195, 2, 4, N'The Shadow Lines', N'Amitav Ghosh', N'English', N'Literature', N'English', N'Educational Ed.', N'Subtle meditation on nationhood, borders, memories, and communal violence.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (196, 2, 4, N'Madhushala: The House of Wine', N'Harivansh Rai Bachchan', N'Hindi', N'Poetry', N'Hindi', N'Collector Ed.', N'Celebrated philosophical quartet verses exploring existence through metaphor.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (197, 2, 4, N'Panchatantra: Timeless Fables and Morals', N'Pandit Vishnu Sharma', N'Sanskrit', N'Literature', N'English', N'Illustrated Ed.', N'Ancient animal allegories illustrating political statecraft and human wisdom.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (198, 2, 4, N'Encyclopedic Handbook of World Religions', N'Mircea Eliade', N'Humanities', N'Reference', N'English', N'Comprehensive', N'Comparative exploration of myth, ritual, sacred doctrine, and religious practices.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (199, 2, 4, N'Illustrated Encyclopedia of Geography and Space', N'Dorling Kindersley', N'General Knowledge', N'Reference', N'English', N'Revised Ed.', N'Stunning geological cutaways, stellar cartography, and global demographic maps.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00'),
    (200, 2, 4, N'Dictionary of Science and Scientific Biography', N'David Millar', N'Science', N'Reference', N'English', N'5th Edition', N'Exhaustive cross-referenced dictionary of 5,000 physical, chemical, and biological terms.', 3, 0, 1, '2026-06-01 09:00:00', 8, '2026-06-01 09:00:00');

    SET IDENTITY_INSERT library_schema.library_book OFF;
    PRINT N'Inserted 200 catalog titles.';

    PRINT N'======================================================================';
    PRINT N'3. INSERTING 600 PHYSICAL COPIES (3 PER TITLE ACROSS 7 STATUSES)';
    PRINT N'======================================================================';

    SET IDENTITY_INSERT library_schema.library_book_copy ON;

    -- Generate Copy 1, Copy 2, Copy 3 for each of the 200 catalog books (600 copies total)
    INSERT INTO library_schema.library_book_copy
    (
        book_copy_id, book_id, school_id, branch_id, copy_number,
        barcode, copy_status, is_active, created_at, created_by, updated_at
    )
    SELECT
        (b.book_id - 1) * 3 + cp.copy_no AS book_copy_id,
        b.book_id,
        b.school_id,
        b.branch_id,
        cp.copy_no AS copy_number,
        CONCAT(N'BC-SCH', b.school_id, N'-BR', b.branch_id, N'-BK', RIGHT(CONCAT(N'000', b.book_id), 3), N'-CP', cp.copy_no) AS barcode,
        -- Realistic initial copy statuses across selected inventory
        CASE 
            WHEN b.book_id = 6   AND cp.copy_no = 3 THEN N'DAMAGED'
            WHEN b.book_id = 25  AND cp.copy_no = 3 THEN N'MAINTENANCE'
            WHEN b.book_id = 45  AND cp.copy_no = 3 THEN N'RETIRED'
            WHEN b.book_id = 75  AND cp.copy_no = 3 THEN N'DAMAGED'
            WHEN b.book_id = 90  AND cp.copy_no = 3 THEN N'MAINTENANCE'
            WHEN b.book_id = 120 AND cp.copy_no = 3 THEN N'RETIRED'
            WHEN b.book_id = 145 AND cp.copy_no = 3 THEN N'LOST'
            WHEN b.book_id = 175 AND cp.copy_no = 3 THEN N'DAMAGED'
            WHEN b.book_id = 198 AND cp.copy_no = 3 THEN N'LOST'
            ELSE N'AVAILABLE'
        END AS copy_status,
        CASE 
            WHEN b.book_id IN (45, 120) AND cp.copy_no = 3 THEN 0 -- Retired copies soft-deleted
            ELSE 1
        END AS is_active,
        b.created_at,
        b.created_by,
        b.updated_at
    FROM library_schema.library_book b
    CROSS JOIN (VALUES (1), (2), (3)) cp(copy_no);

    SET IDENTITY_INSERT library_schema.library_book_copy OFF;
    PRINT N'Inserted 600 physical book copies.';

    PRINT N'======================================================================';
    PRINT N'4. INSERTING REALISTIC CIRCULATION LEDGER TRANSACTIONS';
    PRINT N'======================================================================';

    SET IDENTITY_INSERT library_schema.library_book_borrow ON;

    INSERT INTO library_schema.library_book_borrow
    (
        borrow_id, school_id, branch_id, academic_year_id, student_id,
        class_id, section_id, book_id, book_copy_id, borrow_status,
        borrowed_at, due_date, returned_at, returned_to, issued_by,
        remarks, is_active, updated_at
    )
    VALUES
    (1, 1, 1, 1, 1, 1, 1, 1, 1, N'RETURNED', '2026-06-02 09:15:00', '2026-06-16', '2026-06-15 14:20:00', 2, 2, N'Algebra & polynomials foundational reference.', 1, '2026-06-15 14:20:00'),
    (2, 1, 1, 1, 1, 1, 1, 2, 4, N'RETURNED', '2026-06-16 10:30:00', '2026-06-30', '2026-06-29 11:15:00', 2, 2, N'Kinematics and vectors chapter study.', 1, '2026-06-29 11:15:00'),
    (3, 1, 1, 1, 1, 1, 1, 4, 11, N'RETURNED', '2026-06-20 14:00:00', '2026-07-04', '2026-07-02 16:30:00', 2, 2, N'Selected English poetry anthology for recitation.', 1, '2026-07-02 16:30:00'),
    (4, 1, 1, 1, 1, 1, 1, 1, 2, N'RETURNED', '2026-07-01 10:00:00', '2026-07-15', '2026-07-14 14:30:00', 2, 2, N'Calculus limits and continuity unit.', 1, '2026-07-14 14:30:00'),
    (5, 1, 1, 1, 1, 1, 1, 3, 7, N'RETURNED', '2026-07-05 11:30:00', '2026-07-19', '2026-07-18 15:00:00', 2, 2, N'Inorganic salts and qualitative analysis practicals.', 1, '2026-07-18 15:00:00'),
    (6, 1, 1, 1, 1, 1, 1, 5, 14, N'RETURNED', '2026-07-12 13:00:00', '2026-07-26', '2026-07-25 12:45:00', 2, 2, N'Medieval Indian administration research essay.', 1, '2026-07-25 12:45:00'),
    (7, 1, 1, 1, 1, 1, 1, 6, 16, N'RETURNED', '2026-07-20 09:45:00', '2026-08-03', '2026-08-01 11:20:00', 2, 2, N'Python control flow and algorithmic problem solving.', 1, '2026-08-01 11:20:00'),
    (8, 1, 1, 1, 1, 1, 1, 5, 13, N'RETURNED', '2026-08-05 10:00:00', '2026-08-19', '2026-08-18 14:15:00', 2, 2, N'Medieval Indian administration reference returned in good condition.', 1, '2026-08-18 14:15:00'),
    (9, 1, 1, 1, 1, 1, 1, 2, 6, N'RETURNED', '2026-08-02 11:15:00', '2026-08-16', '2026-08-14 15:10:00', 2, 2, N'Thermodynamics laws and heat engine cycles.', 1, '2026-08-14 15:10:00'),
    (10, 1, 1, 1, 1, 1, 1, 4, 12, N'RETURNED', '2026-08-08 14:30:00', '2026-08-22', '2026-08-20 10:15:00', 2, 2, N'Literary criticism and Victorian prose study.', 1, '2026-08-20 10:15:00'),
    (11, 1, 1, 1, 1, 1, 1, 6, 17, N'RETURNED', '2026-08-15 10:00:00', '2026-08-29', '2026-08-28 16:00:00', 2, 2, N'Object-oriented classes and data encapsulation.', 1, '2026-08-28 16:00:00'),
    (12, 1, 1, 1, 1, 1, 1, 7, 19, N'RETURNED', '2026-08-01 09:30:00', '2026-08-15', '2026-08-14 13:00:00', 2, 2, N'Linear algebra matrix transformations.', 1, '2026-08-14 13:00:00'),
    (13, 1, 1, 1, 1, 1, 1, 8, 22, N'RETURNED', '2026-08-10 11:00:00', '2026-08-24', '2026-08-23 15:30:00', 2, 2, N'Discrete graph theory and tree traversal.', 1, '2026-08-23 15:30:00'),
    (14, 1, 1, 1, 1, 1, 1, 10, 28, N'RETURNED', '2026-08-16 10:45:00', '2026-08-30', '2026-08-29 16:20:00', 2, 2, N'Probability distributions reference reading.', 1, '2026-08-29 16:20:00'),
    (15, 1, 1, 1, 1, 1, 1, 11, 31, N'RETURNED', '2026-08-12 14:00:00', '2026-08-26', '2026-08-25 11:15:00', 2, 2, N'Classical Newtonian mechanics problem solving.', 1, '2026-08-25 11:15:00'),
    (16, 1, 1, 1, 1, 1, 1, 34, 100, N'RETURNED', '2026-08-18 12:00:00', '2026-09-01', '2026-08-31 10:30:00', 2, 2, N'Algorithms and computational complexity notes.', 1, '2026-08-31 10:30:00'),
    (17, 1, 1, 1, 1, 1, 1, 42, 124, N'RETURNED', '2026-08-20 15:00:00', '2026-09-03', '2026-09-02 14:00:00', 2, 2, N'World history reference reading.', 1, '2026-09-02 14:00:00'),
    (18, 1, 1, 1, 1, 1, 1, 49, 145, N'RETURNED', '2026-08-22 09:30:00', '2026-09-05', '2026-09-04 16:00:00', 2, 2, N'Shakespeare critical plays analysis.', 1, '2026-09-04 16:00:00'),
    (19, 1, 1, 1, 1, 1, 1, 3, 9, N'OVERDUE', '2026-08-14 10:30:00', '2026-08-28', NULL, NULL, 2, N'Organic reaction mechanisms guide. Due date exceeded; overdue notification issued.', 1, '2026-08-29 08:30:00'),
    (20, 1, 1, 1, 1, 1, 1, 1, 1, N'ACTIVE', '2026-08-28 09:30:00', '2026-09-15', NULL, NULL, 2, N'Re-issued for mid-term board examination preparation.', 1, '2026-08-28 09:30:00'),
    (21, 1, 1, 1, 1, 1, 1, 6, 16, N'ACTIVE', '2026-09-04 11:00:00', '2026-09-18', NULL, NULL, 2, N'Advanced binary tree traversal algorithms practical.', 1, '2026-09-04 11:00:00'),
    (22, 1, 1, 1, 2, 1, 2, 1, 2, N'ACTIVE', '2026-09-01 11:15:00', '2026-09-18', NULL, NULL, 2, N'Standard loan period.', 1, '2026-09-01 11:15:00'),
    (23, 1, 1, 1, 2, 1, 2, 3, 8, N'ACTIVE', '2026-09-02 12:00:00', '2026-09-19', NULL, NULL, 2, N'Issued for lab session.', 1, '2026-09-02 12:00:00'),
    (24, 1, 1, 1, 2, 1, 2, 5, 14, N'RETURNED', '2026-07-25 14:00:00', '2026-08-08', '2026-08-07 10:45:00', 2, 2, N'History book returned in intact condition.', 1, '2026-08-07 10:45:00'),
    (25, 1, 1, 1, 3, 2, 3, 2, 4, N'OVERDUE', '2026-08-10 10:30:00', '2026-08-24', NULL, NULL, 2, N'Reminder SMS sent to parent.', 1, '2026-08-25 08:00:00'),
    (26, 1, 1, 1, 3, 2, 3, 4, 10, N'RETURNED', '2026-07-20 09:00:00', '2026-08-03', '2026-08-01 13:20:00', 2, 2, N'English anthology returned on time.', 1, '2026-08-01 13:20:00'),
    (27, 1, 1, 1, 4, 2, 4, 2, 5, N'RETURNED', '2026-07-10 14:00:00', '2026-07-24', '2026-07-23 11:00:00', 2, 2, N'Clearance stamped.', 1, '2026-07-23 11:00:00'),
    (28, 1, 1, 1, 4, 2, 4, 4, 10, N'OVERDUE', '2026-08-12 15:00:00', '2026-08-26', NULL, NULL, 2, N'First overdue notice served.', 1, '2026-08-27 09:00:00'),
    (29, 1, 1, 1, 17, 1, 1, 12, 34, N'ACTIVE', '2026-09-03 10:00:00', '2026-09-20', NULL, NULL, 2, N'Circuit analysis course reading.', 1, '2026-09-03 10:00:00'),
    (30, 1, 1, 1, 18, 1, 2, 26, 76, N'ACTIVE', '2026-09-04 14:30:00', '2026-09-21', NULL, NULL, 2, N'Biology genetics reference manual.', 1, '2026-09-04 14:30:00'),
    (31, 1, 2, 1, 5, 3, 5, 51, 151, N'RETURNED', '2026-07-02 11:00:00', '2026-07-16', '2026-07-15 16:00:00', 4, 4, N'Applied math homework completed.', 1, '2026-07-15 16:00:00'),
    (32, 1, 2, 1, 5, 3, 5, 51, 151, N'ACTIVE', '2026-08-30 10:15:00', '2026-09-16', NULL, NULL, 4, N'Second checkout for algebra units.', 1, '2026-08-30 10:15:00'),
    (33, 1, 2, 1, 6, 3, 6, 56, 166, N'ACTIVE', '2026-09-03 14:00:00', '2026-09-20', NULL, NULL, 4, N'Acoustics and wave theory reading.', 1, '2026-09-03 14:00:00'),
    (34, 1, 2, 1, 7, 4, 7, 62, 184, N'OVERDUE', '2026-08-11 09:00:00', '2026-08-25', NULL, NULL, 4, N'Plant botany atlas overdue notice.', 1, '2026-08-26 11:00:00'),
    (35, 1, 2, 1, 8, 4, 8, 66, 196, N'RETURNED', '2026-07-08 10:30:00', '2026-07-22', '2026-07-21 14:10:00', 4, 4, N'C++ programming textbook returned.', 1, '2026-07-21 14:10:00'),
    (36, 1, 2, 1, 8, 4, 8, 67, 199, N'ACTIVE', '2026-09-04 11:30:00', '2026-09-21', NULL, NULL, 4, N'Java collections and multithreading study.', 1, '2026-09-04 11:30:00'),
    (37, 1, 2, 1, 21, 3, 5, 71, 211, N'RETURNED', '2026-07-15 14:00:00', '2026-07-29', '2026-07-28 11:00:00', 4, 4, N'World geography landscape returned.', 1, '2026-07-28 11:00:00'),
    (38, 2, 3, 2, 9, 5, 9, 101, 301, N'RETURNED', '2026-07-05 10:00:00', '2026-07-19', '2026-07-18 11:30:00', 6, 6, N'Coordinate geometry text returned.', 1, '2026-07-18 11:30:00'),
    (39, 2, 3, 2, 9, 5, 9, 101, 301, N'ACTIVE', '2026-08-29 11:00:00', '2026-09-16', NULL, NULL, 6, N'Conics and polar coordinate problem set.', 1, '2026-08-29 11:00:00'),
    (40, 2, 3, 2, 10, 5, 10, 106, 316, N'ACTIVE', '2026-09-02 14:30:00', '2026-09-19', NULL, NULL, 6, N'Laser physics lab reference.', 1, '2026-09-02 14:30:00'),
    (41, 2, 3, 2, 11, 6, 11, 111, 331, N'OVERDUE', '2026-08-14 09:30:00', '2026-08-28', NULL, NULL, 6, N'Overdue notice sent to student portal.', 1, '2026-08-29 09:00:00'),
    (42, 2, 3, 2, 12, 6, 12, 116, 346, N'RETURNED', '2026-07-12 13:00:00', '2026-07-26', '2026-07-25 15:00:00', 6, 6, N'Molecular cell biology returned cleanly.', 1, '2026-07-25 15:00:00'),
    (43, 2, 3, 2, 12, 6, 12, 121, 361, N'ACTIVE', '2026-09-03 10:00:00', '2026-09-20', NULL, NULL, 6, N'Automata theory computation assignments.', 1, '2026-09-03 10:00:00'),
    (44, 2, 3, 2, 25, 5, 9, 141, 421, N'RETURNED', '2026-07-20 11:00:00', '2026-08-03', '2026-08-02 15:45:00', 6, 6, N'Pride and Prejudice classic reader returned.', 1, '2026-08-02 15:45:00'),
    (45, 2, 4, 2, 13, 7, 13, 151, 451, N'RETURNED', '2026-07-06 09:30:00', '2026-07-20', '2026-07-19 14:00:00', 8, 8, N'Pure math analysis returned.', 1, '2026-07-19 14:00:00'),
    (46, 2, 4, 2, 13, 7, 13, 151, 451, N'ACTIVE', '2026-08-31 10:00:00', '2026-09-17', NULL, NULL, 8, N'Metric spaces and topology assignment.', 1, '2026-08-31 10:00:00'),
    (47, 2, 4, 2, 14, 7, 14, 156, 466, N'ACTIVE', '2026-09-02 11:30:00', '2026-09-19', NULL, NULL, 8, N'Quantum optics coherent radiation prep.', 1, '2026-09-02 11:30:00'),
    (48, 2, 4, 2, 15, 8, 15, 166, 496, N'OVERDUE', '2026-08-15 14:00:00', '2026-08-29', NULL, NULL, 8, N'Marine biology biodiversity text overdue.', 1, '2026-08-30 08:30:00'),
    (49, 2, 4, 2, 16, 8, 16, 171, 511, N'RETURNED', '2026-07-14 15:30:00', '2026-07-28', '2026-07-27 11:00:00', 8, 8, N'Tanenbaum operating systems returned.', 1, '2026-07-27 11:00:00'),
    (50, 2, 4, 2, 14, 7, 14, 176, 526, N'RETURNED', '2026-07-21 10:15:00', '2026-08-04', '2026-08-03 14:40:00', 8, 8, N'Econometrics analysis manual returned.', 1, '2026-08-03 14:40:00'),
    (51, 2, 4, 2, 15, 8, 15, 186, 556, N'LOST', '2026-08-02 11:00:00', '2026-08-16', NULL, NULL, 8, N'Student reported textbook lost during daily transit.', 1, '2026-08-20 16:00:00'),
    (52, 2, 4, 2, 16, 8, 16, 198, 594, N'LOST', '2026-08-05 13:30:00', '2026-08-19', NULL, NULL, 8, N'Lost book report filed with librarian.', 1, '2026-08-22 10:00:00');

    SET IDENTITY_INSERT library_schema.library_book_borrow OFF;
    PRINT N'Inserted 52 circulation ledger records.';

    PRINT N'======================================================================';
    PRINT N'5. SYNCHRONIZING PHYSICAL COPY STATUSES WITH BORROW LEDGER';
    PRINT N'======================================================================';

    UPDATE bc
    SET copy_status = CASE
        WHEN EXISTS (
            SELECT 1 FROM library_schema.library_book_borrow bb
            WHERE bb.book_copy_id = bc.book_copy_id
              AND bb.is_active = 1
              AND bb.borrow_status = N'BORROWED'
        ) THEN N'BORROWED'
        WHEN EXISTS (
            SELECT 1 FROM library_schema.library_book_borrow bb
            WHERE bb.book_copy_id = bc.book_copy_id
              AND bb.is_active = 1
              AND bb.borrow_status = N'ACTIVE'
        ) THEN N'BORROWED'
        WHEN EXISTS (
            SELECT 1 FROM library_schema.library_book_borrow bb
            WHERE bb.book_copy_id = bc.book_copy_id
              AND bb.is_active = 1
              AND bb.borrow_status = N'OVERDUE'
        ) THEN N'OVERDUE'
        WHEN EXISTS (
            SELECT 1 FROM library_schema.library_book_borrow bb
            WHERE bb.book_copy_id = bc.book_copy_id
              AND bb.is_active = 1
              AND bb.borrow_status = N'LOST'
        ) THEN N'LOST'
        WHEN bc.copy_status IN (N'DAMAGED', N'MAINTENANCE', N'RETIRED') THEN bc.copy_status
        ELSE N'AVAILABLE'
    END
    FROM library_schema.library_book_copy bc;

    PRINT N'Physical copy statuses synchronized.';

    PRINT N'======================================================================';
    PRINT N'6. SYNCHRONIZING REAL-TIME INVENTORY COUNTERS ON CATALOG BOOKS';
    PRINT N'======================================================================';

    UPDATE b
    SET 
        total_copies = ISNULL(counts.total_active_copies, 0),
        available_copies = ISNULL(counts.available_active_copies, 0),
        updated_at = SYSUTCDATETIME()
    FROM library_schema.library_book b
    CROSS APPLY (
        SELECT
            COUNT(*) AS total_active_copies,
            SUM(CASE WHEN bc.copy_status = N'AVAILABLE' THEN 1 ELSE 0 END) AS available_active_copies
        FROM library_schema.library_book_copy bc
        WHERE bc.book_id = b.book_id
          AND bc.is_active = 1
    ) counts;

    PRINT N'Catalog book inventory counters synchronized.';

    COMMIT TRANSACTION;
    PRINT N'======================================================================';
    PRINT N'LIBRARY MOCK DATA SEED SCRIPT COMPLETED SUCCESSFULLY!';
    PRINT N'======================================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrSev INT = ERROR_SEVERITY();
    DECLARE @ErrState INT = ERROR_STATE();
    RAISERROR(@ErrMsg, @ErrSev, @ErrState);
END CATCH;
GO
