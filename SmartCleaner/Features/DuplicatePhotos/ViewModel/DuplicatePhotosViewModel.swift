//
//  DuplicatePhotosViewModel.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import SwiftUI
import Photos
import Combine

@MainActor
final class DuplicatePhotosViewModel: ObservableObject {

    // MARK: - Published
    @Published var groups: [MediaGroup] = []
    @Published var isLoading: Bool = false
    @Published var totalPhotosCount: Int = 0
    @Published var totalPhotosSize: Int64 = 0
    @Published var scrollToGroupId: UUID? = nil

    // MARK: - Computed

    var selectedCount: Int {
        groups.flatMap { $0.assets }.filter { $0.isSelected }.count
    }

    var selectedSize: Int64 {
        groups.flatMap { $0.assets }.filter { $0.isSelected }.reduce(0) { $0 + $1.fileSize }
    }

    var hasSelection: Bool { selectedCount > 0 }

    var deleteButtonTitle: String {
        let sizeStr = ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
        return "Delete \(selectedCount) photos (\(sizeStr))"
    }

    // MARK: - Load (cache-first)
    
    func load() {
        guard !isLoading else { return }
        isLoading = true

        Task.detached(priority: .userInitiated) { [weak self] in
            let fetchResult = PHAsset.fetchAssets(with: .image, options: nil)
            var allAssets: [PHAsset] = []
            fetchResult.enumerateObjects { asset, _, _ in allAssets.append(asset) }

            // 1. Спробуємо завантажити кеш
            if let cached = await GalleryCache.shared.load(for: .duplicatePhotos, from: allAssets) {
                let cachedCount = cached.flatMap { $0.assets }.count
                
                await MainActor.run { [weak self] in
                    self?.groups = cached
                    self?.totalPhotosCount = cachedCount
                    // Рахуємо розмір тут, де доступ до MainActor відкритий
                    self?.totalPhotosSize = cached.flatMap { $0.assets }.reduce(0) { $0 + $1.fileSize }
                    self?.isLoading = false
                }
            }

            // 2. Свіжий розрахунок у фоні
            let fresh = await Self.groupByDuplicateKey(allAssets)
            let freshDuplicatesCount = fresh.flatMap { $0.assets }.count
            
            // Зберігаємо в кеш 
            await GalleryCache.shared.save(fresh, for: .duplicatePhotos)

            await MainActor.run { [weak self] in
                guard let self = self else { return }
                
                if self.groups.count != fresh.count || self.totalPhotosCount != freshDuplicatesCount {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.groups = fresh
                        self.totalPhotosCount = freshDuplicatesCount
                        // Рахуємо розмір тут
                        self.totalPhotosSize = fresh.flatMap { $0.assets }.reduce(0) { $0 + $1.fileSize }
                    }
                }
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Selection

    func toggleSelection(assetId: String, in groupId: UUID) {
        guard let gi = groups.firstIndex(where: { $0.id == groupId }),
              let ai = groups[gi].assets.firstIndex(where: { $0.id == assetId }) else { return }
        groups[gi].assets[ai].isSelected.toggle()
    }

    func selectAll(in groupId: UUID) {
        guard let gi = groups.firstIndex(where: { $0.id == groupId }) else { return }
        let allNonBestSelected = groups[gi].assets
            .filter { !$0.isBest }
            .allSatisfy { $0.isSelected }

        for ai in groups[gi].assets.indices {
            if groups[gi].assets[ai].isBest { continue }
            groups[gi].assets[ai].isSelected = !allNonBestSelected
        }
    }

    func selectAllGroups() {
        for gi in groups.indices {
            for ai in groups[gi].assets.indices {
                if groups[gi].assets[ai].isBest { continue }
                groups[gi].assets[ai].isSelected = true
            }
        }
    }

    func deselectAll() {
        for gi in groups.indices {
            for ai in groups[gi].assets.indices {
                groups[gi].assets[ai].isSelected = false
            }
        }
    }

    var isAllSelected: Bool {
        let nonBestAssets = groups.flatMap { $0.assets }.filter { !$0.isBest }
        guard !nonBestAssets.isEmpty else { return false }
        return nonBestAssets.allSatisfy { $0.isSelected }
    }

    // MARK: - Delete (optimistic)
    func deleteSelected() async {
        let toDelete = groups
            .flatMap { $0.assets }
            .filter { $0.isSelected }
            .map { $0.asset }

        guard !toDelete.isEmpty else { return }

        // 1. Зберігаємо поточний стан на випадок скасування
        let previousGroups = self.groups
        let previousCount = self.totalPhotosCount
        let previousSize = self.totalPhotosSize

        // 2. Оптимістичне оновлення UI
        withAnimation(.easeInOut(duration: 0.25)) {
            for gi in groups.indices {
                groups[gi].assets.removeAll { $0.isSelected }
            }
            groups.removeAll { $0.assets.count < 2 }
            
            // Оновлюємо статистику
            let remaining = groups.flatMap { $0.assets }
            totalPhotosCount = remaining.count
            totalPhotosSize = remaining.reduce(Int64(0)) { $0 + $1.fileSize }
        }

        // 3. Реальне видалення
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(toDelete as NSFastEnumeration)
            }
            // Якщо успішно — оновлюємо кеш
            GalleryCache.shared.save(groups, for: .duplicatePhotos)
        } catch {
            // 4. КОРИСТУВАЧ СКАСУВАВ АБО СТАЛАСЯ ПОМИЛКА
            // Повертаємо старі дані БЕЗ виклику load()
            withAnimation(.easeInOut(duration: 0.25)) {
                self.groups = previousGroups
                self.totalPhotosCount = previousCount
                self.totalPhotosSize = previousSize
            }
            print("Видалення скасовано або помилка: \(error)")
        }
    }
    
    // MARK: - Grouping

    private static func groupByDuplicateKey(_ assets: [PHAsset]) -> [MediaGroup] {
        var buckets: [String: [PHAsset]] = [:]

        for asset in assets {
            let timestamp = Int(asset.creationDate?.timeIntervalSince1970 ?? 0)
            let key = "\(timestamp)_\(asset.pixelWidth)x\(asset.pixelHeight)"
            buckets[key, default: []].append(asset)
        }

        return buckets.values
            .filter { $0.count >= 2 }
            .map { groupAssets in
                let bestId = groupAssets.max(by: { $0.fileSize < $1.fileSize })?.localIdentifier
                let mediaAssets = groupAssets.map { asset in
                    MediaAsset(
                        id: asset.localIdentifier,
                        asset: asset,
                        isBest: asset.localIdentifier == bestId,
                        isSelected: false
                    )
                }
                return MediaGroup(assets: mediaAssets)
            }
            .sorted { $0.assets.count > $1.assets.count }
    }
}
