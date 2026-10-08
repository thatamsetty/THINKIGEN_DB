# Community Validation Contract

MongoDB stores the ten Community collections in the organization database. SQL Server remains authoritative for users and tenant ownership. Numeric SQL BIGINT identifiers are represented as BSON `long` (`NumberLong(...)`) for new writes. Existing `int` values are accepted by the validators for compatibility; no automatic ID conversion is performed.

## Application-level relationships

FastAPI must reject orphan or cross-tenant writes and must derive identity fields from the authenticated session:

- Member, join request, post, discussion, and poll `community_id` must reference an existing Community.
- Member and join request `school_id` must match the Community; branch consistency must be checked when applicable.
- A post must reference an active Community, match its school, and be created by the authenticated user with the required membership/permission.
- A like must reference an active post, match its Community school, and be idempotent for `(post_id, user_id)`.
- A comment must reference an existing post; `comment.community_id` and `comment.school_id` must match the post.
- A discussion reply must reference an active discussion; `reply.community_id` and `reply.school_id` must match it.
- A poll vote must reference an active, unexpired poll, match its school, use an existing embedded `option_id`, and be unique for `(poll_id, user_id)`.
- Only authorized active members may post, comment, reply, like, or vote; owner/moderator/admin permissions are resolved by FastAPI.
- `owner_user_id`, `author_user_id`, `user_id`, `created_by`, `updated_by`, and `invited_by_user_id` are authoritative references. Display names and roles are staleable snapshots only.

Acceptance of a request must validate the pending state, reactivate or create the unique membership, clear `left_at`, update the request, and adjust `member_count` as one coordinated service operation.

## Counters and lifecycle

- `member_count` is derived from joined records in `connect_community_member`.
- `like_count` is derived from `connect_community_post_like`.
- `total_votes` and each embedded `options[].vote_count` are derived from `connect_community_poll_vote`.
- Counter updates must use idempotent atomic operations or transactions and must never go below zero.
- Membership rejoin updates the existing `(community_id, user_id)` document to `joined` with `left_at: null`; `left` and `removed` require a date.
- `is_active` controls normal visibility. Historical content and activity are retained unless a separate business retention rule says otherwise. Poll expiry is determined from `expires_at`, not only `is_active`.

## Storage

Post media and attachments remain embedded metadata arrays. Azure Blob Storage owns internal bytes; MongoDB stores stable `object_key` metadata and never binary data or permanent SAS URLs. FastAPI authorizes access and generates a short-lived SAS URL. `external_url` is reserved for genuinely external content. Where a file participates in the centralized document architecture, use `thinkigen_documents` metadata and its `storage.container` plus `storage.object_key` instead of another file registry.

## Migration safety

`024_connect_community_production_hardening.js` uses `collMod`, strict/error validation, and safe index creation. It does not drop collections, delete documents, or change IDs. It replaces the legacy request-type-scoped pending index with one partial unique index for `(community_id, user_id)` and will fail rather than silently discard conflicting pending records. Existing `int` identifiers remain valid; conversion to BSON `long` is an explicit future migration only.
