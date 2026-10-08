# Thinkigen MongoDB — Student Overview (Compass)

SQL Server remains the ERP system of record.

These collections store **Compass-generated** Student Overview data only:

| Collection | Overview widget |
|------------|-----------------|
| `student_mission_control_daily` | Mission Control: readiness, quote, streak, Start My Day, Compass “suggested for you” checklist rows, optional task-time cache |
| `student_compass_intelligence_daily` | Compass Intelligence tabs: For You, Learning, Focus, Health |
| `student_learning_health_daily` | Learning Health: overall score, status, sub-label, five skills |

## Learning Hub

Curriculum master, resources, papers, and per-student progress. SQL keeps `class_subject` / `subject` / student placement. Course % is **not** on the syllabus; FastAPI computes it from syllabus topics + `student_learning_progress`.

| Collection | Purpose |
|------------|---------|
| `class_subject_syllabus` | Chapter/topic tree per school, branch, year, class, subject |
| `learning_resource` | Video / notes / quiz / book metadata + Blob / YouTube refs |
| `exam_paper` | Class-level Exam Papers UI (tabs, preview/download). No section/student. |
| `student_learning_progress` | Per-student topic status; optional % cache |

## Connect

Communication thread masters, meetings, and live Community content.  
Chat **message bodies**, replies, likes, and read receipts live in **Parquet** (`database/parquet/`).  
Inbox / unread / presence / recent messages / counters live in **Redis** (`database/redis/connect_keys.md`).  
**No SQL Connect tables.** Copy `user_id` / `school_id` / `branch_id` as business keys only.

| Collection | Purpose |
|------------|---------|
| `connect_conversation` | 1:1 / group thread master + last preview |
| `connect_meeting` | Meetings schedule, instructor, agenda, resources |
| `connect_community` | Club / society / group master |
| `connect_community_member` | Membership |
| `connect_community_join_request` | Join requests + invitations |
| `connect_community_post` | Community feed posts |
| `connect_community_comment` | Post comments |
| `connect_community_post_like` | Post likes |
| `connect_community_discussion` | Discussions |
| `connect_community_discussion_reply` | Discussion replies |
| `connect_community_poll` | Polls |
| `connect_community_poll_vote` | Poll votes |

## Auth

Password stays on SQL `security_schema.users` (`password_hash` / lock fields).  
Login key: `users.email_address`.  
One Mongo document per `user_id` (second login replaces the session).  
Store SHA-256 hashes only. TTL is `refresh_expires_at` (~27–30 days), not access expiry (~5–10 minutes).  
Access + refresh tokens: Mongo only — no SQL refresh-token table.

| Collection | Purpose |
|------------|---------|
| `user_jwt_token` | Active ACCESS + REFRESH hashes for one user session |

## Shared documents

| Collection | Purpose |
|------------|---------|
| `thinkigen_documents` | Central metadata for SQL-backed module files stored in Azure Blob Storage. Connect and Learning Hub resource collections remain separate. |

See [database/docs/thinkigen-documents.md](../docs/thinkigen-documents.md) for the schema, lifecycle, indexes, samples, and FastAPI workflow.

**Not stored in Mongo (Connect)**

- Chat / group message history → Parquet `chat_events`
- Unread / presence / recent message cache → Redis
- “I'm Interested” on meetings (feature removed)
- `connect_message` / `connect_conversation_read_state` / `connect_meeting_interest` collections

**Not stored in Mongo (Overview)**

- Classes KPI (timetable + attendance)
- Assignments KPI (assignment + assignment_status)
- Assessment card (next exam_schedule)
- Homework / writing / reading checklist rows
- My Day, Priorities, Announcements, Upcoming Exams

SQL `student_id` (and academic scope IDs) are copied as business keys. There is no Mongo FK to SQL Server.

One Organization = one Mongo database (same isolation as SQL).

## Apply (local)

```javascript
load("database/mongo/collections/001_student_mission_control_daily.js");
load("database/mongo/collections/002_student_compass_intelligence_daily.js");
load("database/mongo/collections/003_student_learning_health_daily.js");
load("database/mongo/collections/004_class_subject_syllabus.js");
load("database/mongo/collections/005_learning_resource.js");
load("database/mongo/collections/006_exam_paper.js");
load("database/mongo/collections/007_student_learning_progress.js");
load("database/mongo/collections/008_connect_conversation.js");
load("database/mongo/collections/009_connect_meeting.js");
load("database/mongo/collections/010_connect_community.js");
load("database/mongo/collections/011_connect_community_member.js");
load("database/mongo/collections/012_connect_community_join_request.js");
load("database/mongo/collections/013_connect_community_post.js");
load("database/mongo/collections/014_connect_community_comment.js");
load("database/mongo/collections/015_connect_community_post_like.js");
load("database/mongo/collections/016_connect_community_discussion.js");
load("database/mongo/collections/017_connect_community_discussion_reply.js");
load("database/mongo/collections/018_connect_community_poll.js");
load("database/mongo/collections/019_connect_community_poll_vote.js");
load("database/mongo/collections/020_user_jwt_token.js");
load("database/mongo/collections/023_thinkigen_documents.js");
```

Or run each file in `mongosh` against the Organization database.

SQL BIGINT IDs must be inserted as `NumberLong`.

## Related docs

| Doc | Path |
|-----|------|
| SQL full table reference | `database/docs/full-table-reference.md` |
| Mongo collections reference | `database/docs/mongodb-collections-reference.md` |
| Chat Parquet schema | `database/parquet/connect_chat_events.md` |
| Community Parquet schema | `database/parquet/connect_community_events.md` |
| Redis key map | `database/redis/connect_keys.md` |
