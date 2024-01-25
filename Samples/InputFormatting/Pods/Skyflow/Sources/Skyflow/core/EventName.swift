/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the different type of event listeners

import Foundation

public enum EventName: String {
    case CHANGE = "CHANGE"
    case READY = "READY"
    case FOCUS = "FOCUS"
    case BLUR = "BLUR"
    case SUBMIT = "SUBMIT"
}
