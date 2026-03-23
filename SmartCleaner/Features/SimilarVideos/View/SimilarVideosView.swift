//
//  SimilarVideosView.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import SwiftUI
import Photos

// MARK: - SimilarVideosView

struct SimilarVideosView: View {

    @StateObject private var viewModel = SimilarVideosViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {

            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.titleColor)
                    }

                    Spacer()

                    if !viewModel.groups.isEmpty {
                        Button(action: {
                            viewModel.isAllSelected ? viewModel.deselectAll() : viewModel.selectAllGroups()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.isAllSelected ? "checkmark.circle.fill" : "checkmark.circle")
                                    .font(.system(size: 15))
                                Text(viewModel.isAllSelected ? "Deselect all" : "Select all")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(.appPrimary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)

                // MARK: Title + Stats
                CategoryHeaderView(title: "Similar Videos", count: viewModel.totalVideosCount, totalSize: viewModel.totalVideosSize, countLabel: "Videos")
                
                Divider()

                // MARK: Content
                if viewModel.isLoading {
                    LoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.groups.isEmpty {
                    EmptyStateView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.groups) { group in
                                VideoGroupSection(
                                    group: group,
                                    onToggleAsset: { assetId in
                                        viewModel.toggleSelection(assetId: assetId, in: group.id)
                                    },
                                    onSelectAll: {
                                        viewModel.selectAll(in: group.id)
                                    }
                                )

                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, viewModel.hasSelection ? 100 : 32)
                    }
                }
            }

            // MARK: Delete Button
            if viewModel.hasSelection {
                DeleteButtonView(title: viewModel.deleteButtonTitle) {
                    Task { await viewModel.deleteSelected() }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.hasSelection)
        .onAppear { viewModel.load() }

    }
}

// MARK: - VideoGroupSection

struct VideoGroupSection: View {

    let group: MediaGroup
    let onToggleAsset: (String) -> Void
    let onSelectAll: () -> Void

    var body: some View {
        VStack(spacing: 8) {

            HStack {
                Text(group.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.titleColor)

                Spacer()

                Button(action: onSelectAll) {
                    Text(group.allSelected ? "Deselect All" : "Select All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appPrimary)
                }
            }
            .padding(.horizontal, 16)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)],
                spacing: 4
            ) {
                ForEach(group.assets) { asset in
                    VideoThumbnailCell(asset: asset) {
                        onToggleAsset(asset.id)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .onAppear {
            ThumbnailCache.shared.startCaching(group.assets.map { $0.asset })
        }
        .onDisappear {
            ThumbnailCache.shared.stopCaching(group.assets.map { $0.asset })
        }
    }
}

#Preview {
    SimilarVideosView()
}
