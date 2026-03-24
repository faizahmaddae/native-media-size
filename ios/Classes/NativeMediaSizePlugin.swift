import Flutter
import Photos
import UIKit

public class NativeMediaSizePlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "native_media_size",
            binaryMessenger: registrar.messenger()
        )
        let instance = NativeMediaSizePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getFileSize":
            guard let args = call.arguments as? [String: Any],
                  let assetId = args["assetId"] as? String else {
                result(FlutterError(code: "INVALID_ARG", message: "assetId is required", details: nil))
                return
            }
            result(querySize(assetId: assetId))

        case "getFileSizes":
            guard let args = call.arguments as? [String: Any],
                  let assetIds = args["assetIds"] as? [String] else {
                result([String: Int]())
                return
            }
            result(querySizes(assetIds: assetIds))

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // ─── IMPORTANT ────────────────────────────────────────────────
    // `value(forKey: "fileSize")` is NOT part of Apple's public API for
    // PHAssetResource. It works reliably as of iOS 18, but Apple DTS has
    // stated it may stop working in a future version.
    //
    // If Apple removes this key, the methods below will return nil/empty
    // rather than crash — callers should handle nil gracefully.
    //
    // The official alternative (PHAssetResourceManager.requestData) requires
    // reading the full file data, which defeats the purpose of a fast
    // metadata-only query.
    // ──────────────────────────────────────────────────────────────

    /// Query a single asset's file size from PHAssetResource metadata.
    /// Returns nil if the asset is not found or the fileSize key is unavailable.
    private func querySize(assetId: String) -> NSNumber? {
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [assetId],
            options: nil
        )
        guard let asset = fetchResult.firstObject else { return nil }
        return fileSizeForAsset(asset)
    }

    /// Batch query file sizes for multiple assets.
    private func querySizes(assetIds: [String]) -> [String: NSNumber] {
        var result = [String: NSNumber]()
        if assetIds.isEmpty { return result }

        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: assetIds,
            options: nil
        )

        fetchResult.enumerateObjects { asset, _, _ in
            if let size = self.fileSizeForAsset(asset) {
                result[asset.localIdentifier] = size
            }
        }

        return result
    }

    /// Extract file size from PHAssetResource metadata (undocumented key).
    /// Returns the total size of all resources (image + video for Live Photos).
    /// May return nil if Apple removes the "fileSize" key in a future iOS version.
    private func fileSizeForAsset(_ asset: PHAsset) -> NSNumber? {
        let resources = PHAssetResource.assetResources(for: asset)
        var totalSize: Int64 = 0

        for resource in resources {
            if let sizeValue = resource.value(forKey: "fileSize") as? Int64 {
                totalSize += sizeValue
            }
        }

        return totalSize > 0 ? NSNumber(value: totalSize) : nil
    }
}
