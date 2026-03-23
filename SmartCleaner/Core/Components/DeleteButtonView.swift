//
//  DeleteButtonView.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 23.03.2026.
//

import SwiftUI

struct DeleteButtonView: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.appPrimary)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .shadow(color: Color.appPrimary.opacity(0.35), radius: 12, x: 0, y: 4)
    }
}
