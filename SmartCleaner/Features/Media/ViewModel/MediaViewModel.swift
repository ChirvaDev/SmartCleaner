//
//  MediaViewModel.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import SwiftUI
import Photos
import Combine

@MainActor
final class MediaViewModel: ObservableObject {
    
    @Published var categories: [MediaCategory] = MediaCategoryType.allCases.map {
        MediaCategory(type: $0, itemCount: 0)
    }
    
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    
    init() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if authorizationStatus == .authorized || authorizationStatus == .limited {
            // Викликаємо асинхронний метод із синхронного ініціалізатора через Task
            Task { await fetchRealCounts() }
        }
    }
    
    func requestAccessIfNeeded() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            Task { @MainActor in
                self?.authorizationStatus = status
                if status == .authorized || status == .limited {
                    await self?.fetchRealCounts()
                }
            }
        }
    }
    
    // Робимо функцію асинхронною
    func fetchRealCounts() async {
        try? await Task.sleep(nanoseconds: 100_000_000)
        // 1. Спершу ініціалізуємо поточними значеннями (або 0)
        var results = [MediaCategoryType: Int]()
        for cat in categories {
            results[cat.type] = cat.itemCount
        }

        // 2. Створюємо групу тасків для паралельного підрахунку
        await withTaskGroup(of: (MediaCategoryType, Int).self) { group in
            for type in MediaCategoryType.allCases {
                group.addTask {
                    let count = await self.getCount(for: type)
                    return (type, count)
                }
            }
            
            for await (type, count) in group {
                // Оновлюємо результат для конкретного типу
                results[type] = count
                
                // Оновлюємо UI на головному потоці відразу після отримання кожної цифри
                await MainActor.run {
                    self.categories = MediaCategoryType.allCases.map { type in
                        MediaCategory(type: type, itemCount: results[type] ?? 0)
                    }
                }
            }
        }
    }
    
    // Додаємо async до сигнатури
    private func getCount(for type: MediaCategoryType) async -> Int {
        let options = PHFetchOptions()
        
        switch type {
        case .duplicatePhotos:
            return await getDuplicatesCount()
            
        case .similarPhotos:
            return await getSimilarPhotosCount()
            
        case .screenshots:
            options.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoScreenshot.rawValue)
            return PHAsset.fetchAssets(with: .image, options: options).count
            
        case .livePhotos:
            options.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoLive.rawValue)
            return PHAsset.fetchAssets(with: .image, options: options).count
            
        case .screenRecordings:
            options.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.videoScreenRecording.rawValue)
            return PHAsset.fetchAssets(with: .video, options: options).count
            
        case .similarVideos:
            return PHAsset.fetchAssets(with: .video, options: nil).count
        }
    }
    
    private func getDuplicatesCount() async -> Int {
        // Виносимо важку роботу в фоновий потік (detached task)
        return await Task.detached(priority: .background) {
            let fetchOptions = PHFetchOptions()
            let allPhotosFetch = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            var buckets: [String: Int] = [:]
            
            allPhotosFetch.enumerateObjects { asset, _, _ in
                let timestamp = Int(asset.creationDate?.timeIntervalSince1970 ?? 0)
                let key = "\(timestamp)_\(asset.pixelWidth)x\(asset.pixelHeight)"
                buckets[key, default: 0] += 1
            }
            
            let duplicateCount = buckets.values
                .filter { $0 >= 2 }
                .reduce(0, +)
            
            return duplicateCount
        }.value
    }
    
    private func getSimilarPhotosCount() async -> Int {
        return GalleryCache.shared.getCountQuickly(for: .similarPhotos)
    }
}
