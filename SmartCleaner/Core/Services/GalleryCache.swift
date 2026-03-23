//
//  GalleryCache.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 23.03.2026.
//

import Foundation
import Photos

// MARK: - Gallery Cache
// Зберігає результати групування між сесіями через UserDefaults
// Формат: [[localIdentifier]] — масив груп, кожна група — масив id

final class GalleryCache {

    static let shared = GalleryCache()
    private init() {}

    // MARK: - Keys

    enum Key: String {
        case duplicatePhotos = "cache_duplicate_photos"
        case similarPhotos   = "cache_similar_photos"
        case similarVideos   = "cache_similar_videos"
    }

    // MARK: - Save

    func save(_ groups: [MediaGroup], for key: Key) {
        let data = groups.map { group in
            group.assets.map { $0.id }
        }
        // 1. Рахуємо загальну кількість файлів у всіх групах
        let totalFilesCount = groups.reduce(0) { $0 + $1.assets.count }
        
        // 2. Зберігаємо структуру (масиви ID)
        UserDefaults.standard.set(data, forKey: key.rawValue)
        UserDefaults.standard.set(Date(), forKey: key.rawValue + "_date")
        
        // 3. ЗБЕРІГАЄМО ЧИСЛО (яке потім читає getCountQuickly)
        UserDefaults.standard.set(totalFilesCount, forKey: key.rawValue + "_count")
    }

    // MARK: - Load

    // Повертає групи з кешу або nil якщо кешу немає
    func load(for key: Key, from fetchResult: [PHAsset]) -> [MediaGroup]? {
        guard let raw = UserDefaults.standard.array(forKey: key.rawValue) as? [[String]] else {
            return nil
        }

        // Будуємо словник asset по localIdentifier для швидкого пошуку
        let assetMap = Dictionary(uniqueKeysWithValues: fetchResult.map { ($0.localIdentifier, $0) })

        let groups: [MediaGroup] = raw.compactMap { ids in
            let assets = ids.compactMap { assetMap[$0] }
            guard assets.count >= 2 else { return nil }

            let bestId = assets.max(by: { $0.fileSize < $1.fileSize })?.localIdentifier
            let mediaAssets = assets.map { asset in
                MediaAsset(
                    id: asset.localIdentifier,
                    asset: asset,
                    isBest: asset.localIdentifier == bestId,
                    isSelected: false
                )
            }
            return MediaGroup(assets: mediaAssets)
        }

        return groups.isEmpty ? nil : groups
    }

    // MARK: - Clear

    func clear(_ key: Key) {
        UserDefaults.standard.removeObject(forKey: key.rawValue)
        UserDefaults.standard.removeObject(forKey: key.rawValue + "_date")
    }

    // MARK: - Cache date

    func lastUpdated(for key: Key) -> Date? {
        UserDefaults.standard.object(forKey: key.rawValue + "_date") as? Date
    }
    
    func getCountQuickly(for key: Key) -> Int {
            return UserDefaults.standard.integer(forKey: key.rawValue + "_count")
        }
}
