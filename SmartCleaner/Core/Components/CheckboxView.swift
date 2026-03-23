//
//  CheckboxView.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 23.03.2026.
//

import SwiftUI

struct CheckboxView: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.appPrimary)
                    .frame(width: 22, height: 22)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            } else {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color.white, lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.black.opacity(0.15))
                    )
            }
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }
}
