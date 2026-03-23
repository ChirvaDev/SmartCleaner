//
//  ThumbnailCache.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import Photos
import UIKit

// MARK: - ThumbnailCache
// Централізований кеш для thumbnails через PHCachingImageManager

final class ThumbnailCache {

    static let shared = ThumbnailCache()

    private let imageManager = PHCachingImageManager()
    private var cache = NSCache<NSString, UIImage>()

    static let thumbnailSize = CGSize(width: 200, height: 200)

    private init() {
        cache.countLimit = 300
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    // MARK: - Prefetch (коли група стає видимою)

    func startCaching(_ assets: [PHAsset]) {
        let options = cachingOptions()
        imageManager.startCachingImages(
            for: assets,
            targetSize: Self.thumbnailSize,
            contentMode: .aspectFill,
            options: options
        )
    }

    func stopCaching(_ assets: [PHAsset]) {
        let options = cachingOptions()
        imageManager.stopCachingImages(
            for: assets,
            targetSize: Self.thumbnailSize,
            contentMode: .aspectFill,
            options: options
        )
    }

    // MARK: - Load

    func image(for asset: PHAsset) async -> UIImage? {
        let key = asset.localIdentifier as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        return await withCheckedContinuation { continuation in
            let options = requestOptions()
            var didResume = false

            imageManager.requestImage(
                for: asset,
                targetSize: Self.thumbnailSize,
                contentMode: .aspectFill,
                options: options
            ) { [weak self] image, info in
                let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false

                // Пропускаємо degraded версію — чекаємо фінальну
                if isDegraded { return }

                guard !didResume else { return }
                didResume = true

                if let image {
                    self?.cache.setObject(image, forKey: key, cost: Int(Self.thumbnailSize.width * Self.thumbnailSize.height * 4))
                }
                continuation.resume(returning: image)
            }
        }
    }

    // MARK: - Options

    private func cachingOptions() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        return options
    }

    private func requestOptions() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        return options
    }
}
