"""Contract checks for user_jwt_token Mongo validator (no live Mongo required)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JWT = ROOT / "collections" / "020_user_jwt_token.js"


def _read(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    if not text.strip():
        raise SystemExit(f"empty file: {path}")
    return text


def test_user_jwt_token() -> None:
    src = _read(JWT)
    for token in [
        'createCollection("user_jwt_token"',
        "$jsonSchema",
        "validationLevel: \"strict\"",
        "uq_user_jwt_token_user",
        "uq_user_jwt_access_hash",
        "uq_user_jwt_refresh_hash",
        "ttl_user_jwt_refresh_expires",
        "access_token_hash",
        "refresh_token_hash",
        "access_expires_at",
        "refresh_expires_at",
        "expireAfterSeconds: 0",
        "user_id",
    ]:
        if token not in src:
            raise SystemExit(f"user_jwt_token missing: {token}")
    if "password_hash" in src:
        raise SystemExit("user_jwt_token must not store password_hash")


if __name__ == "__main__":
    test_user_jwt_token()
    print("004_user_jwt_token: PASS")
