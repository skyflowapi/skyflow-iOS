/*
 * Copyright (c) 2022 Skyflow
*/

// Collect element for FILE_INPUT / MULTI_FILE_INPUT. The default `.FIELD` appearance is laid out
// like the browser file input that skyflow-js renders: one box (styled by inputStyles) holding a
// "Choose File" button and the selection ("No file chosen", the file name, or "N files"), plus a
// clear button. `.CUSTOM` draws no trigger (the app calls openPicker() from its own control)
// and lists each selected file with its own remove button. The label is above and the error
// below in both appearances. The app can observe state, open the picker and trigger uploads,
// but no public API exposes file bytes, URLs or names.

import Foundation
import UIKit

public final class FileInputElement: UIView {
    /// View controller used to present the pickers. When nil, the nearest view controller in
    /// the responder chain is used.
    public weak var presentingViewController: UIViewController?

    internal let input: FileElementInput
    internal let configurationResult: Result<FileElementConfiguration, FileErrorCode>
    internal private(set) var files: [PickedFile] = []
    internal private(set) var validationError: FileValidationError?
    internal private(set) var customError: String?
    internal private(set) var isPickerPresented = false
    internal var isUploading = false {
        didSet { refreshControls() }
    }

    private let store: SecureFileStore
    private let picker: FilePicking
    private let contextOptions: ContextOptions
    // Why the last pick failed (unreadable file, camera denied or unavailable). Never
    // contains a file name. Cleared by the next successful pick or by clearValue().
    private var pickError: String?
    private var showsValidationError = false

    private var onChangeHandler: (([String: Any]) -> Void)?
    private var onReadyHandler: (([String: Any]) -> Void)?
    private var onFocusHandler: (([String: Any]) -> Void)?
    private var onBlurHandler: (([String: Any]) -> Void)?

    internal let stackView = UIStackView()
    internal let titleLabel = UILabel()
    internal let fieldView = UIView()
    internal let chooseButton = UIButton(type: .system)
    internal let statusLabel = UILabel()
    internal let clearButton = UIButton(type: .system)
    internal let errorLabel = UILabel()
    private var fieldPadding: [NSLayoutConstraint] = []
    private lazy var fieldTap = UITapGestureRecognizer(target: self, action: #selector(chooseTapped))

    // Views for the `.CUSTOM` appearance.
    internal let fileListStack = UIStackView()
    internal private(set) var removeButtons: [UIButton] = []

    internal static let unreadableFileMessage = "Unable to read the selected file. Choose it again."
    internal static let cameraAccessDeniedMessage = "Camera access is turned off. Allow it in Settings to take a photo."
    internal static let cameraUnavailableMessage = "The camera is not available on this device."
    internal static let emptyStatus = "No file chosen"

    internal init(input: FileElementInput, options: FileElementOptions, contextOptions: ContextOptions,
                  store: SecureFileStore, picker: FilePicking? = nil) {
        self.input = input
        self.configurationResult = FileElementConfiguration.make(input: input, options: options)
        self.contextOptions = contextOptions
        self.store = store
        self.picker = picker ?? SystemFilePicker(store: store)
        super.init(frame: .zero)
        if case .failure(let error) = configurationResult {
            Log.error(message: error.message, contextOptions: contextOptions)
        }
        setUpViews()
        revalidate()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        files.forEach { store.remove($0.url) }
    }

    internal var configuration: FileElementConfiguration? {
        if case .success(let configuration) = configurationResult { return configuration }
        return nil
    }

    internal var isValid: Bool {
        configuration != nil && customError == nil && validationError == nil && pickError == nil
    }

    internal var isMounted: Bool {
        window != nil
    }

    // Message for the app: never contains a file name.
    internal var reportedError: String? {
        if let customError = customError { return customError }
        if let pickError = pickError { return pickError }
        return validationError?.reportMessage
    }

    internal var listenerState: [String: Any] {
        [
            "elementType": input.type.rawValue,
            "isEmpty": files.isEmpty,
            "isValid": isValid,
            "isFocused": isPickerPresented,
            "isRequired": configuration?.required ?? false,
            "fileCount": files.count,
            "value": "",
        ]
    }

    // MARK: - Public API

    public func on(eventName: EventName, handler: @escaping ([String: Any]) -> Void) {
        switch eventName {
        case .CHANGE: onChangeHandler = handler
        case .READY: onReadyHandler = handler
        case .FOCUS: onFocusHandler = handler
        case .BLUR: onBlurHandler = handler
        case .SUBMIT: break
        }
    }

    /// Shows `error` under the element and makes it invalid until `resetError()` is called.
    public func setError(_ error: String) {
        customError = error
        refresh()
    }

    public func resetError() {
        customError = nil
        refresh()
    }

    /// Removes every selected file and deletes the SDK's copies of them.
    public func clearValue() {
        guard isUploading == false else { return }
        removeAllFiles()
        pickError = nil
        showsValidationError = false
        revalidate()
        notifyChange()
    }

    public func unmount() {
        clearValue()
    }

    /// Opens the source menu, or the picker directly when only one source is available, from
    /// the app's own control. Available only when the element was created with
    /// `appearance: .CUSTOM`; with `.FIELD` the SDK's own button opens the picker and this call
    /// does nothing. Also ignored while a picker is open, during an upload, or when the element
    /// is misconfigured.
    public func openPicker() {
        guard isCustom else { return }
        chooseTapped()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            onReadyHandler?(listenerState)
        }
    }

    // MARK: - Internal operations (picker results, upload lifecycle)

    internal func handle(_ result: FilePickResult) {
        isPickerPresented = false
        onBlurHandler?(listenerState)
        if let failure = result.failure {
            // Nothing was picked, so the current selection stays.
            showPickError(Self.message(for: failure))
            return
        }
        guard result.files.isEmpty == false || result.unreadableCount > 0 else { return }

        // A new pick replaces the selection, as the browser file input does. A camera
        // photo counts as a pick, so on MULTI_FILE_INPUT it also replaces the selection.
        if result.files.isEmpty == false {
            removeAllFiles()
        }
        files.append(contentsOf: result.files)
        pickError = result.unreadableCount > 0 ? Self.unreadableFileMessage : nil
        showsValidationError = true
        revalidate()
        notifyChange()
    }

    /// Re-runs validation and makes any error visible. Returns the error to report, if any.
    internal func validateForUpload() -> String? {
        showsValidationError = true
        revalidate()
        return reportedError
    }

    /// Uploaded files leave the element so a second uploadFiles() call cannot create
    /// duplicate records; their copies are deleted. Failed files stay for a retry.
    internal func markUploaded(_ ids: Set<UUID>) {
        guard ids.isEmpty == false else { return }
        files.removeAll { file in
            guard ids.contains(file.id) else { return false }
            store.remove(file.url)
            return true
        }
        showsValidationError = false
        revalidate()
        notifyChange()
    }

    internal func makeUploadJobs() -> [FileUploadJob] {
        guard let configuration = configuration else { return [] }
        return files.map {
            FileUploadJob(file: $0, table: configuration.table, column: configuration.column,
                          skyflowID: configuration.skyflowID, preserveFileName: configuration.preserveFileName,
                          returnFileMetadata: configuration.returnFileMetadata)
        }
    }

    // MARK: - Picking

    @objc internal func chooseTapped() {
        guard let configuration = configuration, isUploading == false, isPickerPresented == false,
              let presenter = resolvePresenter() else {
            return
        }
        let sources = availableSources
        guard let first = sources.first else {
            // Only the camera was configured, and this device or app cannot offer it.
            showPickError(Self.cameraUnavailableMessage)
            return
        }
        if sources.count == 1 {
            present(first, from: presenter, configuration: configuration)
            return
        }
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for source in sources {
            sheet.addAction(UIAlertAction(title: Self.menuTitle(for: source), style: .default) { [weak self] _ in
                self?.present(source, from: presenter, configuration: configuration)
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        // An action sheet without an anchor crashes on iPad.
        sheet.popoverPresentationController?.sourceView = menuAnchor
        sheet.popoverPresentationController?.sourceRect = menuAnchor.bounds
        presenter.present(sheet, animated: true)
    }

    /// Configured sources this device and app can offer, in menu order.
    internal var availableSources: [FileSource] {
        (configuration?.sources ?? []).filter(picker.isAvailable)
    }

    internal static func menuTitle(for source: FileSource) -> String {
        switch source {
        case .FILES: return "Browse Files"
        case .PHOTOS: return "Photo Library"
        case .CAMERA: return "Take Photo"
        }
    }

    internal static func message(for failure: FilePickFailure) -> String {
        switch failure {
        case .cameraAccessDenied: return cameraAccessDeniedMessage
        case .cameraUnavailable: return cameraUnavailableMessage
        }
    }

    private func showPickError(_ message: String) {
        pickError = message
        showsValidationError = true
        revalidate()
        notifyChange()
    }

    @objc internal func clearTapped() {
        clearValue()
    }

    /// Removes one selected file (the ✕ on its row) and deletes the SDK's copy.
    internal func removeFile(at index: Int) {
        guard isUploading == false, files.indices.contains(index) else { return }
        let file = files.remove(at: index)
        store.remove(file.url)
        if files.isEmpty {
            pickError = nil
            showsValidationError = false
        }
        revalidate()
        notifyChange()
    }

    @objc private func removeRowTapped(_ sender: UIButton) {
        removeFile(at: sender.tag)
    }

    private var menuAnchor: UIView {
        isCustom ? self : chooseButton
    }

    private func present(_ source: FileSource, from presenter: UIViewController, configuration: FileElementConfiguration) {
        isPickerPresented = true
        onFocusHandler?(listenerState)
        picker.pick(from: source, presenter: presenter, configuration: configuration,
                    selectionLimit: configuration.maxFileCount) { [weak self] result in
            self?.handle(result)
        }
    }

    internal func resolvePresenter() -> UIViewController? {
        var candidate = presentingViewController
        if candidate == nil {
            var responder: UIResponder? = self
            while let next = responder?.next {
                if let viewController = next as? UIViewController {
                    candidate = viewController
                    break
                }
                responder = next
            }
        }
        guard var presenter = candidate else { return nil }
        while let presented = presenter.presentedViewController, presented.isBeingDismissed == false {
            presenter = presented
        }
        return presenter
    }

    // MARK: - State and rendering

    private func removeAllFiles() {
        files.forEach { store.remove($0.url) }
        files.removeAll()
    }

    private func revalidate() {
        validationError = configuration.flatMap { FileValidator.validate(files, configuration: $0) }
        refresh()
    }

    private func notifyChange() {
        onChangeHandler?(listenerState)
    }

    private var displayedError: String? {
        if let customError = customError { return customError }
        guard showsValidationError else { return nil }
        if let pickError = pickError { return pickError }
        return validationError?.displayMessage
    }

    // Matches what the browser shows next to its "Choose File" button.
    internal var statusText: String {
        switch files.count {
        case 0: return Self.emptyStatus
        case 1: return files[0].name
        default: return "\(files.count) files"
        }
    }

    private var isCustom: Bool {
        input.appearance == .CUSTOM
    }

    private func refresh() {
        let error = displayedError
        errorLabel.text = error
        errorLabel.isHidden = error == nil
        if isCustom {
            reloadFileRows()
        } else {
            applyFieldStyle(error == nil ? input.inputStyles.base : (input.inputStyles.invalid ?? input.inputStyles.base))
            statusLabel.text = statusText
            clearButton.isHidden = files.isEmpty
        }
        refreshControls()
    }

    private func refreshControls() {
        let canPick = configuration != nil && isUploading == false
        chooseButton.isEnabled = canPick
        fieldTap.isEnabled = canPick
        clearButton.isEnabled = isUploading == false
        removeButtons.forEach { $0.isEnabled = isUploading == false }
    }

    private func setUpViews() {
        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        let isRequired = configuration?.required ?? false
        titleLabel.text = input.label.isEmpty ? nil : (isRequired ? "\(input.label) *" : input.label)
        titleLabel.isHidden = input.label.isEmpty
        titleLabel.numberOfLines = 0
        apply(input.labelStyles.base, to: titleLabel)

        errorLabel.numberOfLines = 0
        errorLabel.textColor = .systemRed
        errorLabel.font = .preferredFont(forTextStyle: .footnote)
        apply(input.errorTextStyles.base, to: errorLabel)

        fileListStack.axis = .vertical
        fileListStack.spacing = 6

        let body = isCustom ? fileListStack : makeFieldBody()
        [titleLabel, body, errorLabel].forEach(stackView.addArrangedSubview)
    }

    private var chooseTitle: String {
        guard input.placeholder.isEmpty else { return input.placeholder }
        return input.type == .MULTI_FILE_INPUT ? "Choose Files" : "Choose File"
    }

    private func makeFieldBody() -> UIView {
        // Styled after the browser's native file button: a small filled button inside the box.
        chooseButton.setTitle(chooseTitle, for: .normal)
        chooseButton.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        chooseButton.backgroundColor = .tertiarySystemFill
        chooseButton.layer.cornerRadius = 6
        chooseButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        chooseButton.setContentHuggingPriority(.required, for: .horizontal)
        chooseButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        chooseButton.addTarget(self, action: #selector(chooseTapped), for: .touchUpInside)

        statusLabel.lineBreakMode = .byTruncatingMiddle
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        clearButton.tintColor = .tertiaryLabel
        clearButton.accessibilityLabel = "Clear selected files"
        clearButton.setContentHuggingPriority(.required, for: .horizontal)
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [chooseButton, statusLabel, clearButton])
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        fieldView.addSubview(row)
        fieldPadding = [
            row.topAnchor.constraint(equalTo: fieldView.topAnchor),
            row.leadingAnchor.constraint(equalTo: fieldView.leadingAnchor),
            fieldView.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            fieldView.bottomAnchor.constraint(equalTo: row.bottomAnchor),
        ]
        NSLayoutConstraint.activate(fieldPadding)
        // Like the browser input, tapping anywhere in the box opens the picker.
        fieldView.addGestureRecognizer(fieldTap)
        fieldView.isAccessibilityElement = false
        return fieldView
    }

    // One row per selected file: its name and its own remove button.
    private func reloadFileRows() {
        fileListStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        removeButtons.removeAll()
        let style = input.inputStyles.base
        for (index, file) in files.enumerated() {
            let name = UILabel()
            name.text = file.name
            name.lineBreakMode = .byTruncatingMiddle
            name.font = style?.font ?? .preferredFont(forTextStyle: .body)
            name.textColor = style?.textColor ?? .label
            name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            let remove = UIButton(type: .system)
            remove.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            remove.tintColor = .tertiaryLabel
            remove.accessibilityLabel = "Remove file"
            remove.tag = index
            remove.isEnabled = isUploading == false
            remove.setContentHuggingPriority(.required, for: .horizontal)
            remove.addTarget(self, action: #selector(removeRowTapped(_:)), for: .touchUpInside)
            removeButtons.append(remove)

            let row = UIStackView(arrangedSubviews: [name, remove])
            row.axis = .horizontal
            row.spacing = 8
            row.alignment = .center
            fileListStack.addArrangedSubview(row)
        }
        fileListStack.isHidden = fileListStack.arrangedSubviews.isEmpty
    }

    private func apply(_ style: Style?, to label: UILabel) {
        guard let style = style else { return }
        if let font = style.font { label.font = font }
        if let color = style.textColor { label.textColor = color }
        if let alignment = style.textAlignment { label.textAlignment = alignment }
    }

    private func applyFieldStyle(_ style: Style?) {
        fieldView.layer.borderColor = (style?.borderColor ?? .separator).cgColor
        fieldView.layer.borderWidth = style?.borderWidth ?? 1
        fieldView.layer.cornerRadius = style?.cornerRadius ?? 6
        fieldView.backgroundColor = style?.backgroundColor
        let padding = style?.padding ?? UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        fieldPadding[0].constant = padding.top
        fieldPadding[1].constant = padding.left
        fieldPadding[2].constant = padding.right
        fieldPadding[3].constant = padding.bottom
        statusLabel.font = style?.font ?? .preferredFont(forTextStyle: .body)
        statusLabel.textColor = files.isEmpty ? .secondaryLabel : (style?.textColor ?? .label)
    }
}
