/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation

// Object that describes the different type of event listeners

public enum EventName: String {
    case CHANGE = "CHANGE"
    case READY = "READY"
    case FOCUS = "FOCUS"
    case BLUR = "BLUR"
}
