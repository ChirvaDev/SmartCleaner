//
//  VideoThumbnailCell.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 23.03.2026.
//

import Foundation
import SwiftUI
import Photos

struct VideoThumbnailCell: View {
    let asset: MediaAsset
    let onTap: () -> Void

    @State private var thumbnail: UIImage?
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            // Контейнер для зображення
            GeometryReader { geo in
                ZStack(alignment: .topTrailing) {
                    Group {
                        if let image = thumbnail {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.placeholderBackground)
                        }
                    }

                    // Оверлей при виборі
                    if asset.isSelected {
                        Color.appPrimary.opacity(0.25)
                    }

                    CheckboxView(isSelected: asset.isSelected)
                        .padding(6)

                    VStack {
                        Spacer()
                        HStack(alignment: .bottom) {
                            if asset.isBest {
                                BestBadgeView()
                            }
                            
                            Spacer()
                            
                            // Тривалість відео
                            durationBadge
                        }
                        .padding(6)
                    }
                }
            }
        }
        .aspectRatio(1.0, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(asset.isSelected ? Color.appPrimary : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onAppear {
            loadTask = Task {
                let image = await ThumbnailCache.shared.image(for: asset.asset)
                if !Task.isCancelled { thumbnail = image }
            }
        }
        .onDisappear {
            loadTask?.cancel()
        }
    }

    // Окремий в'ю для бейджа тривалості
    private var durationBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "video.fill")
                .font(.system(size: 8))
            Text(asset.asset.duration.formattedDuration)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.6))
        .clipShape(Capsule())
    }
}
