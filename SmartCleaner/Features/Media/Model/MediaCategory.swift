//
//  MediaCategory.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import SwiftUI

// MARK: - MediaCategory

struct MediaCategory: Identifiable {
    let id = UUID()
    let type: MediaCategoryType
    var itemCount: Int = 0
}

// MARK: - MediaCategoryType

enum MediaCategoryType: CaseIterable {
    case duplicatePhotos
    case similarPhotos
    case screenshots
    case livePhotos
    case screenRecordings
    case similarVideos

    var title: String {
        switch self {
        case .duplicatePhotos:   return "Duplicate Photos"
        case .similarPhotos:     return "Similar Photos"
        case .screenshots:       return "Screenshots"
        case .livePhotos:        return "Live Photos"
        case .screenRecordings:  return "Screen Recordings"
        case .similarVideos:     return "Similar Videos"
        }
    }

    var iconAssetName: String {
        switch self {
        case .duplicatePhotos:  return "icon_duplicate_photos"
        case .similarPhotos:    return "icon_similar_photos"
        case .screenshots:      return "icon_screenshots"
        case .livePhotos:       return "icon_live_photos"
        case .screenRecordings: return "icon_screen_recordings"
        case .similarVideos:    return "icon_similar_videos"
        }
    }
}
