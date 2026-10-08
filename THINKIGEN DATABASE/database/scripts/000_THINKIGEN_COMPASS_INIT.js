/* ============================================================================
   THINKIGEN Compass & Connect — Complete MongoDB Initialization
   Generated: 2026-08-29
   Database: MongoDB (Atlas or local)
   
   Total Collections: 20
   One collection per organization database
   
   Usage:
   - Connect to MongoDB with mongosh
   - Run: mongosh < 000_THINKIGEN_COMPASS_INIT.js
   - Or copy-paste in mongosh shell
   
   ============================================================================ */

print("=================================================================");
print("THINKIGEN COMPASS & CONNECT — COMPLETE MONGODB INITIALIZATION");
print("=================================================================");
print("");
print("Database: " + db.getName());
print("Timestamp: " + new Date().toISOString());
print("");

// Initialize all collections in sequence
print("Creating MongoDB collections...");
print("");

print("Collection 1/20: student_mission_control_daily");
load("../mongo/collections/001_student_mission_control_daily.js");
print("✓ student_mission_control_daily created");

print("Collection 2/20: student_compass_intelligence_daily");
load("../mongo/collections/002_student_compass_intelligence_daily.js");
print("✓ student_compass_intelligence_daily created");

print("Collection 3/20: student_learning_health_daily");
load("../mongo/collections/003_student_learning_health_daily.js");
print("✓ student_learning_health_daily created");

print("Collection 4/20: class_subject_syllabus");
load("../mongo/collections/004_class_subject_syllabus.js");
print("✓ class_subject_syllabus created");

print("Collection 5/20: learning_resource");
load("../mongo/collections/005_learning_resource(documets).js");
print("✓ learning_resource created");

print("Collection 6/20: exam_paper");
load("../mongo/collections/006_exam_paper.js");
print("✓ exam_paper created");

print("Collection 7/20: student_learning_progress");
load("../mongo/collections/007_student_learning_progress.js");
print("✓ student_learning_progress created");

print("Collection 8/20: connect_conversation");
load("../mongo/collections/008_connect_conversation.js");
print("✓ connect_conversation created");

print("Collection 9/20: connect_meeting");
load("../mongo/collections/009_connect_meeting.js");
print("✓ connect_meeting created");

print("Collection 10/20: connect_community");
load("../mongo/collections/010_connect_community.js");
print("✓ connect_community created");

print("Collection 11/20: connect_community_member");
load("../mongo/collections/011_connect_community_member.js");
print("✓ connect_community_member created");

print("Collection 12/20: connect_community_join_request");
load("../mongo/collections/012_connect_community_join_request.js");
print("✓ connect_community_join_request created");

print("Collection 13/20: connect_community_post");
load("../mongo/collections/013_connect_community_post.js");
print("✓ connect_community_post created");

print("Collection 14/20: connect_community_comment");
load("../mongo/collections/014_connect_community_comment.js");
print("✓ connect_community_comment created");

print("Collection 15/20: connect_community_post_like");
load("../mongo/collections/015_connect_community_post_like.js");
print("✓ connect_community_post_like created");

print("Collection 16/20: connect_community_discussion");
load("../mongo/collections/016_connect_community_discussion.js");
print("✓ connect_community_discussion created");

print("Collection 17/20: connect_community_discussion_reply");
load("../mongo/collections/017_connect_community_discussion_reply.js");
print("✓ connect_community_discussion_reply created");

print("Collection 18/20: connect_community_poll");
load("../mongo/collections/018_connect_community_poll.js");
print("✓ connect_community_poll created");

print("Collection 19/20: connect_community_poll_vote");
load("../mongo/collections/019_connect_community_poll_vote.js");
print("✓ connect_community_poll_vote created");

print("Community production hardening");
load("../mongo/collections/024_connect_community_production_hardening.js");
print("✓ Community validators and indexes hardened");

print("Collection 20/20: user_jwt_token");
load("../mongo/collections/020_user_jwt_token.js");
print("✓ user_jwt_token created");

// Verification Report
print("");
print("=================================================================");
print("MONGODB INITIALIZATION COMPLETE");
print("=================================================================");
print("");

// List all collections
var collections = db.getCollectionNames();
print("Collections Summary:");
print("───────────────────────────────────────");

collections.forEach(function(col) {
    var count = db[col].countDocuments();
    var docCount = String(count);
    var padded = docCount + " documents";
    print(col + " " + Array(50 - col.length - padded.length).join(".") + " " + padded);
});

print("");
print("Domain Breakdown:");
print("───────────────────────────────────────");
print("Overview (3 collections):");
print("  • student_mission_control_daily");
print("  • student_compass_intelligence_daily");
print("  • student_learning_health_daily");
print("");
print("Learning Hub (4 collections):");
print("  • class_subject_syllabus");
print("  • learning_resource");
print("  • exam_paper");
print("  • student_learning_progress");
print("");
print("Connect (13 collections):");
print("  • connect_conversation");
print("  • connect_meeting");
print("  • connect_community");
print("  • connect_community_member");
print("  • connect_community_join_request");
print("  • connect_community_post");
print("  • connect_community_comment");
print("  • connect_community_post_like");
print("  • connect_community_discussion");
print("  • connect_community_discussion_reply");
print("  • connect_community_poll");
print("  • connect_community_poll_vote");
print("");
print("Auth (1 collection):");
print("  • user_jwt_token");
print("");
print("Total Collections: " + collections.length);
print("");
print("=================================================================");
print("Next Steps:");
print("  1. Create indexes on Parquet collections");
print("  2. Configure Redis for caching");
print("  3. Sync data from SQL Server");
print("  4. Run FastAPI integration tests");
print("=================================================================");
