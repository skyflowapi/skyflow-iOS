/*
 * Copyright (c) 2022 Skyflow
*/

// Reads a picked photo straight from the Photos library, so no copy of it is made until
// upload. Used only when the app already has full photo library access for its own features;
// the SDK never asks for that permission. Without it, picked photos are copied into
// SecureFileStore as before.

import Foundation
#if canImport(Photos)
import Photos
#endif

internal struct PhotoAssetInfo: Equatable {
    let name: String
    let size: Int
    let typeIdentifier: String
}

internal protocol PhotoAssetLibrary {
    /// True only for full access. Reading the status never shows a prompt.
    var hasFullAccess: Bool { get }
    /// Name, size and type of the photo, or nil when it cannot be read by identifier.
    func info(forAssetID id: String) -> PhotoAssetInfo?
    /// Streams the photo's bytes in order on a background queue, then calls `completion`
    /// once, with nil on success.
    func streamData(forAssetID id: String, onChunk: @escaping (Data) throws -> Void,
                    completion: @escaping (Error?) -> Void)
}

internal enum PhotoAssetError: Error {
    case unavailable
}

internal struct SystemPhotoAssetLibrary: PhotoAssetLibrary {
    var hasFullAccess: Bool {
        if #available(iOS 14, *) {
            return PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized
        }
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }

    func info(forAssetID id: String) -> PhotoAssetInfo? {
        guard hasFullAccess, let resource = Self.resource(forAssetID: id),
              let original = Self.originalResource(forAssetID: id) else {
            return nil
        }
        // The size is not public API on PHAssetResource. Without it the size limits cannot be
        // checked at pick time, so the caller falls back to copying the photo.
        guard let size = (resource.value(forKey: "fileSize") as? NSNumber)?.intValue, size > 0 else {
            return nil
        }
        // An edited photo's rendered resource is named "FullSizeRender.*", so the name comes
        // from the original and the extension from the resource actually uploaded.
        let base = (original.originalFilename as NSString).deletingPathExtension
        let ext = (resource.originalFilename as NSString).pathExtension
        return PhotoAssetInfo(name: ext.isEmpty ? base : "\(base).\(ext)", size: size,
                              typeIdentifier: resource.uniformTypeIdentifier)
    }

    func streamData(forAssetID id: String, onChunk: @escaping (Data) throws -> Void,
                    completion: @escaping (Error?) -> Void) {
        guard hasFullAccess, let resource = Self.resource(forAssetID: id) else {
            completion(PhotoAssetError.unavailable)
            return
        }
        let options = PHAssetResourceRequestOptions()
        // iCloud photos with "Optimize iPhone Storage" are downloaded during the upload.
        options.isNetworkAccessAllowed = true
        var chunkError: Error?
        PHAssetResourceManager.default().requestData(for: resource, options: options, dataReceivedHandler: { chunk in
            guard chunkError == nil else { return }
            do { try onChunk(chunk) } catch { chunkError = error }
        }, completionHandler: { error in
            completion(chunkError ?? error)
        })
    }

    private static func asset(forAssetID id: String) -> PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
    }

    // What the user sees in Photos: the edited version when there is one, else the original.
    private static func resource(forAssetID id: String) -> PHAssetResource? {
        guard let asset = asset(forAssetID: id) else { return nil }
        let resources = PHAssetResource.assetResources(for: asset)
        return resources.first { $0.type == .fullSizePhoto } ?? resources.first { $0.type == .photo }
    }

    private static func originalResource(forAssetID id: String) -> PHAssetResource? {
        guard let asset = asset(forAssetID: id) else { return nil }
        return PHAssetResource.assetResources(for: asset).first { $0.type == .photo }
    }
}
