/*
 * Copyright (c) 2022 Skyflow
*/

/// How a file element draws its trigger and the selected files. Both appearances behave the
/// same: same pickers, validation, events and upload. Only the look changes.
public enum FileElementAppearance {
    /// Bordered box with a "Choose File" button and the selection, like the browser file input.
    /// The default.
    case FIELD
    /// No SDK trigger: the app's own control calls `FileInputElement.openPicker()`. The element
    /// shows only the selected files, their remove buttons and errors.
    case CUSTOM
}
