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

    /// Query a single asset's file size from PHAssetResource metadata.
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

    /// Extract file size from PHAssetResource metadata.
    /// Returns the total size of all resources (image + video for Live Photos).
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
