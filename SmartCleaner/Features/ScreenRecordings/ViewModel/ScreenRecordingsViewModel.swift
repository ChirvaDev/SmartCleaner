//
//  ScreenRecordingsViewModel.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import SwiftUI
import Photos
import Combine

// MARK: - ScreenRecordingsViewModel

@MainActor
final class ScreenRecordingsViewModel: ObservableObject {

    // MARK: - Published

    @Published var assets: [MediaAsset] = []
    @Published var isLoading: Bool = false
    @Published var showDeleteConfirmation: Bool = false
    @Published var totalSize: Int64 = 0

    // MARK: - Computed

    var selectedAssets: [MediaAsset] { assets.filter { $0.isSelected } }
    var selectedCount: Int { selectedAssets.count }
    var selectedSize: Int64 { selectedAssets.reduce(0) { $0 + $1.fileSize } }
    var hasSelection: Bool { selectedCount > 0 }
    var isAllSelected: Bool { !assets.isEmpty && assets.allSatisfy { $0.isSelected } }

    var deleteButtonTitle: String {
        let sizeStr = ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
        return "Delete \(selectedCount) videos (\(sizeStr))"
    }

    // MARK: - Load

    func load() {
        guard !isLoading else { return }
        isLoading = true
        assets = []

        Task.detached(priority: .userInitiated) { [weak self] in
            let options = PHFetchOptions()
            options.predicate = NSPredicate(
                format: "mediaSubtype & %d != 0",
                PHAssetMediaSubtype.videoScreenRecording.rawValue
            )
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            let fetchResult = PHAsset.fetchAssets(with: .video, options: options)
            var fetched: [PHAsset] = []
            fetchResult.enumerateObjects { asset, _, _ in fetched.append(asset) }

            let total = fetched.reduce(Int64(0)) { $0 + $1.fileSize }
            let mediaAssets = fetched.map { MediaAsset(id: $0.localIdentifier, asset: $0) }

            await MainActor.run { [weak self] in
                self?.assets = mediaAssets
                self?.totalSize = total
                self?.isLoading = false
            }
        }
    }

    // MARK: - Selection

    func toggleSelection(_ id: String) {
        guard let i = assets.firstIndex(where: { $0.id == id }) else { return }
        assets[i].isSelected.toggle()
    }

    func selectAll() {
        for i in assets.indices { assets[i].isSelected = true }
    }

    func deselectAll() {
        for i in assets.indices { assets[i].isSelected = false }
    }

    // MARK: - Delete

    func deleteSelected() async {
        let toDelete = selectedAssets.map { $0.asset }
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
