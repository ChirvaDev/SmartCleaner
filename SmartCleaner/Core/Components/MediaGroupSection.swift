//
//  MediaGroupSection.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import SwiftUI

struct MediaGroupSection: View {

    let group: MediaGroup
    let onToggleAsset: (String) -> Void
    let onSelectAll: () -> Void
    let onSelectText: String
    let showBestBadge: Bool

    var body: some View {
        VStack(spacing: 8) {

            // Header
            HStack {
                Text("\(group.title) \(onSelectText)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.titleColor)

                Spacer()

                Button(action: onSelectAll) {
                    Text(group.allSelected ? "Deselect All" : "Select All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appPrimary)
                }
            }
            .padding(.horizontal, 16)

            // 2-column grid
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)],
                spacing: 4
            ) {
                ForEach(group.assets) { asset in
                    MediaThumbnailCell(asset: asset, showBestBadge: showBestBadge) {
                        onToggleAsset(asset.id)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .onAppear {
            ThumbnailCache.shared.startCaching(group.assets.map { $0.asset })
        }
        .onDisappear {
            ThumbnailCache.shared.stopCaching(group.assets.map { $0.asset })
        }
    }
}
