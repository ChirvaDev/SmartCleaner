//
//  SimilarVideosViewModel.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import SwiftUI
import Photos
import Combine

@MainActor
final class SimilarVideosViewModel: ObservableObject {

    // MARK: - Published

    @Published var groups: [MediaGroup] = []
    @Published var isLoading: Bool = false
    @Published var showDeleteConfirmation: Bool = false
    @Published var totalVideosCount: Int = 0
    @Published var totalVideosSize: Int64 = 0

    // MARK: - Computed

    var selectedCount: Int { groups.flatMap { $0.assets }.filter { $0.isSelected }.count }
    var selectedSize: Int64 { groups.flatMap { $0.assets }.filter { $0.isSelected }.reduce(0) { $0 + $1.fileSize } }
    var hasSelection: Bool { selectedCount > 0 }
    var isAllSelected: Bool { !groups.isEmpty && groups.flatMap { $0.assets }.allSatisfy { $0.isSelected } }

    var deleteButtonTitle: String {
        let sizeStr = ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
        return "Delete \(selectedCount) videos (\(sizeStr))"
    }

    // MARK: - Load

    func load() {
        guard !isLoading else { return }
        isLoading = true
        groups = []

        Task.detached(priority: .userInitiated) { [weak self] in
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            let fetchResult = PHAsset.fetchAssets(with: .video, options: options)
            var allAssets: [PHAsset] = []
            fetchResult.enumerateObjects { asset, _, _ in allAssets.append(asset) }

            let totalSize = allAssets.reduce(Int64(0)) { $0 + $1.fileSize }
            let count = allAssets.count
            let grouped = await Self.groupBySimilarity(allAssets)

            await MainActor.run { [weak self] in
                self?.totalVideosCount = count
                self?.totalVideosSize = totalSize
                self?.groups = grouped
                self?.isLoading = false
            }
        }
    }

    // MARK: - Grouping by duration + resolution

    private static func groupBySimilarity(_ assets: [PHAsset]) -> [MediaGroup] {
        var buckets: [String: [PHAsset]] = [:]

        for asset in assets {
            // Округлюємо до секунди щоб знайти однакові відео
            let duration = Int(asset.duration.rounded())
            let key = "\(duration)_\(asset.pixelWidth)x\(asset.pixelHeight)"
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

    // MARK: - Selection

    func toggleSelection(assetId: String, in groupId: UUID) {
        guard let gi = groups.firstIndex(where: { $0.id == groupId }),
              let ai = groups[gi].assets.firstIndex(where: { $0.id == assetId }) else { return }
        groups[gi].assets[ai].isSelected.toggle()
    }

    func selectAll(in groupId: UUID) {
        guard let gi = groups.firstIndex(where: { $0.id == groupId }) else { return }
        let allSelected = groups[gi].allSelected
        for ai in groups[gi].assets.indices {
            groups[gi].assets[ai].isSelected = allSelected ? false : true
        }
    }

    func selectAllGroups() {
        for gi in groups.indices {
            for ai in groups[gi].assets.indices {
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

    // MARK: - Delete

    func deleteSelected() async {
        let toDelete = groups.flatMap { $0.assets }.filter { $0.isSelected }.map { $0.asset }
        guard !toDelete.isEmpty else { return }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(toDelete as NSFastEnumeration)
            }
            load()
        } catch {
            print("Delete error: \(error)")
        }
    }
}
