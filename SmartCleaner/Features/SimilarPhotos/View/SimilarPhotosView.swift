//
//  SimilarPhotosView.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 23.03.2026.
//

import SwiftUI

struct SimilarPhotosView: View {

    @StateObject private var viewModel = SimilarPhotosViewModel()
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
                CategoryHeaderView(title: "Similar Photos", count: viewModel.totalPhotosCount, totalSize: viewModel.totalPhotosSize, countLabel: "Photos")

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
                                MediaGroupSection(
                                    group: group,
                                    onToggleAsset: { assetId in
                                        viewModel.toggleSelection(assetId: assetId, in: group.id)
                                    },
                                    onSelectAll: {
                                        viewModel.selectAll(in: group.id)
                                    }, onSelectText: "Similar", showBestBadge: false
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

#Preview {
    SimilarPhotosView()
}
