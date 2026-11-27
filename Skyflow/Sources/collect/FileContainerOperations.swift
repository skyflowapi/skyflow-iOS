/*
 * Copyright (c) 2022 Skyflow
*/

// File element creation and uploadFiles() on the collect container (Skyflow SDK only).

import Foundation

public extension Container {
    /// Creates a file element from a `CollectElementInput` with `type: .FILE_INPUT` or
    /// `.MULTI_FILE_INPUT`, as skyflow-js does with `create()`. A separate label is needed because
    /// `create(input:)` returns a `TextField`.
    func create(fileInput: CollectElementInput, options: CollectElementOptions = CollectElementOptions()) -> FileInputElement where T: CollectContainer {
        var contextOptions = skyflow.contextOptions
        contextOptions.interface = .COLLECT_CONTAINER
        let input = fileInput.fileInput ?? Self.notFileTypeInput(fileInput)
        let element = FileInputElement(input: input, options: options.fileOptions, contextOptions: contextOptions, store: .shared)
        fileElements.append(element)
        Log.info(message: .CREATED_ELEMENT, values: [input.label.isEmpty ? "file" : input.label], contextOptions: contextOptions)
        return element
    }

    // create() cannot fail, so a text-field input becomes an element whose configuration error
    // is reported by uploadFiles(), like other invalid settings.
    private static func notFileTypeInput(_ input: CollectElementInput) -> FileElementInput {
        var file = FileElementInput(table: input.data.tableName, column: input.data.column, label: input.data.label,
                                    type: .FILE_INPUT)
        file.isNotFileType = true
        return file
    }

    /// Uploads the files selected in this container's file elements, one record per file.
    ///
    /// - `onSuccess`: `["fileUploadResponse": [[String: Any]]]`, one entry per file in element
    ///   creation order, then selection order. Each entry is the vault response (`skyflow_id`,
    ///   plus `fileMetadata` when `returnFileMetadata` is set).
    /// - `onFailure`: a `SkyflowError` when nothing was sent (invalid configuration, invalid or
    ///   unmounted elements, token failure); otherwise `["errorResponse": [...]]`, plus
    ///   `"fileUploadResponse"` when some files succeeded.
    ///
    /// Optional elements with no file are skipped. Uploaded files are removed from their
    /// elements; failed files stay selected so the call can be retried.
    func uploadFiles(callback: Callback) where T: CollectContainer {
        // Elements are UIKit views, so all element state is read and changed on the main queue.
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.uploadFiles(callback: callback) }
            return
        }
        uploadFiles(callback: callback, session: URLSession(configuration: .ephemeral))
    }
}

extension Container {
    // `session` is injectable for tests. Ephemeral: no on-disk cache or cookies for requests
    // that carry file contents and a bearer token.
    internal func uploadFiles(callback: Callback, session: URLSession, store: SecureFileStore = .shared) where T: CollectContainer {
        var contextOptions = skyflow.contextOptions
        contextOptions.interface = .COLLECT_CONTAINER

        let fail: (SkyflowError) -> Void = { error in
            session.invalidateAndCancel()
            callback.onFailure(error)
        }
        if let errorCode = CoreRequestValidators.checkClientConfig(vaultID: skyflow.vaultID, vaultURL: skyflow.vaultURL) {
            return fail(SkyflowError.wrap(errorCode.getErrorObject(contextOptions: contextOptions)))
        }

        let elements = fileElements.compactMap { $0 as? FileInputElement }
        guard elements.isEmpty == false else {
            return fail(FileErrorCode.noFileElements.getErrorObject(contextOptions: contextOptions))
        }
        guard elements.contains(where: \.isUploading) == false else {
            return fail(FileErrorCode.uploadInProgress.getErrorObject(contextOptions: contextOptions))
        }
        for element in elements {
            if case .failure(let error) = element.configurationResult {
                return fail(error.getErrorObject(contextOptions: contextOptions))
            }
        }
        if let unmounted = elements.first(where: { $0.isMounted == false }) {
            let column = unmounted.configuration?.column ?? ""
            return fail(SkyflowError.wrap(ErrorCodes.UNMOUNTED_COLLECT_ELEMENT(value: column).getErrorObject(contextOptions: contextOptions)))
        }

        // Validate every element (not just the first invalid one) so all errors show at once.
        let invalid = elements.compactMap { element -> String? in
            guard let error = element.validateForUpload() else { return nil }
            return "for \(element.configuration?.column ?? "") \(error)"
        }
        if invalid.isEmpty == false {
            let details = "\(LangAndVersion) Validation error. Invalid file elements:\n" + invalid.joined(separator: "\n")
            return fail(FileErrorCode.invalidElements(details: details).getErrorObject(contextOptions: contextOptions))
        }

        let batches = elements.map { (element: $0, jobs: $0.makeUploadJobs()) }
        let jobs = batches.flatMap(\.jobs)
        guard jobs.isEmpty == false else {
            session.finishTasksAndInvalidate()
            callback.onSuccess(["fileUploadResponse": [[String: Any]]()])
            return
        }

        elements.forEach { $0.isUploading = true }
        let uploader = FileUploader(apiClient: skyflow.apiClient, session: session, store: store, contextOptions: contextOptions)
        uploader.upload(jobs, onTokenFailure: { error in
            elements.forEach { $0.isUploading = false }
            session.invalidateAndCancel()
            callback.onFailure(error)
        }, completion: { outcomes in
            session.finishTasksAndInvalidate()
            elements.forEach { $0.isUploading = false }

            var successes: [[String: Any]] = []
            var failures: [[String: Any]] = []
            var outcomeIndex = 0
            for batch in batches {
                var uploaded = Set<UUID>()
                for job in batch.jobs {
                    switch outcomes[outcomeIndex] {
                    case .success(let entry):
                        successes.append(entry)
                        uploaded.insert(job.file.id)
                    case .failure(let entry):
                        failures.append(entry)
                    }
                    outcomeIndex += 1
                }
                batch.element.markUploaded(uploaded)
            }

            if failures.isEmpty {
                Log.info(message: .COLLECT_SUBMIT_SUCCESS, contextOptions: contextOptions)
                callback.onSuccess(["fileUploadResponse": successes])
            } else if successes.isEmpty {
                callback.onFailure(["errorResponse": failures])
            } else {
                callback.onFailure(["fileUploadResponse": successes, "errorResponse": failures])
            }
        })
    }
}
