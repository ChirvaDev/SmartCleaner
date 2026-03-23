//
//  MediaThumbnailCell.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import SwiftUI
import Photos

struct MediaThumbnailCell: View {
    
    let asset: MediaAsset
    let showBestBadge: Bool
    let onTap: () -> Void
    
    @State private var thumbnail: UIImage?
    @State private var loadTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                ZStack(alignment: .bottomLeading) {
                    // 1. Сама картинка
                    Group {
                        if let image = thumbnail {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                .transition(.opacity.animation(.easeIn(duration: 0.2)))
                        } else {
                            Rectangle()
                                .fill(Color.placeholderBackground)
                        }
                    }
                    
                    // 2. Оверлей вибору
                    if asset.isSelected {
                        Color.appPrimary.opacity(0.25)
                    }
                    
                    // 3. Бейдж "Best"
                    if asset.isBest && showBestBadge {
                                            BestBadgeView()
                                                .padding(6)
                                        }
                    
                    // 4. Чекбокс
                    VStack {
                        HStack {
                            Spacer()
                            CheckboxView(isSelected: asset.isSelected)
                                .padding(6)
                        }
                        Spacer()
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    asset.isSelected ? Color.appPrimary : Color.clear,
                    lineWidth: 2
                )
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onAppear { startLoading() }
        .onDisappear { cancelLoading() }
    }
    
    // MARK: - Loading
    
    private func startLoading() {
        guard thumbnail == nil else { return }
        loadTask = Task {
            let image = await ThumbnailCache.shared.image(for: asset.asset)
            guard !Task.isCancelled else { return }
            await MainActor.run { thumbnail = image }
        }
    }
    
    private func cancelLoading() {
        loadTask?.cancel()
        loadTask = nil
    }
}

