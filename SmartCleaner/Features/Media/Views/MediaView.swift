//
//  MediaView.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import SwiftUI
import Photos

struct MediaView: View {
    
    @StateObject private var viewModel = MediaViewModel()
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    private var isAccessGranted: Bool {
        viewModel.authorizationStatus == .authorized ||
        viewModel.authorizationStatus == .limited
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                
                // MARK: Title
                Text("Media")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.titleColor)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                
                // MARK: Grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.categories) { category in
                        if isAccessGranted {
                            NavigationLink(destination: destination(for: category.type)) {
                                MediaCategoryCard(category: category, isAccessGranted: isAccessGranted)
                            }
                        } else {
                            MediaCategoryCard(category: category, isAccessGranted: isAccessGranted)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .animation(.easeInOut(duration: 0.3), value: viewModel.categories.map { $0.itemCount })
            }
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            viewModel.requestAccessIfNeeded()
        }
    }
    
    @ViewBuilder
    private func destination(for type: MediaCategoryType) -> some View {
        switch type {
        case .duplicatePhotos:
            DuplicatePhotosView()
        case .similarPhotos:
            SimilarPhotosView()
        case .screenshots:
            ScreenshotsView()
        case .livePhotos:
            LivePhotosView()
        case .screenRecordings:
            ScreenRecordingsView()
        case .similarVideos:
            SimilarVideosView()
        }
    }
}

#Preview {
    NavigationStack {
        MediaView()
    }
}
