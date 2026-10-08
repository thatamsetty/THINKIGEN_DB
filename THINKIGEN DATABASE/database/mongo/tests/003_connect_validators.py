"""Contract checks for Connect Mongo validators (no live Mongo required)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COL = ROOT / "collections"

FILES = {
    "conversation": COL / "008_connect_conversation.js",
    "meeting": COL / "009_connect_meeting.js",
    "community": COL / "010_connect_community.js",
    "member": COL / "011_connect_community_member.js",
    "join_request": COL / "012_connect_community_join_request.js",
    "post": COL / "013_connect_community_post.js",
    "comment": COL / "014_connect_community_comment.js",
    "post_like": COL / "015_connect_community_post_like.js",
    "discussion": COL / "016_connect_community_discussion.js",
    "discussion_reply": COL / "017_connect_community_discussion_reply.js",
    "poll": COL / "018_connect_community_poll.js",
    "poll_vote": COL / "019_connect_community_poll_vote.js",
}

# Must never appear as Mongo collections for Connect
FORBIDDEN_COLLECTIONS = [
    'createCollection("connect_message"',
    'createCollection("connect_conversation_read_state"',
    'createCollection("connect_meeting_interest"',
]


def _read(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    if not text.strip():
        raise SystemExit(f"empty file: {path}")
    return text


def _require(src: str, label: str, tokens: list[str]) -> None:
    for token in tokens:
        if token not in src:
            raise SystemExit(f"{label} missing: {token}")


def test_no_forbidden_collections() -> None:
    for path in FILES.values():
        src = _read(path)
        for bad in FORBIDDEN_COLLECTIONS:
            if bad in src:
                raise SystemExit(f"{path.name} must not define: {bad}")


def test_conversation() -> None:
    src = _read(FILES["conversation"])
    _require(
        src,
        "conversation",
        [
            'createCollection("connect_conversation"',
            "$jsonSchema",
            'validationLevel: "strict"',
            "uq_connect_conversation_id",
            '"chat"',
            '"group"',
            "participants",
            "last_message_preview",
            "additionalProperties: false",
        ],
    )


def test_meeting() -> None:
    src = _read(FILES["meeting"])
    _require(
        src,
        "meeting",
        [
            'createCollection("connect_meeting"',
            "uq_connect_meeting_id",
            "ix_connect_meeting_schedule",
            '"virtual"',
            '"in-person"',
            "instructor",
            "agenda",
            "notification_reminder",
        ],
    )
    if "interested" in src.lower() and "I'm Interested" not in src:
        # header may mention feature removed; schema must not store interest
        if "is_interested" in src or "isInterested" in src:
            raise SystemExit("meeting must not store I'm Interested fields")


def test_community() -> None:
    src = _read(FILES["community"])
    _require(
        src,
        "community",
        [
            'createCollection("connect_community"',
            "uq_connect_community_id",
            "ix_connect_community_scope_type",
            '"club"',
            '"society"',
            '"group"',
        ],
    )


def test_member() -> None:
    src = _read(FILES["member"])
    _require(
        src,
        "member",
        [
            'createCollection("connect_community_member"',
            "uq_connect_community_member",
            '"joined"',
            '"moderator"',
            '"owner"',
        ],
    )


def test_join_request() -> None:
    src = _read(FILES["join_request"])
    _require(
        src,
        "join_request",
        [
            'createCollection("connect_community_join_request"',
            "uq_connect_community_join_request_id",
            '"request"',
            '"invitation"',
            '"pending"',
            '"accepted"',
        ],
    )


def test_post() -> None:
    src = _read(FILES["post"])
    _require(
        src,
        "post",
        [
            'createCollection("connect_community_post"',
            "uq_connect_community_post_id",
            "ix_connect_community_post_feed",
            "object_key",
        ],
    )


def test_comment() -> None:
    src = _read(FILES["comment"])
    _require(
        src,
        "comment",
        [
            'createCollection("connect_community_comment"',
            "uq_connect_community_comment_id",
            "ix_connect_community_comment_post",
        ],
    )


def test_post_like() -> None:
    src = _read(FILES["post_like"])
    _require(
        src,
        "post_like",
        [
            'createCollection("connect_community_post_like"',
            "uq_connect_community_post_like",
        ],
    )


def test_discussion() -> None:
    src = _read(FILES["discussion"])
    _require(
        src,
        "discussion",
        [
            'createCollection("connect_community_discussion"',
            "uq_connect_community_discussion_id",
            "ix_connect_community_discussion_feed",
        ],
    )


def test_discussion_reply() -> None:
    src = _read(FILES["discussion_reply"])
    _require(
        src,
        "discussion_reply",
        [
            'createCollection("connect_community_discussion_reply"',
            "uq_connect_community_discussion_reply_id",
            "ix_connect_community_discussion_reply_thread",
        ],
    )


def test_poll() -> None:
    src = _read(FILES["poll"])
    _require(
        src,
        "poll",
        [
            'createCollection("connect_community_poll"',
            "uq_connect_community_poll_id",
            "ix_connect_community_poll_feed",
            "options",
        ],
    )


def test_poll_vote() -> None:
    src = _read(FILES["poll_vote"])
    _require(
        src,
        "poll_vote",
        [
            'createCollection("connect_community_poll_vote"',
            "uq_connect_community_poll_vote",
            "option_id",
        ],
    )


if __name__ == "__main__":
    test_no_forbidden_collections()
    test_conversation()
    test_meeting()
    test_community()
    test_member()
    test_join_request()
    test_post()
    test_comment()
    test_post_like()
    test_discussion()
    test_discussion_reply()
    test_poll()
    test_poll_vote()
    print("003_connect_validators: PASS")
