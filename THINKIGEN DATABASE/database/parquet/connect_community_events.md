# Connect Parquet — community_events

Durable archive / analytics log for **Community** actions.

Mongo remains the live source for feed UI (`connect_community_post`, comments, likes, …).  
Parquet stores append-only history of the same actions.  
Redis caches feed/like counters.

## Path layout

```text
/{org_id}/connect/parquet/community_events/year=YYYY/month=MM/day=DD/part-*.parquet
```

## Event types

| event_type | Meaning |
|---|---|
| `post_created` | New community post |
| `post_reply` | Comment on a post (`parent_id` = post_id) |
| `post_liked` / `post_unliked` | Like toggle on post |
| `reply_liked` / `reply_unliked` | Optional like on a comment/reply |
| `discussion_created` | Discussion thread opened |
| `discussion_reply` | Reply in discussion |
| `poll_created` | Poll created |
| `poll_voted` | User voted |
| `member_joined` | Membership became joined |
| `join_requested` / `invitation_sent` | Join flow audit |
| `join_accepted` / `join_declined` | Join resolution |

## Columns

| Column | Type | Null | Notes |
|---|---|---|---|
| `event_id` | INT64 / STRING | NO | Unique event id |
| `event_type` | STRING | NO | See table above |
| `community_id` | INT64 | NO | Community master id |
| `school_id` | INT64 | NO | Business key |
| `branch_id` | INT64 | YES | Business key |
| `actor_user_id` | INT64 | NO | Who acted |
| `target_id` | INT64/STRING | YES | post_id / comment_id / discussion_id / poll_id |
| `parent_id` | INT64/STRING | YES | Parent post/discussion when nested |
| `option_id` | INT64 | YES | Poll option for votes |
| `content` | STRING | YES | Post/comment/discussion text |
| `attachment_blob_id` | STRING | YES | Image/file blob |
| `attachment_file_name` | STRING | YES | |
| `attachment_mime_type` | STRING | YES | |
| `occurred_at` | TIMESTAMP | NO | UTC |
| `is_deleted` | BOOLEAN | NO | Soft delete |

## Rules

1. Live Community UI reads **Mongo**, not Parquet.
2. Every successful Mongo write that changes community state should enqueue a matching Parquet event.
3. Images/files live in Blob; Parquet/Mongo store `blob_id` only.
4. Partition by day for cheap retention and scans.

## Example rows

```text
post_created | community=101 | actor=701 | content="We won!" | attachment_blob_id=blob_abc
post_reply   | community=101 | actor=702 | parent=1001 | content="Congrats"
post_liked   | community=101 | actor=703 | target=1001
poll_voted   | community=101 | actor=999 | target=3001 | option_id=1
```
