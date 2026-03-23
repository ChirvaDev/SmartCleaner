//
//  OnboardingPageView.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import SwiftUI

// MARK: - Single Page View

struct OnboardingPageView: View {

    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 0) {

            // Image
            Image(page.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            Spacer(minLength: 28)

            // Texts
            VStack(spacing: 10) {
                Text(page.title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.titleColor)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.subtitleColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 10)


            Spacer(minLength: 0)
        }
    }
}
