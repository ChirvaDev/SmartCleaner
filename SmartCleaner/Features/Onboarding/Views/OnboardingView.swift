//
//  OnboardingView.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import SwiftUI

struct OnboardingView: View {

    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $viewModel.currentPage) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: viewModel.currentPage)

                VStack(spacing: 24) {

                    PageIndicatorView(
                        totalPages: viewModel.pages.count,
                        currentPage: viewModel.currentPage
                    )

                    Button(action: viewModel.handleContinue) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.appPrimary)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
                .padding(.top, 16)
            }
        }
    }
}

#Preview {
    OnboardingView()
}





