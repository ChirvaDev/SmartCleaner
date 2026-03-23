//
//  LoadingView.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 23.03.2026.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.6)
                .tint(.appPrimary)
            
            Text("Scanning photos...")
                .font(.system(size: 15))
                .foregroundColor(.subtitleColor)
        }
    }
}

#Preview {
    LoadingView()
}
