//
//  SimilarPhotosViewModel.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 23.03.2026.
//

import SwiftUI
import Photos
import Combine
import Vision

@MainActor
final class SimilarPhotosViewModel: ObservableObject {
    
    // MARK: - Published State
        @Published var groups: [MediaGroup] = []
        @Published var isLoading: Bool = false
        
        @Published var totalPhotosCount: Int = 0
        @Published var totalPhotosSize: Int64 = 0
        
        @Published var selectedCount: Int = 0
        @Published var selectedSize: Int64 = 0

        // MARK: - Light Computed Properties
        var hasSelection: Bool { selectedCount > 0 }
        
        var isAllSelected: Bool {
            let totalNonBest = totalPhotosCount - groups.count
            return selectedCount >= totalNonBest && totalNonBest > 0
        }

        var deleteButtonTitle: String {
            let sizeStr = ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
            return "Delete \(selectedCount) photos (\(sizeStr))"
        }


    // MARK: - Load
    func load() {
        guard !isLoading else { return }
        if groups.isEmpty { isLoading = true }

        Task.detached(priority: .userInitiated) { [weak self] in
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
            
            var allAssets: [PHAsset] = []
            fetchResult.enumerateObjects { asset, _, _ in allAssets.append(asset) }

            // 1. Завантаження кешу
            if let cached = await GalleryCache.shared.load(for: .similarPhotos, from: allAssets) {
                await MainActor.run { [weak self] in
                    if self?.groups.isEmpty == true {
                        self?.groups = cached
                        // ОНОВЛЮЄМО СТАТИСТИКУ ДЛЯ КЕШУ
                        self?.updateTotals(from: cached)
                    }
                }
            }

            // 2. Свіжий Vision аналіз
            let fresh = await Self.groupByVisualSimilarity(allAssets)
            await GalleryCache.shared.save(fresh, for: .similarPhotos)

            await MainActor.run { [weak self] in
                if self?.groups.count != fresh.count {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.groups = fresh
                        // ОНОВЛЮЄМО СТАТИСТИКУ ДЛЯ СВІЖИХ ДАНИХ
                        self?.updateTotals(from: fresh)
                    }
                } else if self?.totalPhotosCount == 0 && !fresh.isEmpty {
                    // На випадок, якщо кількість груп збіглася з кешем, але статистика ще 0
                    self?.updateTotals(from: fresh)
                }
                self?.isLoading = false
            }
        }
    }
    
    // MARK: - Grouping
     static func groupByVisualSimilarity(
        _ assets: [PHAsset],
        window: TimeInterval = 5,
        featureThreshold: Float = 0.3,
        histThreshold: Float = 0.05  // дуже строго
    ) async -> [MediaGroup] {
        guard !assets.isEmpty else { return [] }

        var prints: [VNFeaturePrintObservation?] = Array(repeating: nil, count: assets.count)
        var images: [UIImage?] = Array(repeating: nil, count: assets.count)
        let batchSize = 8

        for batchStart in stride(from: 0, to: assets.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, assets.count)
            await withTaskGroup(of: (Int, VNFeaturePrintObservation?, UIImage?).self) { group in
                for i in batchStart..<batchEnd {
                    group.addTask {
                        let (fp, img) = await featurePrint(for: assets[i])
                        return (i, fp, img)
                    }
                }
                for await (i, fp, img) in group {
                    prints[i] = fp
                    images[i] = img
                }
            }
        }

        // Рахуємо гістограми
        let histograms: [[Float]?] = images.map { img in
            guard let img else { return nil }
            return histogram(from: img)
        }

        var groups: [[PHAsset]] = []
        var currentGroup: [PHAsset] = [assets[0]]
        var groupStartDate = assets[0].creationDate ?? .distantPast
        var groupStartPrint = prints[0]
        var groupStartHist = histograms[0]

        for i in 1..<assets.count {
            let curr = assets[i]
            let currDate = curr.creationDate ?? .distantPast
            let withinTime = currDate.timeIntervalSince(groupStartDate) <= window
            let notScreenshot = !isScreenshot(curr)

            // Обидві умови мають виконатись
            var featureSimilar = true
            if let p1 = groupStartPrint, let p2 = prints[i] {
                featureSimilar = featurePrintDistance(p1, p2) < featureThreshold
            }

            var histSimilar = true
            if let h1 = groupStartHist, let h2 = histograms[i] {
                histSimilar = histogramDistance(h1, h2) < histThreshold
            }

            if withinTime && featureSimilar && histSimilar && notScreenshot {
                currentGroup.append(curr)
            } else {
                if currentGroup.count >= 2 { groups.append(currentGroup) }
                currentGroup = [curr]
                groupStartDate = currDate
                groupStartPrint = prints[i]
                groupStartHist = histograms[i]
            }
        }
        if currentGroup.count >= 2 { groups.append(currentGroup) }

        return groups
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
    
    // MARK: - Vision Helpers
    private static func featurePrint(for asset: PHAsset) async -> (VNFeaturePrintObservation?, UIImage?) {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.resizeMode = .fast
            options.deliveryMode = .fastFormat
            options.isNetworkAccessAllowed = false

            var hasResumed = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 224, height: 224),
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                guard !hasResumed else { return }
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if isDegraded { return }
                hasResumed = true

                guard let cgImage = image?.cgImage else {
                    continuation.resume(returning: (nil, nil))
                    return
                }

                let request = VNGenerateImageFeaturePrintRequest()
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
                let fp = request.results?.first as? VNFeaturePrintObservation
                continuation.resume(returning: (fp, image))
            }
        }
    }

    // Гістограма по 8 бінах для R, G, B — разом 24 значення
    private static func histogram(from image: UIImage) -> [Float]? {
        guard let cgImage = image.cgImage,
              let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bins = 8
        var rHist = [Float](repeating: 0, count: bins)
        var gHist = [Float](repeating: 0, count: bins)
        var bHist = [Float](repeating: 0, count: bins)
        let total = Float(width * height)

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * cgImage.bytesPerRow + x * bytesPerPixel
                let r = Int(bytes[offset])
                let g = Int(bytes[offset + 1])
                let b = Int(bytes[offset + 2])
                rHist[r * bins / 256] += 1
                gHist[g * bins / 256] += 1
                bHist[b * bins / 256] += 1
            }
        }

        // Нормалізуємо
        let hist = (rHist + gHist + bHist).map { $0 / total }
        return hist
    }

    // Відстань між гістограмами (Bhattacharyya)
    private static func histogramDistance(_ a: [Float], _ b: [Float]) -> Float {
        var bc: Float = 0
        for i in 0..<a.count {
            bc += sqrt(a[i] * b[i])
        }
        return 1.0 - bc  // 0 = ідентичні, 1 = повністю різні
    }

    private static func featurePrintDistance(_ a: VNFeaturePrintObservation,
                                              _ b: VNFeaturePrintObservation) -> Float {
        var distance: Float = 0
        try? a.computeDistance(&distance, to: b)
        return distance
    }

    private static func isScreenshot(_ asset: PHAsset) -> Bool {
        asset.mediaSubtypes.contains(.photoScreenshot) ||
        asset.mediaSubtypes.contains(.photoPanorama)
    }

    // MARK: - Selection
    private func updateSelectionStats() {
            var count = 0
            var size: Int64 = 0
            for group in groups {
                for asset in group.assets {
                    if asset.isSelected {
                        count += 1
                        size += asset.fileSize
                    }
                }
            }
            self.selectedCount = count
            self.selectedSize = size
        }
    
    private func updateTotals(from freshGroups: [MediaGroup]) {
        let allAssets = freshGroups.flatMap { $0.assets }
        self.totalPhotosCount = allAssets.count
        self.totalPhotosSize = allAssets.reduce(0) { $0 + $1.fileSize }
    }
    
    func toggleSelection(assetId: String, in groupId: UUID) {
        guard let gi = groups.firstIndex(where: { $0.id == groupId }),
              let ai = groups[gi].assets.firstIndex(where: { $0.id == assetId }) else { return }
        groups[gi].assets[ai].isSelected.toggle()
        updateSelectionStats()
    }

    func selectAll(in groupId: UUID) {
        guard let gi = groups.firstIndex(where: { $0.id == groupId }) else { return }
        let allSelected = groups[gi].allSelected
        for ai in groups[gi].assets.indices {
            groups[gi].assets[ai].isSelected = allSelected ? false : true
        }
        updateSelectionStats()
    }

    func selectAllGroups() {
        for gi in groups.indices {
            for ai in groups[gi].assets.indices {
                groups[gi].assets[ai].isSelected = true
            }
        }
        updateSelectionStats()
    }

    func deselectAll() {
        for gi in groups.indices {
            for ai in groups[gi].assets.indices {
                groups[gi].assets[ai].isSelected = false
            }
        }
        updateSelectionStats()
    }

    // MARK: - Delete
    func deleteSelected() async {
        let toDeleteAssets = groups.flatMap { $0.assets }.filter { $0.isSelected }
        let phAssetsToDelete = toDeleteAssets.map { $0.asset }
        guard !phAssetsToDelete.isEmpty else { return }

        // Робимо бекап на випадок натискання кнопки "Скасувати" у системному вікні
        let backupGroups = self.groups

        // 1. Оптимістичне видалення з інтерфейсу (миттєво)
        withAnimation(.easeInOut(duration: 0.25)) {
            for i in groups.indices {
                groups[i].assets.removeAll { $0.isSelected }
            }
            // Прибираємо групи, де залишилося менше 2-х фото (вони більше не схожі)
            groups.removeAll { $0.assets.count < 2 }
            
            updateTotals(from: self.groups)
            updateSelectionStats()
        }

        // 2. Видалення з системної бібліотеки
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(phAssetsToDelete as NSFastEnumeration)
            }
            // Успішно видалено — оновлюємо кеш
             GalleryCache.shared.save(groups, for: .similarPhotos)
        } catch {
            // Якщо користувач скасував або сталася помилка — повертаємо фото назад у список
            withAnimation(.easeInOut(duration: 0.25)) {
                self.groups = backupGroups
            }
            print("Видалення відхилено: \(error.localizedDescription)")
        }
    }
}

