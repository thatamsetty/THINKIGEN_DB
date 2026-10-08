/* ========================================================================
   THINKIGEN SCHOOL ERP
   MongoDB Collection: connect_meeting
   ========================================================================

   PURPOSE
   -------
   Connect -> Meeting Master

   MongoDB stores:
     - meeting master/configuration
     - organizer snapshot
     - target snapshot
     - meeting type
     - schedule
     - external meeting details
     - agenda
     - resources
     - reminder configuration
     - audit fields

   Thinkigen DOES NOT host video/audio.

   SQL SERVER = SOURCE OF TRUTH
   ----------------------------
   SQL Server remains authoritative for:

     - users
     - authentication
     - active/inactive status
     - school membership
     - branch membership
     - academic-year relationship
     - user_type / role
     - authorization

   MongoDB stores snapshots of organizer/target information.

   BACKEND MUST VALIDATE
   ---------------------
     1. User exists in SQL Server
     2. User is active
     3. User belongs to school
     4. User belongs to branch
     5. User belongs to academic year
     6. Organizer is authorized
     7. Organizer role matches SQL user_type
     8. Target role matches SQL user_type
     9. Target users are unique
    10. Organizer is not a target
    11. Status transitions are valid
    12. View/update/cancel permissions are valid
    13. Reminder business rules are valid

   IMPORTANT
   ---------
   - NO mock data
   - NO SQL user data
   - NO passwords
   - NO access tokens
   - NO secrets
   - Existing collection is NEVER dropped
   - Existing indexes are NEVER silently dropped
   - Existing invalid data causes migration to STOP
   - Validator uses strict/error
*/


/* ========================================================================
   CONFIGURATION
   ======================================================================== */

var COLLECTION_NAME = "connect_meeting";


/* ========================================================================
   ENUMS
   ======================================================================== */

var VALID_ROLES = [
    "STUDENT",
    "TEACHER",
    "PRINCIPAL",
    "MANAGEMENT",
    "FINANCE",
    "TRANSPORT",
    "STAFF",
    "PARENT",
    "OTHER_AUTHORIZED_ROLE",
    "ADMIN"
];

var VALID_STATUSES = [
    "scheduled",
    "pending",
    "ongoing",
    "completed",
    "cancelled"
];

var VALID_MEETING_TYPES = [
    "VIRTUAL",
    "IN_PERSON"
];

var VALID_RESOURCE_TYPES = [
    "document",
    "link"
];

var VALID_TARGET_TYPES = [
    "USER"
];

var VALID_PLATFORMS = [
    "GOOGLE_MEET"
];


/* ========================================================================
   ALLOWED FIELD DEFINITIONS
   ======================================================================== */

var ROOT_FIELDS = [
    "_id",
    "meeting_id",
    "school_id",
    "branch_id",
    "academic_year_id",
    "title",
    "status",
    "meeting_type",
    "scheduled_at",
    "duration_minutes",
    "organizer",
    "targets",
    "agenda",
    "online_details",
    "location",
    "room_no",
    "resources",
    "notification_reminder",
    "is_active",
    "created_at",
    "updated_at",
    "created_by",
    "updated_by"
];

var ORGANIZER_FIELDS = [
    "user_id",
    "name",
    "role",
    "email"
];

var TARGET_FIELDS = [
    "target_type",
    "role",
    "user_ids"
];

var AGENDA_FIELDS = [
    "agenda_id",
    "title"
];

var ONLINE_FIELDS = [
    "platform",
    "meeting_url"
];

var RESOURCE_FIELDS = [
    "resource_id",
    "title",
    "resource_type",
    "object_key",
    "url"
];

var REMINDER_FIELDS = [
    "enabled",
    "minutes_before"
];


/* ========================================================================
   MONGODB VALIDATOR
   ======================================================================== */

var validator = {

    $jsonSchema: {

        bsonType: "object",

        required: [
            "meeting_id",
            "school_id",
            "branch_id",
            "academic_year_id",
            "title",
            "status",
            "meeting_type",
            "scheduled_at",
            "duration_minutes",
            "organizer",
            "targets",
            "is_active",
            "created_at",
            "updated_at"
        ],

        additionalProperties: false,


        /* =================================================================
           MEETING TYPE CONDITIONAL RULES
           ================================================================= */

        anyOf: [

            /* -------------------------------------------------------------
               VIRTUAL
               ------------------------------------------------------------- */

            {
                properties: {

                    meeting_type: {
                        bsonType: "string",
                        enum: [
                            "VIRTUAL"
                        ]
                    },

                    online_details: {

                        bsonType: "object",

                        required: [
                            "platform",
                            "meeting_url"
                        ],

                        additionalProperties: false,

                        properties: {

                            platform: {
                                bsonType: "string",
                                enum: [
                                    "GOOGLE_MEET"
                                ]
                            },

                            meeting_url: {
                                bsonType: "string",
                                minLength: 1,
                                maxLength: 2048
                            }
                        }
                    },

                    location: {
                        bsonType: "null"
                    },

                    room_no: {
                        bsonType: "null"
                    }
                },

                required: [
                    "online_details",
                    "location",
                    "room_no"
                ]
            },


            /* -------------------------------------------------------------
               IN PERSON
               ------------------------------------------------------------- */

            {
                properties: {

                    meeting_type: {
                        bsonType: "string",
                        enum: [
                            "IN_PERSON"
                        ]
                    },

                    online_details: {
                        bsonType: "null"
                    },

                    location: {
                        bsonType: "string",
                        minLength: 1,
                        maxLength: 200
                    },

                    room_no: {
                        bsonType: [
                            "string",
                            "null"
                        ],
                        minLength: 1,
                        maxLength: 100
                    }
                },

                required: [
                    "location",
                    "online_details"
                ]
            }
        ],


        /* =================================================================
           ROOT PROPERTIES
           ================================================================= */

        properties: {

            _id: {
                bsonType: [
                    "objectId",
                    "string"
                ]
            },

            meeting_id: {
                bsonType: [
                    "int",
                    "long"
                ],
                minimum: 1
            },

            school_id: {
                bsonType: [
                    "int",
                    "long"
                ],
                minimum: 1
            },

            branch_id: {
                bsonType: [
                    "int",
                    "long"
                ],
                minimum: 1
            },

            academic_year_id: {
                bsonType: [
                    "int",
                    "long"
                ],
                minimum: 1
            },

            title: {
                bsonType: "string",
                minLength: 1,
                maxLength: 300
            },

            status: {
                bsonType: "string",
                enum: VALID_STATUSES
            },

            meeting_type: {
                bsonType: "string",
                enum: VALID_MEETING_TYPES
            },

            scheduled_at: {
                bsonType: "date"
            },

            duration_minutes: {
                bsonType: [
                    "int",
                    "long"
                ],
                minimum: 1,
                maximum: 1440
            },


            /* =============================================================
               ORGANIZER
               ============================================================= */

            organizer: {

                bsonType: "object",

                required: [
                    "user_id",
                    "name",
                    "role",
                    "email"
                ],

                additionalProperties: false,

                properties: {

                    user_id: {
                        bsonType: [
                            "int",
                            "long"
                        ],
                        minimum: 1
                    },

                    name: {
                        bsonType: "string",
                        minLength: 1,
                        maxLength: 200
                    },

                    role: {
                        bsonType: "string",
                        enum: VALID_ROLES
                    },

                    email: {
                        bsonType: "string",
                        minLength: 1,
                        maxLength: 254
                    }
                }
            },


            /* =============================================================
               TARGETS
               ============================================================= */

            targets: {

                bsonType: "array",

                minItems: 1,

                items: {

                    bsonType: "object",

                    required: [
                        "target_type",
                        "role",
                        "user_ids"
                    ],

                    additionalProperties: false,

                    properties: {

                        target_type: {
                            bsonType: "string",
                            enum: VALID_TARGET_TYPES
                        },

                        role: {
                            bsonType: "string",
                            enum: VALID_ROLES
                        },

                        user_ids: {

                            bsonType: "array",

                            minItems: 1,

                            items: {

                                bsonType: [
                                    "int",
                                    "long"
                                ],

                                minimum: 1
                            }
                        }
                    }
                }
            },


            /* =============================================================
               AGENDA
               ============================================================= */

            agenda: {

                bsonType: [
                    "array",
                    "null"
                ],

                items: {

                    bsonType: "object",

                    required: [
                        "agenda_id",
                        "title"
                    ],

                    additionalProperties: false,

                    properties: {

                        agenda_id: {
                            bsonType: [
                                "int",
                                "long"
                            ],
                            minimum: 1
                        },

                        title: {
                            bsonType: "string",
                            minLength: 1,
                            maxLength: 300
                        }
                    }
                }
            },


            /* =============================================================
               ONLINE DETAILS
               ============================================================= */

            online_details: {

                bsonType: [
                    "object",
                    "null"
                ],

                additionalProperties: false,

                properties: {

                    platform: {
                        bsonType: "string",
                        enum: VALID_PLATFORMS
                    },

                    meeting_url: {
                        bsonType: "string",
                        minLength: 1,
                        maxLength: 2048
                    }
                }
            },


            /* =============================================================
               LOCATION
               ============================================================= */

            location: {

                bsonType: [
                    "string",
                    "null"
                ],

                minLength: 1,
                maxLength: 200
            },


            /* =============================================================
               ROOM
               ============================================================= */

            room_no: {

                bsonType: [
                    "string",
                    "null"
                ],

                minLength: 1,
                maxLength: 100
            },


            /* =============================================================
               RESOURCES
               ============================================================= */

            resources: {

                bsonType: [
                    "array",
                    "null"
                ],

                items: {

                    bsonType: "object",

                    required: [
                        "resource_id",
                        "title",
                        "resource_type"
                    ],

                    additionalProperties: false,

                    properties: {

                        resource_id: {
                            bsonType: [
                                "int",
                                "long"
                            ],
                            minimum: 1
                        },

                        title: {
                            bsonType: "string",
                            minLength: 1,
                            maxLength: 300
                        },

                        resource_type: {
                            bsonType: "string",
                            enum: VALID_RESOURCE_TYPES
                        },

                        object_key: {

                            bsonType: [
                                "string",
                                "null"
                            ],

                            minLength: 1,
                            maxLength: 2048
                        },

                        url: {

                            bsonType: [
                                "string",
                                "null"
                            ],

                            minLength: 1,
                            maxLength: 2048
                        }
                    },


                    /* -----------------------------------------------------
                       DOCUMENT / LINK CONDITIONAL RULE
                       ----------------------------------------------------- */

                    anyOf: [

                        {
                            properties: {

                                resource_type: {
                                    enum: [
                                        "document"
                                    ]
                                },

                                object_key: {
                                    bsonType: "string",
                                    minLength: 1,
                                    maxLength: 2048
                                },

                                url: {
                                    bsonType: "null"
                                }
                            },

                            required: [
                                "object_key",
                                "url"
                            ]
                        },


                        {
                            properties: {

                                resource_type: {
                                    enum: [
                                        "link"
                                    ]
                                },

                                object_key: {
                                    bsonType: "null"
                                },

                                url: {
                                    bsonType: "string",
                                    minLength: 1,
                                    maxLength: 2048
                                }
                            },

                            required: [
                                "object_key",
                                "url"
                            ]
                        }
                    ]
                }
            },


            /* =============================================================
               NOTIFICATION REMINDER
               ============================================================= */

            notification_reminder: {

                bsonType: [
                    "object",
                    "null"
                ],

                required: [
                    "enabled"
                ],

                additionalProperties: false,

                properties: {

                    enabled: {
                        bsonType: "bool"
                    },

                    minutes_before: {
                        bsonType: [
                            "int",
                            "long",
                            "null"
                        ],
                        minimum: 1
                    }
                },


                anyOf: [

                    /* -----------------------------------------------------
                       REMINDER DISABLED
                       ----------------------------------------------------- */

                    {
                        properties: {

                            enabled: {
                                bsonType: "bool",
                                enum: [
                                    false
                                ]
                            }
                        }
                    },


                    /* -----------------------------------------------------
                       REMINDER ENABLED
                       ----------------------------------------------------- */

                    {
                        properties: {

                            enabled: {
                                bsonType: "bool",
                                enum: [
                                    true
                                ]
                            },

                            minutes_before: {
                                bsonType: [
                                    "int",
                                    "long"
                                ],
                                minimum: 1
                            }
                        },

                        required: [
                            "minutes_before"
                        ]
                    }
                ]
            },


            /* =============================================================
               AUDIT
               ============================================================= */

            is_active: {
                bsonType: "bool"
            },

            created_at: {
                bsonType: "date"
            },

            updated_at: {
                bsonType: "date"
            },

            created_by: {
                bsonType: [
                    "int",
                    "long",
                    "null"
                ],
                minimum: 1
            },

            updated_by: {
                bsonType: [
                    "int",
                    "long",
                    "null"
                ],
                minimum: 1
            }
        }
    }
};


/* ========================================================================
   GENERAL HELPERS
   ======================================================================== */

function fail(message) {

    throw new Error(message);
}


function hasOwn(obj, field) {

    return Object.prototype.hasOwnProperty.call(
        obj,
        field
    );
}


/*
   Hardened plain-object detection.

   BSON special values are explicitly excluded so values such as:
     - ObjectId
     - Int32
     - Long
     - Decimal128
     - Binary
     - Timestamp
     - DBRef
     - BSON Symbol
     - MinKey
     - MaxKey

   are never treated as ordinary application objects.

   We intentionally do NOT depend on:
       Object.getPrototypeOf(value) === Object.prototype

   because mongosh/BSON runtime objects can have shell-specific
   prototypes.
*/

function isBsonSpecialType(value) {

    if (
        value === null ||
        value === undefined ||
        typeof value !== "object"
    ) {
        return false;
    }


    if (
        typeof value._bsontype === "string"
    ) {
        return true;
    }


    if (
        typeof BSON !== "undefined"
    ) {

        if (
            typeof BSON.ObjectId !== "undefined" &&
            value instanceof BSON.ObjectId
        ) {
            return true;
        }

        if (
            typeof BSON.Int32 !== "undefined" &&
            value instanceof BSON.Int32
        ) {
            return true;
        }

        if (
            typeof BSON.Long !== "undefined" &&
            value instanceof BSON.Long
        ) {
            return true;
        }

        if (
            typeof BSON.Decimal128 !== "undefined" &&
            value instanceof BSON.Decimal128
        ) {
            return true;
        }

        if (
            typeof BSON.Binary !== "undefined" &&
            value instanceof BSON.Binary
        ) {
            return true;
        }

        if (
            typeof BSON.Timestamp !== "undefined" &&
            value instanceof BSON.Timestamp
        ) {
            return true;
        }

        if (
            typeof BSON.DBRef !== "undefined" &&
            value instanceof BSON.DBRef
        ) {
            return true;
        }

        if (
            typeof BSON.MinKey !== "undefined" &&
            value instanceof BSON.MinKey
        ) {
            return true;
        }

        if (
            typeof BSON.MaxKey !== "undefined" &&
            value instanceof BSON.MaxKey
        ) {
            return true;
        }
    }


    return false;
}


function isPlainObject(value) {

    return (
        value !== null &&
        typeof value === "object" &&
        !Array.isArray(value) &&
        !(value instanceof Date) &&
        !isBsonSpecialType(value)
    );
}


function isNullOrUndefined(value) {

    return (
        value === null ||
        value === undefined
    );
}


/* ========================================================================
   EXACT FIELD VALIDATION
   ======================================================================== */

function assertExactKeys(
    obj,
    allowedFields,
    fieldName,
    docId
) {

    Object.keys(obj).forEach(
        function (key) {

            if (
                allowedFields.indexOf(key) === -1
            ) {

                fail(
                    "MIGRATION STOPPED: unexpected field '" +
                    fieldName +
                    "." +
                    key +
                    "' | Doc: " +
                    docId
                );
            }
        }
    );
}


/* ========================================================================
   BSON INTEGER HELPERS
   ======================================================================== */

function isBsonInteger(value) {

    if (
        value === null ||
        value === undefined
    ) {
        return false;
    }


    /* mongosh BSON classes */

    if (
        typeof BSON !== "undefined" &&
        typeof BSON.Int32 !== "undefined" &&
        value instanceof BSON.Int32
    ) {
        return true;
    }


    if (
        typeof BSON !== "undefined" &&
        typeof BSON.Long !== "undefined" &&
        value instanceof BSON.Long
    ) {
        return true;
    }


    /* legacy BSON */

    if (
        value &&
        typeof value === "object"
    ) {

        if (
            value._bsontype === "Int32" ||
            value._bsontype === "int"
        ) {
            return true;
        }

        if (
            value._bsontype === "Long" ||
            value._bsontype === "long"
        ) {
            return true;
        }
    }

    return false;
}


function integerToString(value) {

    if (!isBsonInteger(value)) {
        return String(value);
    }

    if (
        typeof value.toString === "function"
    ) {
        return value.toString();
    }

    return String(value);
}


function assertBsonInteger(
    value,
    fieldName,
    docId
) {

    if (!isBsonInteger(value)) {

        fail(
            "MIGRATION STOPPED: " +
            fieldName +
            " must be BSON Int32 or BSON Long | Doc: " +
            docId
        );
    }


    var textValue =
        integerToString(value);


    if (
        !/^[0-9]+$/.test(textValue) ||
        /^0+$/.test(textValue)
    ) {

        fail(
            "MIGRATION STOPPED: " +
            fieldName +
            " must be a positive BSON integer | Doc: " +
            docId
        );
    }
}


/*
   Used for bounded integers such as duration_minutes.

   We only convert after confirming the value is BSON integer
   and that it is within JavaScript safe integer range.
*/

function assertBsonIntegerRange(
    value,
    fieldName,
    docId,
    minimum,
    maximum
) {

    assertBsonInteger(
        value,
        fieldName,
        docId
    );

    var textValue =
        integerToString(value);

    var numericValue =
        Number(textValue);

    if (
        !Number.isSafeInteger(numericValue)
    ) {

        fail(
            "MIGRATION STOPPED: " +
            fieldName +
            " exceeds safe integer range | Doc: " +
            docId
        );
    }


    if (
        numericValue < minimum ||
        numericValue > maximum
    ) {

        fail(
            "MIGRATION STOPPED: " +
            fieldName +
            " must be between " +
            minimum +
            " and " +
            maximum +
            " | Doc: " +
            docId
        );
    }
}


/* ========================================================================
   SCALAR HELPERS
   ======================================================================== */

function assertString(
    value,
    fieldName,
    docId,
    minLength,
    maxLength
) {

    if (
        typeof value !== "string"
    ) {

        fail(
            "MIGRATION STOPPED: " +
            fieldName +
            " must be a string | Doc: " +
            docId
        );
    }


    if (
        value.length < minLength ||
        value.length > maxLength
    ) {

        fail(
            "MIGRATION STOPPED: " +
            fieldName +
            " length must be between " +
            minLength +
            " and " +
            maxLength +
            " | Doc: " +
            docId
        );
    }


    if (
        minLength > 0 &&
        value.trim() === ""
    ) {

        fail(
            "MIGRATION STOPPED: " +
            fieldName +
            " cannot be empty/whitespace | Doc: " +
            docId
        );
    }
}


function assertDate(
    value,
    fieldName,
    docId
) {

    if (
        !(value instanceof Date) ||
        isNaN(value.getTime())
    ) {

        fail(
            "MIGRATION STOPPED: " +
            fieldName +
            " must be a valid BSON Date | Doc: " +
            docId
        );
    }
}


function assertBoolean(
    value,
    fieldName,
    docId
) {

    if (
        typeof value !== "boolean"
    ) {

        fail(
            "MIGRATION STOPPED: " +
            fieldName +
            " must be boolean | Doc: " +
            docId
        );
    }
}


function assertEnum(
    value,
    fieldName,
    allowed,
    docId
) {

    if (
        allowed.indexOf(value) === -1
    ) {

        fail(
            "MIGRATION STOPPED: invalid " +
            fieldName +
            " '" +
            value +
            "' | Doc: " +
            docId
        );
    }
}


/* ========================================================================
   IDENTITY / _id VALIDATION
   ======================================================================== */

function validateDocumentId(
    doc,
    docId
) {

    if (
        !hasOwn(doc, "_id")
    ) {
        return;
    }


    var value = doc._id;


    if (
        typeof value === "string"
    ) {

        return;
    }


    if (
        value &&
        typeof value === "object" &&
        (
            value._bsontype === "ObjectId" ||
            (
                typeof BSON !== "undefined" &&
                typeof BSON.ObjectId !== "undefined" &&
                value instanceof BSON.ObjectId
            )
        )
    ) {

        return;
    }


    fail(
        "MIGRATION STOPPED: _id must be ObjectId or string | Doc: " +
        docId
    );
}


/* ========================================================================
   EXISTING DOCUMENT VALIDATION
   ======================================================================== */

function validateExistingDocument(doc) {

    var docId = String(doc._id);


    /* ====================================================================
       ROOT OBJECT
       ==================================================================== */

    if (
        !isPlainObject(doc)
    ) {

        fail(
            "MIGRATION STOPPED: document must be object | Doc: " +
            docId
        );
    }


    assertExactKeys(
        doc,
        ROOT_FIELDS,
        "root",
        docId
    );


    validateDocumentId(
        doc,
        docId
    );


    /* ====================================================================
       REQUIRED ROOT FIELDS
       ==================================================================== */

    var requiredRootFields = [
        "meeting_id",
        "school_id",
        "branch_id",
        "academic_year_id",
        "title",
        "status",
        "meeting_type",
        "scheduled_at",
        "duration_minutes",
        "organizer",
        "targets",
        "is_active",
        "created_at",
        "updated_at"
    ];


    requiredRootFields.forEach(
        function (field) {

            if (
                !hasOwn(doc, field)
            ) {

                fail(
                    "MIGRATION STOPPED: missing required field '" +
                    field +
                    "' | Doc: " +
                    docId
                );
            }
        }
    );


    /* ====================================================================
       ROOT INTEGER FIELDS
       ==================================================================== */

    assertBsonInteger(
        doc.meeting_id,
        "meeting_id",
        docId
    );

    assertBsonInteger(
        doc.school_id,
        "school_id",
        docId
    );

    assertBsonInteger(
        doc.branch_id,
        "branch_id",
        docId
    );

    assertBsonInteger(
        doc.academic_year_id,
        "academic_year_id",
        docId
    );


    /* ====================================================================
       ROOT SCALARS
       ==================================================================== */

    assertString(
        doc.title,
        "title",
        docId,
        1,
        300
    );


    assertEnum(
        doc.status,
        "status",
        VALID_STATUSES,
        docId
    );


    assertEnum(
        doc.meeting_type,
        "meeting_type",
        VALID_MEETING_TYPES,
        docId
    );


    assertDate(
        doc.scheduled_at,
        "scheduled_at",
        docId
    );


    assertBsonIntegerRange(
        doc.duration_minutes,
        "duration_minutes",
        docId,
        1,
        1440
    );


    assertBoolean(
        doc.is_active,
        "is_active",
        docId
    );


    assertDate(
        doc.created_at,
        "created_at",
        docId
    );


    assertDate(
        doc.updated_at,
        "updated_at",
        docId
    );


    /* ====================================================================
       OPTIONAL CREATED_BY / UPDATED_BY
       ==================================================================== */

    if (
        hasOwn(doc, "created_by") &&
        !isNullOrUndefined(doc.created_by)
    ) {

        assertBsonInteger(
            doc.created_by,
            "created_by",
            docId
        );
    }


    if (
        hasOwn(doc, "updated_by") &&
        !isNullOrUndefined(doc.updated_by)
    ) {

        assertBsonInteger(
            doc.updated_by,
            "updated_by",
            docId
        );
    }


    /* ====================================================================
       ORGANIZER
       ==================================================================== */

    if (
        !isPlainObject(doc.organizer)
    ) {

        fail(
            "MIGRATION STOPPED: organizer must be object | Doc: " +
            docId
        );
    }


    assertExactKeys(
        doc.organizer,
        ORGANIZER_FIELDS,
        "organizer",
        docId
    );


    ORGANIZER_FIELDS.forEach(
        function (field) {

            if (
                !hasOwn(
                    doc.organizer,
                    field
                )
            ) {

                fail(
                    "MIGRATION STOPPED: organizer." +
                    field +
                    " is required | Doc: " +
                    docId
                );
            }
        }
    );


    assertBsonInteger(
        doc.organizer.user_id,
        "organizer.user_id",
        docId
    );


    assertString(
        doc.organizer.name,
        "organizer.name",
        docId,
        1,
        200
    );


    assertEnum(
        doc.organizer.role,
        "organizer.role",
        VALID_ROLES,
        docId
    );


    assertString(
        doc.organizer.email,
        "organizer.email",
        docId,
        1,
        254
    );


    /* ====================================================================
       TARGETS
       ==================================================================== */

    if (
        !Array.isArray(doc.targets) ||
        doc.targets.length < 1
    ) {

        fail(
            "MIGRATION STOPPED: targets must be non-empty array | Doc: " +
            docId
        );
    }


    var allTargetUserIds = [];


    doc.targets.forEach(
        function (target, targetIndex) {

            var targetPath =
                "targets[" +
                targetIndex +
                "]";


            if (
                !isPlainObject(target)
            ) {

                fail(
                    "MIGRATION STOPPED: " +
                    targetPath +
                    " must be object | Doc: " +
                    docId
                );
            }


            assertExactKeys(
                target,
                TARGET_FIELDS,
                targetPath,
                docId
            );


            TARGET_FIELDS.forEach(
                function (field) {

                    if (
                        !hasOwn(
                            target,
                            field
                        )
                    ) {

                        fail(
                            "MIGRATION STOPPED: " +
                            targetPath +
                            "." +
                            field +
                            " is required | Doc: " +
                            docId
                        );
                    }
                }
            );


            assertEnum(
                target.target_type,
                targetPath +
                ".target_type",
                VALID_TARGET_TYPES,
                docId
            );


            assertEnum(
                target.role,
                targetPath +
                ".role",
                VALID_ROLES,
                docId
            );


            if (
                !Array.isArray(
                    target.user_ids
                ) ||
                target.user_ids.length < 1
            ) {

                fail(
                    "MIGRATION STOPPED: " +
                    targetPath +
                    ".user_ids must be non-empty array | Doc: " +
                    docId
                );
            }


            target.user_ids.forEach(
                function (userId, userIndex) {

                    var userPath =
                        targetPath +
                        ".user_ids[" +
                        userIndex +
                        "]";


                    assertBsonInteger(
                        userId,
                        userPath,
                        docId
                    );


                    var normalized =
                        integerToString(userId);


                    if (
                        allTargetUserIds.indexOf(
                            normalized
                        ) !== -1
                    ) {

                        fail(
                            "MIGRATION STOPPED: duplicate target user_id '" +
                            normalized +
                            "' | Doc: " +
                            docId
                        );
                    }


                    allTargetUserIds.push(
                        normalized
                    );
                }
            );
        }
    );


    /* Organizer cannot be target */

    var organizerId =
        integerToString(
            doc.organizer.user_id
        );


    if (
        allTargetUserIds.indexOf(
            organizerId
        ) !== -1
    ) {

        fail(
            "MIGRATION STOPPED: organizer.user_id cannot also be target | Doc: " +
            docId
        );
    }


    /* ====================================================================
       AGENDA
       ==================================================================== */

    if (
        hasOwn(doc, "agenda") &&
        !isNullOrUndefined(doc.agenda)
    ) {

        if (
            !Array.isArray(doc.agenda)
        ) {

            fail(
                "MIGRATION STOPPED: agenda must be array or null | Doc: " +
                docId
            );
        }


        var agendaIds = [];


        doc.agenda.forEach(
            function (item, index) {

                var path =
                    "agenda[" +
                    index +
                    "]";


                if (
                    !isPlainObject(item)
                ) {

                    fail(
                        "MIGRATION STOPPED: " +
                        path +
                        " must be object | Doc: " +
                        docId
                    );
                }


                assertExactKeys(
                    item,
                    AGENDA_FIELDS,
                    path,
                    docId
                );


                if (
                    !hasOwn(item, "agenda_id") ||
                    !hasOwn(item, "title")
                ) {

                    fail(
                        "MIGRATION STOPPED: " +
                        path +
                        " requires agenda_id and title | Doc: " +
                        docId
                    );
                }


                assertBsonInteger(
                    item.agenda_id,
                    path +
                    ".agenda_id",
                    docId
                );


                assertString(
                    item.title,
                    path +
                    ".title",
                    docId,
                    1,
                    300
                );


                var agendaId =
                    integerToString(
                        item.agenda_id
                    );


                if (
                    agendaIds.indexOf(
                        agendaId
                    ) !== -1
                ) {

                    fail(
                        "MIGRATION STOPPED: duplicate agenda_id '" +
                        agendaId +
                        "' | Doc: " +
                        docId
                    );
                }


                agendaIds.push(
                    agendaId
                );
            }
        );
    }


    /* ====================================================================
       ONLINE DETAILS
       ==================================================================== */

    if (
        hasOwn(doc, "online_details") &&
        !isNullOrUndefined(doc.online_details)
    ) {

        if (
            !isPlainObject(
                doc.online_details
            )
        ) {

            fail(
                "MIGRATION STOPPED: online_details must be object or null | Doc: " +
                docId
            );
        }


        assertExactKeys(
            doc.online_details,
            ONLINE_FIELDS,
            "online_details",
            docId
        );
    }


    /* ====================================================================
       LOCATION
       ==================================================================== */

    if (
        hasOwn(doc, "location") &&
        !isNullOrUndefined(doc.location)
    ) {

        assertString(
            doc.location,
            "location",
            docId,
            1,
            200
        );
    }


    /* ====================================================================
       ROOM
       ==================================================================== */

    if (
        hasOwn(doc, "room_no") &&
        !isNullOrUndefined(doc.room_no)
    ) {

        assertString(
            doc.room_no,
            "room_no",
            docId,
            1,
            100
        );
    }


    /* ====================================================================
       MEETING TYPE RULES
       ==================================================================== */

    if (
        doc.meeting_type === "VIRTUAL"
    ) {

        /* online_details required */

        if (
            !hasOwn(
                doc,
                "online_details"
            ) ||
            !isPlainObject(
                doc.online_details
            )
        ) {

            fail(
                "MIGRATION STOPPED: VIRTUAL meeting requires online_details object | Doc: " +
                docId
            );
        }


        assertExactKeys(
            doc.online_details,
            ONLINE_FIELDS,
            "online_details",
            docId
        );


        if (
            !hasOwn(
                doc.online_details,
                "platform"
            ) ||
            !hasOwn(
                doc.online_details,
                "meeting_url"
            )
        ) {

            fail(
                "MIGRATION STOPPED: VIRTUAL online_details requires platform and meeting_url | Doc: " +
                docId
            );
        }


        assertEnum(
            doc.online_details.platform,
            "online_details.platform",
            VALID_PLATFORMS,
            docId
        );


        assertString(
            doc.online_details.meeting_url,
            "online_details.meeting_url",
            docId,
            1,
            2048
        );


        /* location must exist and be null */

        if (
            !hasOwn(doc, "location") ||
            doc.location !== null
        ) {

            fail(
                "MIGRATION STOPPED: VIRTUAL meeting requires location=null | Doc: " +
                docId
            );
        }


        /* room_no must exist and be null */

        if (
            !hasOwn(doc, "room_no") ||
            doc.room_no !== null
        ) {

            fail(
                "MIGRATION STOPPED: VIRTUAL meeting requires room_no=null | Doc: " +
                docId
            );
        }
    }


    if (
        doc.meeting_type === "IN_PERSON"
    ) {

        /* location required */

        if (
            !hasOwn(doc, "location")
        ) {

            fail(
                "MIGRATION STOPPED: IN_PERSON meeting requires location | Doc: " +
                docId
            );
        }


        assertString(
            doc.location,
            "location",
            docId,
            1,
            200
        );


        /* online_details must exist and be null */

        if (
            !hasOwn(doc, "online_details") ||
            doc.online_details !== null
        ) {

            fail(
                "MIGRATION STOPPED: IN_PERSON meeting requires online_details=null | Doc: " +
                docId
            );
        }


        /*
           room_no:
             - missing = allowed
             - null = allowed
             - string = allowed
        */

        if (
            hasOwn(doc, "room_no") &&
            !isNullOrUndefined(doc.room_no)
        ) {

            assertString(
                doc.room_no,
                "room_no",
                docId,
                1,
                100
            );
        }
    }


    /* ====================================================================
       RESOURCES
       ==================================================================== */

    if (
        hasOwn(doc, "resources") &&
        !isNullOrUndefined(doc.resources)
    ) {

        if (
            !Array.isArray(doc.resources)
        ) {

            fail(
                "MIGRATION STOPPED: resources must be array or null | Doc: " +
                docId
            );
        }


        var resourceIds = [];


        doc.resources.forEach(
            function (resource, index) {

                var path =
                    "resources[" +
                    index +
                    "]";


                if (
                    !isPlainObject(resource)
                ) {

                    fail(
                        "MIGRATION STOPPED: " +
                        path +
                        " must be object | Doc: " +
                        docId
                    );
                }


                assertExactKeys(
                    resource,
                    RESOURCE_FIELDS,
                    path,
                    docId
                );


                [
                    "resource_id",
                    "title",
                    "resource_type"
                ].forEach(
                    function (field) {

                        if (
                            !hasOwn(
                                resource,
                                field
                            )
                        ) {

                            fail(
                                "MIGRATION STOPPED: " +
                                path +
                                "." +
                                field +
                                " is required | Doc: " +
                                docId
                            );
                        }
                    }
                );


                assertBsonInteger(
                    resource.resource_id,
                    path +
                    ".resource_id",
                    docId
                );


                assertString(
                    resource.title,
                    path +
                    ".title",
                    docId,
                    1,
                    300
                );


                assertEnum(
                    resource.resource_type,
                    path +
                    ".resource_type",
                    VALID_RESOURCE_TYPES,
                    docId
                );


                /* --------------------------------------------------------
                   DOCUMENT
                   -------------------------------------------------------- */

                if (
                    resource.resource_type ===
                    "document"
                ) {

                    if (
                        !hasOwn(
                            resource,
                            "object_key"
                        ) ||
                        typeof resource.object_key !== "string"
                    ) {

                        fail(
                            "MIGRATION STOPPED: document resource requires object_key string | Doc: " +
                            docId
                        );
                    }


                    assertString(
                        resource.object_key,
                        path +
                        ".object_key",
                        docId,
                        1,
                        2048
                    );


                    if (
                        !hasOwn(
                            resource,
                            "url"
                        ) ||
                        resource.url !== null
                    ) {

                        fail(
                            "MIGRATION STOPPED: document resource requires url=null | Doc: " +
                            docId
                        );
                    }
                }


                /* --------------------------------------------------------
                   LINK
                   -------------------------------------------------------- */

                if (
                    resource.resource_type ===
                    "link"
                ) {

                    if (
                        !hasOwn(
                            resource,
                            "url"
                        ) ||
                        typeof resource.url !== "string"
                    ) {

                        fail(
                            "MIGRATION STOPPED: link resource requires url string | Doc: " +
                            docId
                        );
                    }


                    assertString(
                        resource.url,
                        path +
                        ".url",
                        docId,
                        1,
                        2048
                    );


                    if (
                        !hasOwn(
                            resource,
                            "object_key"
                        ) ||
                        resource.object_key !== null
                    ) {

                        fail(
                            "MIGRATION STOPPED: link resource requires object_key=null | Doc: " +
                            docId
                        );
                    }
                }


                var resourceId =
                    integerToString(
                        resource.resource_id
                    );


                if (
                    resourceIds.indexOf(
                        resourceId
                    ) !== -1
                ) {

                    fail(
                        "MIGRATION STOPPED: duplicate resource_id '" +
                        resourceId +
                        "' | Doc: " +
                        docId
                    );
                }


                resourceIds.push(
                    resourceId
                );
            }
        );
    }


    /* ====================================================================
       NOTIFICATION REMINDER
       ==================================================================== */

    if (
        hasOwn(
            doc,
            "notification_reminder"
        ) &&
        !isNullOrUndefined(
            doc.notification_reminder
        )
    ) {

        if (
            !isPlainObject(
                doc.notification_reminder
            )
        ) {

            fail(
                "MIGRATION STOPPED: notification_reminder must be object or null | Doc: " +
                docId
            );
        }


        assertExactKeys(
            doc.notification_reminder,
            REMINDER_FIELDS,
            "notification_reminder",
            docId
        );


        if (
            !hasOwn(
                doc.notification_reminder,
                "enabled"
            )
        ) {

            fail(
                "MIGRATION STOPPED: notification_reminder.enabled is required | Doc: " +
                docId
            );
        }


        assertBoolean(
            doc.notification_reminder.enabled,
            "notification_reminder.enabled",
            docId
        );


        if (
            doc.notification_reminder.enabled === true
        ) {

            if (
                !hasOwn(
                    doc.notification_reminder,
                    "minutes_before"
                ) ||
                isNullOrUndefined(
                    doc.notification_reminder.minutes_before
                )
            ) {

                fail(
                    "MIGRATION STOPPED: enabled reminder requires minutes_before | Doc: " +
                    docId
                );
            }


            assertBsonInteger(
                doc.notification_reminder.minutes_before,
                "notification_reminder.minutes_before",
                docId
            );

        } else {

            /*
               Disabled reminder:
               minutes_before may be missing or null.

               If supplied with a value, it must still be a
               positive BSON integer because the schema allows it.
            */

            if (
                hasOwn(
                    doc.notification_reminder,
                    "minutes_before"
                ) &&
                !isNullOrUndefined(
                    doc.notification_reminder.minutes_before
                )
            ) {

                assertBsonInteger(
                    doc.notification_reminder.minutes_before,
                    "notification_reminder.minutes_before",
                    docId
                );
            }
        }
    }
}


/* ========================================================================
   COLLECTION CREATION / MIGRATION
   ======================================================================== */

print("");
print("================================================================");
print("THINKIGEN CONNECT_MEETING COLLECTION SETUP");
print("================================================================");


var collectionExists =
    db.getCollectionNames().indexOf(
        COLLECTION_NAME
    ) !== -1;


/* ========================================================================
   EXISTING COLLECTION
   ======================================================================== */

if (
    collectionExists
) {

    print(
        "Collection already exists: " +
        COLLECTION_NAME
    );

    print(
        "Running complete pre-collMod validation..."
    );


    var existingDocs =
        db[
            COLLECTION_NAME
        ]
            .find({})
            .toArray();


    print(
        "Documents found: " +
        existingDocs.length
    );


    /*
       IMPORTANT:

       Every existing document must satisfy the complete
       migration validation before collMod.

       Nothing is modified before validation succeeds.
    */

    existingDocs.forEach(
        function (doc) {

            validateExistingDocument(
                doc
            );
        }
    );


    print(
        "Pre-collMod validation PASSED."
    );


    var collModResult =
        db.runCommand({

            collMod:
                COLLECTION_NAME,

            validator:
                validator,

            validationLevel:
                "strict",

            validationAction:
                "error"
        });


    if (
        !collModResult.ok
    ) {

        fail(
            "collMod failed: " +
            JSON.stringify(
                collModResult
            )
        );
    }


    print(
        "Validator applied successfully."
    );
}


/* ========================================================================
   NEW COLLECTION
   ======================================================================== */

else {

    db.createCollection(
        COLLECTION_NAME,
        {

            validator:
                validator,

            validationLevel:
                "strict",

            validationAction:
                "error"
        }
    );


    print(
        "Collection created successfully: " +
        COLLECTION_NAME
    );
}


/* ========================================================================
   DESIRED INDEXES
   ======================================================================== */

var desiredIndexes = [

    {
        key: {
            meeting_id: 1
        },

        options: {
            unique: true,
            name: "uq_connect_meeting_id"
        }
    },


    {
        key: {
            school_id: 1,
            scheduled_at: 1,
            status: 1
        },

        options: {
            name: "ix_connect_meeting_schedule"
        }
    },


    {
        key: {
            branch_id: 1,
            scheduled_at: 1,
            status: 1
        },

        options: {
            name: "ix_connect_meeting_branch_schedule"
        }
    },


    {
        key: {
            "targets.user_ids": 1,
            scheduled_at: -1
        },

        options: {
            name: "ix_connect_meeting_target_user"
        }
    }
];


/* ========================================================================
   INDEX HELPERS
   ======================================================================== */

function sameIndexKey(
    existingKey,
    desiredKey
) {

    return (
        JSON.stringify(existingKey) ===
        JSON.stringify(desiredKey)
    );
}


function sameIndexOptions(
    existingIndex,
    desiredOptions
) {

    /*
       Desired indexes in this script use only:
         - unique
         - name

       All other special options must be absent/default.
    */

    var desiredUnique =
        !!desiredOptions.unique;

    var existingUnique =
        !!existingIndex.unique;


    if (
        existingUnique !==
        desiredUnique
    ) {
        return false;
    }


    /*
       A desired normal index must not secretly be:
         - sparse
         - partial
         - TTL
         - hidden
         - custom collation
    */

    if (
        !!existingIndex.sparse
    ) {
        return false;
    }


    if (
        existingIndex.partialFilterExpression
    ) {
        return false;
    }


    if (
        existingIndex.expireAfterSeconds !==
        undefined
    ) {
        return false;
    }


    if (
        existingIndex.hidden === true
    ) {
        return false;
    }


    if (
        existingIndex.collation
    ) {
        return false;
    }


    return true;
}


/* ========================================================================
   INDEX CREATION
   ======================================================================== */

desiredIndexes.forEach(
    function (desired) {

        var currentIndexes =
            db[
                COLLECTION_NAME
            ].getIndexes();


        /* ---------------------------------------------------------------
           EXACT NAME
           --------------------------------------------------------------- */

        var sameName =
            currentIndexes.find(
                function (idx) {

                    return (
                        idx.name ===
                        desired.options.name
                    );
                }
            );


        if (
            sameName
        ) {

            /*
               Same name but different definition:
               STOP.

               Never drop or rewrite an existing index automatically.
            */

            if (
                !sameIndexKey(
                    sameName.key,
                    desired.key
                ) ||
                !sameIndexOptions(
                    sameName,
                    desired.options
                )
            ) {

                fail(
                    "INDEX SETUP STOPPED: index '" +
                    desired.options.name +
                    "' already exists with a different definition. " +
                    "Review manually. No index was dropped."
                );
            }


            print(
                "Index already correct: " +
                desired.options.name
            );

            return;
        }


        /* ---------------------------------------------------------------
           EQUIVALENT DEFINITION
           --------------------------------------------------------------- */

        var sameDefinition =
            currentIndexes.find(
                function (idx) {

                    return (
                        sameIndexKey(
                            idx.key,
                            desired.key
                        ) &&
                        sameIndexOptions(
                            idx,
                            desired.options
                        )
                    );
                }
            );


        if (
            sameDefinition
        ) {

            print(
                "Equivalent index already exists as '" +
                sameDefinition.name +
                "'. Skipping duplicate creation for '" +
                desired.options.name +
                "'."
            );

            return;
        }


        /* ---------------------------------------------------------------
           CREATE
           --------------------------------------------------------------- */

        db[
            COLLECTION_NAME
        ].createIndex(
            desired.key,
            desired.options
        );


        print(
            "Created index: " +
            desired.options.name
        );
    }
);


/* ========================================================================
   FINAL VERIFICATION
   ======================================================================== */

print("");
print("================================================================");
print("FINAL VERIFICATION");
print("================================================================");


/* ========================================================================
   COLLECTION
   ======================================================================== */

var collectionInfo =
    db.getCollectionInfos({
        name: COLLECTION_NAME
    })[0];


if (
    !collectionInfo
) {

    fail(
        "FINAL VERIFICATION FAILED: collection not found."
    );
}


print(
    "Collection verified: " +
    COLLECTION_NAME
);


/* ========================================================================
   VALIDATOR
   ======================================================================== */

if (
    !collectionInfo.options ||
    !collectionInfo.options.validator
) {

    fail(
        "FINAL VERIFICATION FAILED: validator is missing."
    );
}


if (
    collectionInfo.options.validationLevel !==
    "strict"
) {

    fail(
        "FINAL VERIFICATION FAILED: validationLevel must be strict."
    );
}


if (
    collectionInfo.options.validationAction !==
    "error"
) {

    fail(
        "FINAL VERIFICATION FAILED: validationAction must be error."
    );
}


print(
    "Validator verified: strict / error"
);


/* ========================================================================
   INDEX VERIFICATION
   ======================================================================== */

var finalIndexes =
    db[
        COLLECTION_NAME
    ].getIndexes();


desiredIndexes.forEach(
    function (desired) {

        var idx =
            finalIndexes.find(
                function (item) {

                    return (
                        item.name ===
                        desired.options.name
                    );
                }
            );


        /*
           If exact name is not present,
           equivalent definition is acceptable.
        */

        if (
            !idx
        ) {

            idx =
                finalIndexes.find(
                    function (item) {

                        return (
                            sameIndexKey(
                                item.key,
                                desired.key
                            ) &&
                            sameIndexOptions(
                                item,
                                desired.options
                            )
                        );
                    }
                );
        }


        if (
            !idx
        ) {

            fail(
                "FINAL VERIFICATION FAILED: missing index definition for '" +
                desired.options.name +
                "'"
            );
        }


        print(
            "Index verified: " +
            desired.options.name
        );
    }
);


/* ========================================================================
   FINAL DOCUMENT VALIDATION
   ======================================================================== */

var finalDocs =
    db[
        COLLECTION_NAME
    ]
        .find({})
        .toArray();


finalDocs.forEach(
    function (doc) {

        validateExistingDocument(
            doc
        );
    }
);


print("");
print("================================================================");
print("CONNECT_MEETING SETUP COMPLETED SUCCESSFULLY");
print("================================================================");
print("");
print("Collection : " + COLLECTION_NAME);
print("Documents  : " + finalDocs.length);
print("Validator  : strict / error");
print("Indexes    : verified");
print("Data       : NO mock data inserted");
print("Migration  : non-destructive");
print("");
print("SQL Server remains the source of truth for users/auth/roles.");
print("MongoDB stores meeting configuration and user snapshots.");
print("Thinkigen does not host video/audio.");
print("================================================================");
