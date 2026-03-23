//
//  EmptyStateView.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 23.03.2026.
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(.appPrimary)
                .padding(.bottom, 5)

            Text("Your device is clean")
                .font(.system(size: 23, weight: .bold))
                .foregroundColor(.titleColor)

            Text("There are no photos on your device.")
                .font(.system(size: 15))
                .foregroundColor(.subtitleColor)
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 100)

    }
}

#Preview {
    EmptyStateView()
}
