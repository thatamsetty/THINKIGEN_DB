# Connect Parquet — chat_events

Durable history for **normal chat** and **group chat**.

Mongo keeps `connect_conversation` only.  
Redis keeps inbox / unread / recent messages / presence / like counters.  
Blob keeps file bytes (`blob_id` in events).

## Path layout

```text
/{org_id}/connect/parquet/chat_events/year=YYYY/month=MM/day=DD/part-*.parquet
```

## Event types

| event_type | Meaning |
|---|---|
| `message_sent` | New 1:1 or group message |
| `message_reply` | Reply to a message (`parent_id` = message_id) |
| `message_liked` | Like on a message |
| `message_unliked` | Remove like |
| `message_read` | Read receipt (per user) |

## Columns

| Column | Type | Null | Notes |
|---|---|---|---|
| `event_id` | INT64 / STRING | NO | Unique event id |
| `event_type` | STRING | NO | See table above |
| `channel_type` | STRING | NO | `direct` \| `group` |
| `conversation_id` | STRING | NO | Matches Mongo conversation_id |
| `school_id` | INT64 | NO | Business key |
| `branch_id` | INT64 | NO | Business key |
| `actor_user_id` | INT64 | NO | Who performed the action |
| `receiver_user_id` | INT64 | YES | Required for direct `message_sent`; null for group |
| `parent_id` | STRING/INT64 | YES | Target message for reply/like/read |
| `content` | STRING | YES | Text body (messages/replies) |
| `attachment_blob_id` | STRING | YES | Blob ref |
| `attachment_file_name` | STRING | YES | |
| `attachment_mime_type` | STRING | YES | |
| `attachment_file_size_label` | STRING | YES | |
| `occurred_at` | TIMESTAMP | NO | Event time UTC |
| `is_deleted` | BOOLEAN | NO | Soft delete |

## Rules

1. Append-only. Prefer new events over in-place updates.
2. Group messages: set `receiver_user_id = null`; members come from Mongo conversation participants.
3. Read/unread truth: `message_read` events (per user). Redis caches unread badges.
4. Do not store UI-only `date-separator` or `incoming`/`outgoing` labels.
5. One Organization = one Blob/Parquet prefix (same isolation as SQL/Mongo).

## Example rows

```text
message_sent | direct | conv_12 | actor=101 | receiver=202 | content="Hello" | occurred_at=...
message_reply | group | group_55 | actor=101 | parent=msg_9001 | content="I agree"
message_liked | direct | conv_12 | actor=202 | parent=msg_9001
message_read | direct | conv_12 | actor=202 | parent=msg_9005
```
