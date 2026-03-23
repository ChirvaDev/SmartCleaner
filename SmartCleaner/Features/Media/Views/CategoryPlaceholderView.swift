//
//  CategoryPlaceholderView.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 23.03.2026.
//

import Foundation
import SwiftUI

struct CategoryPlaceholderView: View {
    let title: String
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.titleColor)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
