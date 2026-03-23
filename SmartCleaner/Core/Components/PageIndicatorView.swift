//
//  PageIndicatorView.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import SwiftUI

struct PageIndicatorView: View {

    let totalPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.appPrimary : Color.indicatorInactive)
                    .frame(width: index == currentPage ? 20 : 7, height: 7)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}
