//
//  MediaCategoryCard.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import SwiftUI
import Photos

// MARK: - MediaCategoryCard

struct MediaCategoryCard: View {

    let category: MediaCategory
    let isAccessGranted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Icon 
            Image(category.type.iconAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .padding(.bottom, 12)

            // Title
            Text(category.type.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.titleColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 6)

            // Count or Lock
            if isAccessGranted {
                Text("\(category.itemCount) Items")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.subtitleColor)
            } else {
                Image("icon_media_lock")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
}
