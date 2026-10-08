# Connect Redis — hot keys

Redis is the live cache for Connect.  
Mongo/Parquet remain durable sources. Rebuild Redis from them on miss/flush.

## Communication (normal + group chat)

| Key | Type | Purpose |
|---|---|---|
| `connect:inbox:{user_id}` | ZSET score=`last_message_at` | Inbox ordered by activity |
| `connect:conv:{conversation_id}:meta` | HASH | Last preview, type, title cache |
| `connect:conv:{conversation_id}:msgs` | LIST/STREAM | Recent N messages |
| `connect:unread:{user_id}:{conversation_id}` | INT | Unread badge |
| `connect:presence:{user_id}` | STRING + TTL | Online/offline |
| `connect:msg:{message_id}:likes` | SET | Users who liked a chat message |
| `connect:msg:{message_id}:like_count` | INT | Like counter |

### Write flow (message)
1. Append Parquet `chat_events` row  
2. Update Mongo `connect_conversation` last preview  
3. Update Redis inbox + recent msgs + unread for receivers  

### Read flow
1. Inbox/unread from Redis  
2. Recent thread from Redis  
3. Older history from Parquet by `conversation_id` + date  

## Community

| Key | Type | Purpose |
|---|---|---|
| `connect:community:{community_id}:feed` | ZSET score=`created_at` | Recent post ids |
| `connect:post:{post_id}:likes` | SET | Users who liked post |
| `connect:post:{post_id}:like_count` | INT | Like counter |
| `connect:poll:{poll_id}:votes` | HASH | option_id → count |
| `connect:poll:{poll_id}:voters` | SET | Users who already voted |
| `connect:trending:communities` | ZSET/LIST | Optional trending cache |

### Write flow (post/like/vote)
1. Write Mongo live document  
2. Append Parquet `community_events`  
3. Update Redis feed/counters  

## TTL guidance

| Key family | Suggested TTL |
|---|---|
| Presence | 30–120 seconds |
| Recent messages | 7–30 days (or eviction by max length) |
| Inbox / unread | No short TTL; rebuild on miss |
| Feed / like caches | Hours to days; rebuild on miss |

## Not in Redis

- Full durable chat history → Parquet  
- Community masters / membership → Mongo  
- Meeting masters → Mongo  
- File bytes → Blob  
