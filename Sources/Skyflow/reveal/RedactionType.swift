/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the types of redaction

import Foundation

/// Supported redaction types.
public enum RedactionType: String {
    case PLAIN_TEXT = "PLAIN_TEXT"
    case DEFAULT = "DEFAULT"
    case REDACTED = "REDACTED"
    case MASKED = "MASKED"
}
