//
//  MediaAsset.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import Photos
import UIKit

// MARK: - MediaAsset

struct MediaAsset: Identifiable, Equatable {
    let id: String
    let asset: PHAsset
    var isBest: Bool = false
    var isSelected: Bool = false

    var fileSize: Int64 { asset.fileSize }
    var creationDate: Date? { asset.creationDate }

    static func == (lhs: MediaAsset, rhs: MediaAsset) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - MediaGroup

struct MediaGroup: Identifiable {
    let id = UUID()
    var assets: [MediaAsset]

    var title: String {
        "\(assets.count)" 
    }

    var selectedAssets: [MediaAsset] {
        assets.filter { $0.isSelected }
    }

    var allSelected: Bool {
        assets.allSatisfy { $0.isSelected }
    }

    var totalSelectedSize: Int64 {
        selectedAssets.reduce(0) { $0 + $1.fileSize }
    }
}

// MARK: - PHAsset + fileSize


extension PHAsset {
    nonisolated var fileSize: Int64 {
        let resource = PHAssetResource.assetResources(for: self)
        return resource.first?.value(forKey: "fileSize") as? Int64 ?? 0
    }
}
