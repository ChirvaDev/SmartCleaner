//
//  OnboardingViewModel.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import SwiftUI
import Photos
import Combine

// MARK: - OnboardingViewModel

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - Published

    @Published var currentPage: Int = 0
    @Published var showMainApp: Bool = false

    // MARK: - Data

    let pages: [OnboardingPage] = [
        OnboardingPage(
            imageName: "onb_1",
            title: "Clean your Storage",
            subtitle: "Pick the best & delete the rest"
        ),
        OnboardingPage(
            imageName: "onb_2",
            title: "Detect Similar Photos",
            subtitle: "Clean similar photos & videos, save your storage space on your phone."
        ),
        OnboardingPage(
            imageName: "onb_3",
            title: "Video Compressor",
            subtitle: "Find large videos or media files and compress them to free up storage space"
        )
    ]

    // MARK: - Actions

    func handleContinue() {
        let isLastPage = currentPage == pages.count - 1

        if isLastPage {
            requestPhotoLibraryAccess()
        } else {
            withAnimation(.easeInOut(duration: 0.35)) {
                currentPage += 1
            }
        }
    }
    
    private func requestPhotoLibraryAccess() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.proceedToMainApp()
                }
            }
        case .authorized, .limited, .denied, .restricted:
            proceedToMainApp()
        @unknown default:
            proceedToMainApp()
        }
    }

    private func proceedToMainApp() {
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
    }
}
