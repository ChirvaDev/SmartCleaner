//
//  CategoryHeaderView.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 23.03.2026.
//

import SwiftUI

struct CategoryHeaderView: View {
    let title: String
    let count: Int
    let totalSize: Int64
    let countLabel: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.titleColor)
            
            HStack(spacing: 12) {
                
                HStack(spacing: 5) {
                    Image("stat_1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                    
                    Text("\(count) \(countLabel)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.subtitleColor)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                )
                
                HStack(spacing: 5) {
                    Image("stat_2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                    Text(
                        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
                    )
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.subtitleColor)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

#Preview {
    CategoryHeaderView(
        title: "Screen Recordings",
        count: 450,
        totalSize: 345,
        countLabel: "Videos"
    )
}
