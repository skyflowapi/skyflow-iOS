/*
 * Copyright (c) 2022 Skyflow
*/

import UIKit
import XCTest
@testable import Skyflow
@testable import SkyflowCore

final class FileInputElementTests: XCTestCase {
    private var base: URL!
    private var outside: URL!
    private var store: SecureFileStore!
    private var picker: FakePicker!
    // presentingViewController is weak; the test must own the presenter.
    private var presenter: UIViewController!

    override func setUp() {
        base = FileTestSupport.makeDirectory()
        outside = FileTestSupport.makeDirectory()
        store = SecureFileStore(baseDirectory: base)
        picker = FakePicker()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: base)
        try? FileManager.default.removeItem(at: outside)
    }

    private func makeElement(type: FileElementType = .FILE_INPUT,
                             table: String = "docs",
                             label: String = "",
                             placeholder: String = "",
                             appearance: FileElementAppearance = .FIELD,
                             options: FileElementOptions = FileElementOptions(sources: [.FILES])) -> FileInputElement {
        FileInputElement(input: FileElementInput(table: table, column: "file", label: label, placeholder: placeholder,
                                                 type: type, appearance: appearance),
                         options: options, contextOptions: ContextOptions(), store: store, picker: picker)
    }

    private func storedFile(_ name: String, bytes: Int = 10) -> PickedFile {
        let url = try! store.importFile(from: FileTestSupport.writeFile(named: name, bytes: bytes, in: outside), move: true)
        return PickedFile(url: url, name: name, size: bytes)
    }

    private func exists(_ file: PickedFile) -> Bool {
        FileManager.default.fileExists(atPath: file.url.path)
    }

    // MARK: - Initial state

    func testInitialState() {
        let element = makeElement(options: FileElementOptions(required: true, sources: [.FILES]))
        let state = element.listenerState

        XCTAssertEqual(state["elementType"] as? String, "FILE_INPUT")
        XCTAssertEqual(state["isEmpty"] as? Bool, true)
        XCTAssertEqual(state["isRequired"] as? Bool, true)
        XCTAssertEqual(state["fileCount"] as? Int, 0)
        XCTAssertEqual(state["isFocused"] as? Bool, false)
        XCTAssertEqual(state["value"] as? String, "")
        // Required + empty is invalid, but the error is only shown after interaction.
        XCTAssertEqual(state["isValid"] as? Bool, false)
        XCTAssertTrue(element.errorLabel.isHidden)
    }

    func testDefaultButtonTitles() {
        XCTAssertEqual(makeElement().chooseButton.title(for: .normal), "Choose File")
        XCTAssertEqual(makeElement(type: .MULTI_FILE_INPUT).chooseButton.title(for: .normal), "Choose Files")
        XCTAssertEqual(makeElement(placeholder: "Upload ID").chooseButton.title(for: .normal), "Upload ID")
    }

    func testLabelShowsRequiredMarker() {
        XCTAssertEqual(makeElement(label: "ID proof", options: FileElementOptions(required: true)).titleLabel.text, "ID proof *")
        XCTAssertEqual(makeElement(label: "ID proof").titleLabel.text, "ID proof")
        XCTAssertTrue(makeElement().titleLabel.isHidden)
    }

    func testInvalidConfigurationDisablesPicking() {
        let element = makeElement(table: "")

        XCTAssertNil(element.configuration)
        XCTAssertFalse(element.chooseButton.isEnabled)
        XCTAssertEqual(element.fieldView.gestureRecognizers?.first?.isEnabled, false)
        XCTAssertFalse(element.isValid)
        presenter = UIViewController()
        element.presentingViewController = presenter
        element.chooseTapped()
        XCTAssertTrue(picker.requests.isEmpty)
    }

    // MARK: - Picking

    func testTapPresentsSingleSourceDirectlyAndFiresFocusAndBlur() {
        let element = makeElement()
        presenter = UIViewController()
        element.presentingViewController = presenter
        var events: [String] = []
        element.on(eventName: .FOCUS) { events.append("focus:\($0["isFocused"] as! Bool)") }
        element.on(eventName: .BLUR) { events.append("blur:\($0["isFocused"] as! Bool)") }
        element.on(eventName: .CHANGE) { _ in events.append("change") }

        XCTAssertEqual(element.chooseButton.actions(forTarget: element, forControlEvent: .touchUpInside), ["chooseTapped"])
        element.chooseTapped()
        XCTAssertEqual(picker.requests.map(\.source), [.FILES])
        XCTAssertEqual(picker.requests.first?.selectionLimit, 1)

        picker.complete(.cancelled)
        XCTAssertEqual(events, ["focus:true", "blur:false"])
    }

    func testTapWithoutPresenterDoesNothing() {
        let element = makeElement()

        element.chooseTapped()

        XCTAssertTrue(picker.requests.isEmpty)
        XCTAssertFalse(element.isPickerPresented)
    }

    func testSecondTapWhilePickerOpenIsIgnored() {
        let element = makeElement()
        presenter = UIViewController()
        element.presentingViewController = presenter

        element.chooseTapped()
        element.chooseTapped()

        XCTAssertEqual(picker.requests.count, 1)
    }

    func testTappingAnywhereInTheBoxOpensPicker() {
        let element = makeElement()
        let tap = element.fieldView.gestureRecognizers?.first as? UITapGestureRecognizer

        XCTAssertNotNil(tap)
        XCTAssertTrue(tap?.isEnabled == true)
    }

    func testMultiFileSelectionLimitIsMaxFileCount() {
        let element = makeElement(type: .MULTI_FILE_INPUT, options: FileElementOptions(maxFileCount: 3, sources: [.FILES]))
        presenter = UIViewController()
        element.presentingViewController = presenter
        element.handle(FilePickResult(files: [storedFile("a.pdf")]))

        element.chooseTapped()

        // A new pick replaces the selection, so the whole limit is available every time.
        XCTAssertEqual(picker.requests.first?.selectionLimit, 3)
    }

    func testNewPickReplacesSelectionAndDeletesOldCopies() {
        for type in FileElementType.allCases {
            let element = makeElement(type: type)
            let previous = type == .FILE_INPUT ? [storedFile("a.pdf")] : [storedFile("a.pdf"), storedFile("b.pdf")]
            let replacement = storedFile("c.pdf")

            element.handle(FilePickResult(files: previous))
            element.handle(FilePickResult(files: [replacement]))

            XCTAssertEqual(element.files.map(\.name), ["c.pdf"], "\(type)")
            XCTAssertTrue(previous.allSatisfy { exists($0) == false }, "\(type)")
            XCTAssertTrue(exists(replacement))
        }
    }

    func testStatusTextMatchesBrowser() {
        let element = makeElement(type: .MULTI_FILE_INPUT)
        XCTAssertEqual(element.statusLabel.text, "No file chosen")
        XCTAssertTrue(element.clearButton.isHidden)

        element.handle(FilePickResult(files: [storedFile("passport.pdf")]))
        XCTAssertEqual(element.statusLabel.text, "passport.pdf")
        XCTAssertFalse(element.clearButton.isHidden)

        element.handle(FilePickResult(files: [storedFile("a.pdf"), storedFile("b.pdf"), storedFile("c.pdf")]))
        XCTAssertEqual(element.statusLabel.text, "3 files")
        XCTAssertEqual(element.listenerState["fileCount"] as? Int, 3)
    }

    func testCancelKeepsSelectionAndFiresNoChange() {
        let element = makeElement()
        element.handle(FilePickResult(files: [storedFile("a.pdf")]))
        var changes = 0
        element.on(eventName: .CHANGE) { _ in changes += 1 }

        element.handle(.cancelled)

        XCTAssertEqual(element.files.count, 1)
        XCTAssertEqual(changes, 0)
    }

    func testUnreadableFileIsReportedAndClearedByNextAction() {
        let element = makeElement()

        element.handle(FilePickResult(files: [], unreadableCount: 1))
        XCTAssertFalse(element.isValid)
        XCTAssertEqual(element.errorLabel.text, FileInputElement.unreadableFileMessage)
        XCTAssertEqual(element.reportedError, FileInputElement.unreadableFileMessage)

        element.handle(FilePickResult(files: [storedFile("a.pdf")]))
        XCTAssertTrue(element.isValid)
        XCTAssertTrue(element.errorLabel.isHidden)
    }

    func testValidationErrorShownAfterPick() {
        let element = makeElement(options: FileElementOptions(allowedFileType: [".pdf"], sources: [.FILES]))
        var lastState: [String: Any] = [:]
        element.on(eventName: .CHANGE) { lastState = $0 }

        element.handle(FilePickResult(files: [storedFile("a.png")]))

        XCTAssertEqual(element.validationError, .invalidFileType)
        XCTAssertEqual(element.errorLabel.text, "Invalid File Type.")
        XCTAssertFalse(element.errorLabel.isHidden)
        XCTAssertEqual(lastState["isValid"] as? Bool, false)
    }

    func testDisplayedErrorMayNameFilesButReportedErrorNeverDoes() {
        let element = makeElement(type: .MULTI_FILE_INPUT, options: FileElementOptions(maxFileSize: 5))

        element.handle(FilePickResult(files: [storedFile("jane.pdf", bytes: 10), storedFile("john.pdf", bytes: 10)]))

        XCTAssertTrue(element.errorLabel.text?.contains("jane.pdf") == true)
        XCTAssertFalse(element.reportedError?.contains("jane") ?? true)
    }

    // MARK: - Removing and clearing

    func testClearButtonClearsSelectionAndFiresChange() {
        let element = makeElement(type: .MULTI_FILE_INPUT, options: FileElementOptions(maxFileCount: 1))
        let first = storedFile("a.pdf")
        let second = storedFile("b.pdf")
        element.handle(FilePickResult(files: [first, second]))
        XCTAssertEqual(element.validationError, .fileCountExceeded(maxCount: 1))
        var changes = 0
        element.on(eventName: .CHANGE) { _ in changes += 1 }

        XCTAssertEqual(element.clearButton.actions(forTarget: element, forControlEvent: .touchUpInside), ["clearTapped"])
        element.clearTapped()

        XCTAssertTrue(element.files.isEmpty)
        XCTAssertFalse(exists(first))
        XCTAssertFalse(exists(second))
        XCTAssertNil(element.validationError)
        XCTAssertEqual(element.statusLabel.text, "No file chosen")
        XCTAssertEqual(changes, 1)
    }

    func testClearValueAndUnmountDeleteCopies() {
        for clear in [{ (e: FileInputElement) in e.clearValue() }, { (e: FileInputElement) in e.unmount() }] {
            let element = makeElement(type: .MULTI_FILE_INPUT)
            let file = storedFile("a.pdf")
            element.handle(FilePickResult(files: [file]))

            clear(element)

            XCTAssertTrue(element.files.isEmpty)
            XCTAssertFalse(exists(file))
            XCTAssertTrue(element.errorLabel.isHidden)
        }
    }

    func testDeinitDeletesCopies() {
        var element: FileInputElement? = makeElement()
        let file = storedFile("a.pdf")
        element?.handle(FilePickResult(files: [file]))

        element = nil

        XCTAssertFalse(exists(file))
    }

    // MARK: - Custom errors

    func testSetAndResetError() {
        let element = makeElement()
        element.handle(FilePickResult(files: [storedFile("a.pdf")]))

        element.setError("Upload your passport")
        XCTAssertFalse(element.isValid)
        XCTAssertEqual(element.errorLabel.text, "Upload your passport")
        XCTAssertEqual(element.reportedError, "Upload your passport")

        element.resetError()
        XCTAssertTrue(element.isValid)
        XCTAssertTrue(element.errorLabel.isHidden)
    }

    func testValidateForUploadRevealsHiddenError() {
        let element = makeElement(options: FileElementOptions(required: true, sources: [.FILES]))

        XCTAssertEqual(element.validateForUpload(), "No File Selected")
        XCTAssertFalse(element.errorLabel.isHidden)
    }

    // MARK: - Upload lifecycle

    func testUploadingLocksTheElement() {
        let element = makeElement(type: .MULTI_FILE_INPUT)
        element.handle(FilePickResult(files: [storedFile("a.pdf")]))
        let tap = element.fieldView.gestureRecognizers?.first

        element.isUploading = true

        XCTAssertFalse(element.chooseButton.isEnabled)
        XCTAssertFalse(element.clearButton.isEnabled)
        XCTAssertEqual(tap?.isEnabled, false)
        element.clearTapped()
        element.clearValue()
        XCTAssertEqual(element.files.count, 1)

        element.isUploading = false
        XCTAssertTrue(element.chooseButton.isEnabled)
        XCTAssertTrue(element.clearButton.isEnabled)
        XCTAssertEqual(tap?.isEnabled, true)
    }

    func testMarkUploadedRemovesOnlyUploadedFiles() {
        let element = makeElement(type: .MULTI_FILE_INPUT)
        let uploaded = storedFile("a.pdf")
        let failed = storedFile("b.pdf")
        element.handle(FilePickResult(files: [uploaded, failed]))

        element.markUploaded([uploaded.id])

        XCTAssertEqual(element.files.map(\.id), [failed.id])
        XCTAssertFalse(exists(uploaded))
        XCTAssertTrue(exists(failed))
    }

    func testMakeUploadJobs() {
        let element = makeElement(options: FileElementOptions(preserveFileName: false, returnFileMetadata: true))
        let file = storedFile("a.pdf")
        element.handle(FilePickResult(files: [file]))

        let jobs = element.makeUploadJobs()

        XCTAssertEqual(jobs.count, 1)
        XCTAssertEqual(jobs[0].file.id, file.id)
        XCTAssertEqual(jobs[0].table, "docs")
        XCTAssertEqual(jobs[0].column, "file")
        XCTAssertFalse(jobs[0].preserveFileName)
        XCTAssertTrue(jobs[0].returnFileMetadata)
    }

    // MARK: - Privacy

    func testListenerStateNeverExposesFileDetails() {
        let element = makeElement()
        let file = storedFile("jane-passport.pdf")
        element.handle(FilePickResult(files: [file]))

        let description = "\(element.listenerState)"

        XCTAssertFalse(description.contains("jane"))
        XCTAssertFalse(description.contains(file.url.path))
    }

    // MARK: - Presenter resolution and READY

    func testPresenterResolution() {
        let element = makeElement()
        XCTAssertNil(element.resolvePresenter())

        let owner = UIViewController()
        owner.view.addSubview(element)
        XCTAssertTrue(element.resolvePresenter() === owner)

        let explicit = UIViewController()
        element.presentingViewController = explicit
        XCTAssertTrue(element.resolvePresenter() === explicit)
    }

    func testReadyFiresWhenAddedToWindow() {
        let element = makeElement()
        var readyCount = 0
        element.on(eventName: .READY) { _ in readyCount += 1 }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))

        window.addSubview(element)

        XCTAssertEqual(readyCount, 1)
        XCTAssertTrue(element.isMounted)
        element.removeFromSuperview()
        XCTAssertFalse(element.isMounted)
    }

    // MARK: - Camera

    func testMenuTitles() {
        XCTAssertEqual(FileSource.allCases.map(FileInputElement.menuTitle(for:)),
                       ["Browse Files", "Photo Library", "Take Photo"])
    }

    func testUnavailableCameraIsLeftOutOfTheMenu() {
        picker.unavailableSources = [.CAMERA]
        let element = makeElement(options: FileElementOptions(sources: [.FILES, .CAMERA]))
        presenter = UIViewController()
        element.presentingViewController = presenter

        XCTAssertEqual(element.availableSources, [.FILES])
        element.chooseTapped()

        // One source left, so it opens directly instead of showing a menu.
        XCTAssertEqual(picker.requests.map(\.source), [.FILES])
    }

    func testCameraOnlyElementOnDeviceWithoutCameraShowsError() {
        picker.unavailableSources = [.CAMERA]
        let element = makeElement(options: FileElementOptions(sources: [.CAMERA]))
        presenter = UIViewController()
        element.presentingViewController = presenter
        var changes = 0
        element.on(eventName: .CHANGE) { _ in changes += 1 }

        element.chooseTapped()

        XCTAssertTrue(picker.requests.isEmpty)
        XCTAssertFalse(element.isPickerPresented)
        XCTAssertEqual(element.errorLabel.text, FileInputElement.cameraUnavailableMessage)
        XCTAssertEqual(element.reportedError, FileInputElement.cameraUnavailableMessage)
        XCTAssertEqual(changes, 1)
    }

    func testAvailableCameraOpens() {
        let element = makeElement(options: FileElementOptions(sources: [.CAMERA]))
        presenter = UIViewController()
        element.presentingViewController = presenter

        element.chooseTapped()

        XCTAssertEqual(picker.requests.map(\.source), [.CAMERA])
        XCTAssertTrue(element.isPickerPresented)
    }

    func testCameraDeniedShowsErrorAndKeepsSelection() {
        let element = makeElement(options: FileElementOptions(sources: [.FILES, .CAMERA]))
        let existing = storedFile("a.pdf")
        element.handle(FilePickResult(files: [existing]))
        var lastState: [String: Any] = [:]
        element.on(eventName: .CHANGE) { lastState = $0 }

        element.handle(.failed(.cameraAccessDenied))

        XCTAssertEqual(element.files, [existing])
        XCTAssertTrue(exists(existing))
        XCTAssertFalse(element.isValid)
        XCTAssertEqual(element.errorLabel.text, FileInputElement.cameraAccessDeniedMessage)
        XCTAssertEqual(element.reportedError, FileInputElement.cameraAccessDeniedMessage)
        XCTAssertEqual(lastState["isValid"] as? Bool, false)
        XCTAssertEqual(lastState["fileCount"] as? Int, 1)
    }

    func testCameraErrorClearedByNextPickOrClear() {
        let element = makeElement(options: FileElementOptions(sources: [.FILES, .CAMERA]))

        element.handle(.failed(.cameraAccessDenied))
        element.handle(FilePickResult(files: [storedFile("photo_20261119_090507.jpg")]))
        XCTAssertTrue(element.isValid)
        XCTAssertTrue(element.errorLabel.isHidden)

        element.handle(.failed(.cameraUnavailable))
        XCTAssertFalse(element.isValid)
        element.clearValue()
        XCTAssertTrue(element.isValid)
        XCTAssertNil(element.reportedError)
    }

    func testCancelledCameraKeepsPreviousError() {
        let element = makeElement(options: FileElementOptions(sources: [.CAMERA]))
        element.handle(.failed(.cameraAccessDenied))

        element.handle(.cancelled)

        XCTAssertEqual(element.reportedError, FileInputElement.cameraAccessDeniedMessage)
    }

    func testCameraPhotoReplacesMultiFileSelection() {
        let element = makeElement(type: .MULTI_FILE_INPUT, options: FileElementOptions(maxFileCount: 3))
        let previous = [storedFile("a.pdf"), storedFile("b.pdf")]
        element.handle(FilePickResult(files: previous))
        let photo = storedFile("photo_20261119_090507.jpg")

        element.handle(FilePickResult(files: [photo]))

        XCTAssertEqual(element.files, [photo])
        XCTAssertFalse(previous.contains(where: exists))
    }

    // MARK: - Appearances

    private func contains(_ element: FileInputElement, _ view: UIView) -> Bool {
        view.isDescendant(of: element)
    }

    func testFieldIsTheDefaultAppearance() {
        let element = makeElement()

        XCTAssertTrue(contains(element, element.fieldView))
        XCTAssertFalse(contains(element, element.fileListStack))
    }

    func testCustomDrawsNoTriggerOnlyTheFileList() {
        let element = makeElement(appearance: .CUSTOM)

        XCTAssertTrue(contains(element, element.fileListStack))
        XCTAssertFalse(contains(element, element.fieldView))
        XCTAssertFalse(contains(element, element.chooseButton))
    }

    func testOpenPickerOpensLikeATapForCustom() {
        let element = makeElement(appearance: .CUSTOM)
        presenter = UIViewController()
        element.presentingViewController = presenter

        element.openPicker()
        element.openPicker()

        XCTAssertEqual(picker.requests.map(\.source), [.FILES])
        XCTAssertTrue(element.isPickerPresented)
    }

    func testOpenPickerIsIgnoredForField() {
        let element = makeElement()
        presenter = UIViewController()
        element.presentingViewController = presenter

        element.openPicker()

        XCTAssertTrue(picker.requests.isEmpty)
        XCTAssertFalse(element.isPickerPresented)
    }

    func testOpenPickerIgnoredWhenMisconfigured() {
        let element = makeElement(table: "", appearance: .CUSTOM)
        presenter = UIViewController()
        element.presentingViewController = presenter

        element.openPicker()

        XCTAssertTrue(picker.requests.isEmpty)
    }

    func testRowsListEachFileWithItsOwnRemoveButton() {
        let element = makeElement(type: .MULTI_FILE_INPUT, appearance: .CUSTOM)
        let first = storedFile("a.pdf")
        let second = storedFile("b.pdf")
        element.handle(FilePickResult(files: [first, second]))
        var lastState: [String: Any] = [:]
        element.on(eventName: .CHANGE) { lastState = $0 }

        let names = element.fileListStack.arrangedSubviews.compactMap {
            ($0 as? UIStackView)?.arrangedSubviews.first as? UILabel
        }.map(\.text)
        XCTAssertEqual(names, ["a.pdf", "b.pdf"])
        XCTAssertEqual(element.removeButtons.count, 2)

        element.removeFile(at: 0)

        XCTAssertEqual(element.files, [second])
        XCTAssertFalse(exists(first))
        XCTAssertTrue(exists(second))
        XCTAssertEqual(element.removeButtons.count, 1)
        XCTAssertEqual(lastState["fileCount"] as? Int, 1)
    }

    func testRemovingTheLastFileHidesTheErrorAgain() {
        let element = makeElement(appearance: .CUSTOM, options: FileElementOptions(allowedFileType: [".pdf"], sources: [.FILES]))
        element.handle(FilePickResult(files: [storedFile("a.png")]))
        XCTAssertFalse(element.errorLabel.isHidden)

        element.removeFile(at: 0)

        XCTAssertTrue(element.files.isEmpty)
        XCTAssertTrue(element.errorLabel.isHidden)
        XCTAssertTrue(element.fileListStack.isHidden)
    }

    func testUploadingDisablesPickingAndRemoveButtonsForCustom() {
        let element = makeElement(type: .MULTI_FILE_INPUT, appearance: .CUSTOM)
        presenter = UIViewController()
        element.presentingViewController = presenter
        element.handle(FilePickResult(files: [storedFile("a.pdf")]))

        element.isUploading = true

        XCTAssertFalse(element.removeButtons[0].isEnabled)
        element.removeFile(at: 0)
        XCTAssertEqual(element.files.count, 1)
        element.openPicker()
        XCTAssertTrue(picker.requests.isEmpty)

        element.isUploading = false
        XCTAssertTrue(element.removeButtons[0].isEnabled)
    }
}
