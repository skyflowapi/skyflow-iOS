/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the types of redaction

import Foundation

public enum RedactionType: String {
    case PLAIN_TEXT = "PLAIN_TEXT"
    case DEFAULT = "DEFAULT"
    case REDACTED = "REDACTED"
    case MASKED = "MASKED"
}
