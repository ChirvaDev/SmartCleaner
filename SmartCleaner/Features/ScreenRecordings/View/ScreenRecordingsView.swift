//
//  ScreenRecordingsView.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import SwiftUI
import Photos

struct ScreenRecordingsView: View {

    @StateObject private var viewModel = ScreenRecordingsViewModel()
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

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

                    if !viewModel.assets.isEmpty {
                        Button(action: {
                            viewModel.isAllSelected ? viewModel.deselectAll() : viewModel.selectAll()
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
                CategoryHeaderView(title: "Screen Recordings", count: viewModel.assets.count, totalSize: viewModel.totalSize, countLabel: "Videos")
                
                Divider()

                // MARK: Content
                if viewModel.isLoading {
                    LoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.assets.isEmpty {
                    EmptyStateView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(viewModel.assets) { asset in
                                ScreenRecordingCell(asset: asset) {
                                    viewModel.toggleSelection(asset.id)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, viewModel.hasSelection ? 100 : 32)
                    }
                }
            }

            if viewModel.hasSelection {
                DeleteButtonView(title: viewModel.deleteButtonTitle) {
                                    Task {
                                        await viewModel.deleteSelected()
                                    }
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
    ScreenRecordingsView()
}
