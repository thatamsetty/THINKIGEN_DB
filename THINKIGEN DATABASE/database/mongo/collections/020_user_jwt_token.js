/*
    Collection: user_jwt_token
    Purpose:    Multi-login JWT session tracking per SQL user

    SQL link:   security_schema.users.user_id
    Password:   stays on security_schema.users (password_hash / lock fields)
    Tokens:     Mongo only — no SQL refresh-token table

    Security model:
    - JSON Web Tokens use HS256 with JWT_SECRET_KEY
    - Passwords use bcrypt in SQL
    - Refresh tokens in Mongo are stored as SHA-256 hashes only
    - Access token is not stored raw in Mongo

    Lifetimes (FastAPI sets the dates):
    - access_expires_at  ≈ 5–10 minutes
    - refresh_expires_at ≈ 27–30 days

    Design:
    - One document = one active login session
    - Multiple sessions per same user are allowed
    - session_id uniquely identifies a session
    - refresh_token_hash is unique to prevent token reuse collisions
*/

if (!db.getCollectionNames().includes("user_jwt_token")) {
    db.createCollection("user_jwt_token", {
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "session_id",
                    "user_id",
                    "device_id",
                    "token_family_id",
                    "access_jti",
                    "refresh_jti",
                    "refresh_token_hash",
                    "access_expires_at",
                    "refresh_expires_at",
                    "status",
                    "is_revoked",
                    "created_at",
                    "updated_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    session_id: { bsonType: "string", minLength: 10, maxLength: 128 },
                    user_id: { bsonType: ["int", "long"], minimum: 1 },
                    device_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    token_family_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    access_jti: { bsonType: "string", minLength: 10, maxLength: 128 },
                    refresh_jti: { bsonType: "string", minLength: 10, maxLength: 128 },
                    refresh_token_hash: { bsonType: "string", minLength: 64, maxLength: 64 },
                    access_expires_at: { bsonType: "date" },
                    refresh_expires_at: { bsonType: "date" },
                    status: { bsonType: "string", enum: ["active", "revoked", "expired"] },
                    is_revoked: { bsonType: "bool" },
                    revoked_at: { bsonType: ["date", "null"] },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" },
                    created_ip: { bsonType: ["string", "null"], maxLength: 45 },
                    user_agent: { bsonType: ["string", "null"], maxLength: 500 }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
} else {
    db.runCommand({
        collMod: "user_jwt_token",
        validator: {
            $jsonSchema: {
                bsonType: "object",
                required: [
                    "session_id",
                    "user_id",
                    "device_id",
                    "token_family_id",
                    "access_jti",
                    "refresh_jti",
                    "refresh_token_hash",
                    "access_expires_at",
                    "refresh_expires_at",
                    "status",
                    "is_revoked",
                    "created_at",
                    "updated_at"
                ],
                additionalProperties: false,
                properties: {
                    _id: { bsonType: "objectId" },
                    session_id: { bsonType: "string", minLength: 10, maxLength: 128 },
                    user_id: { bsonType: ["int", "long"], minimum: 1 },
                    device_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    token_family_id: { bsonType: "string", minLength: 1, maxLength: 128 },
                    access_jti: { bsonType: "string", minLength: 10, maxLength: 128 },
                    refresh_jti: { bsonType: "string", minLength: 10, maxLength: 128 },
                    refresh_token_hash: { bsonType: "string", minLength: 64, maxLength: 64 },
                    access_expires_at: { bsonType: "date" },
                    refresh_expires_at: { bsonType: "date" },
                    status: { bsonType: "string", enum: ["active", "revoked", "expired"] },
                    is_revoked: { bsonType: "bool" },
                    revoked_at: { bsonType: ["date", "null"] },
                    created_at: { bsonType: "date" },
                    updated_at: { bsonType: "date" },
                    created_ip: { bsonType: ["string", "null"], maxLength: 45 },
                    user_agent: { bsonType: ["string", "null"], maxLength: 500 }
                }
            }
        },
        validationLevel: "strict",
        validationAction: "error"
    });
}

if (!db.user_jwt_token.getIndexes().some(function (idx) {
    return idx.name === "uq_user_jwt_session_id";
})) {
    db.user_jwt_token.createIndex(
        { session_id: 1 },
        { unique: true, name: "uq_user_jwt_session_id" }
    );
}

if (!db.user_jwt_token.getIndexes().some(function (idx) {
    return idx.name === "ix_user_jwt_user_status";
})) {
    db.user_jwt_token.createIndex(
        { user_id: 1, status: 1 },
        { name: "ix_user_jwt_user_status" }
    );
}

if (!db.user_jwt_token.getIndexes().some(function (idx) {
    return idx.name === "ix_user_jwt_user_refresh_expiry";
})) {
    db.user_jwt_token.createIndex(
        { user_id: 1, refresh_expires_at: 1 },
        { name: "ix_user_jwt_user_refresh_expiry" }
    );
}

if (!db.user_jwt_token.getIndexes().some(function (idx) {
    return idx.name === "uq_user_jwt_refresh_hash";
})) {
    db.user_jwt_token.createIndex(
        { refresh_token_hash: 1 },
        { unique: true, name: "uq_user_jwt_refresh_hash" }
    );
}

if (!db.user_jwt_token.getIndexes().some(function (idx) {
    return idx.name === "uq_user_jwt_access_jti";
})) {
    db.user_jwt_token.createIndex(
        { access_jti: 1 },
        { unique: true, name: "uq_user_jwt_access_jti" }
    );
}

if (!db.user_jwt_token.getIndexes().some(function (idx) {
    return idx.name === "uq_user_jwt_refresh_jti";
})) {
    db.user_jwt_token.createIndex(
        { refresh_jti: 1 },
        { unique: true, name: "uq_user_jwt_refresh_jti" }
    );
}

if (!db.user_jwt_token.getIndexes().some(function (idx) {
    return idx.name === "ttl_user_jwt_refresh_expires";
})) {
    db.user_jwt_token.createIndex(
        { refresh_expires_at: 1 },
        { expireAfterSeconds: 0, name: "ttl_user_jwt_refresh_expires" }
    );
}
