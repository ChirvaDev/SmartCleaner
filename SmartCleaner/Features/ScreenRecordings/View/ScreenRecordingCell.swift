//
//  ScreenRecordingCell.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 23.03.2026.
//

import Foundation
import SwiftUI
import Photos

struct ScreenRecordingCell: View {

    let asset: MediaAsset
    let onTap: () -> Void

    @State private var thumbnail: UIImage?
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .topTrailing) {

            Group {
                if let image = thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity.animation(.easeIn(duration: 0.2)))
                } else {
                    Rectangle()
                        .fill(Color.placeholderBackground)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            if asset.isSelected {
                Color.appPrimary.opacity(0.25)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            CheckboxView(isSelected: asset.isSelected)
                .padding(6)

            // Duration badge
            HStack(spacing: 3) {
                Image(systemName: "video.fill")
                    .font(.system(size: 9))
                Text(asset.asset.duration.formattedDuration)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.55))
            .clipShape(Capsule())
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .aspectRatio(9/16, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(asset.isSelected ? Color.appPrimary : Color.clear, lineWidth: 2)
        )
        .onTapGesture(perform: onTap)
        .onAppear {
            loadTask = Task {
                let image = await ThumbnailCache.shared.image(for: asset.asset)
                guard !Task.isCancelled else { return }
                await MainActor.run { thumbnail = image }
            }
        }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
        }
    }
}
