//
//  ContentView.swift
//  SmartCleaner
//
//  Created by Prometheus Core on 22.03.2026.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("onboardingCompleted") private var isOnboardingCompleted: Bool = false

    var body: some View {
        ZStack{
            if isOnboardingCompleted {
                NavigationStack {
                    MediaView()
                }
                .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isOnboardingCompleted)
    }
}

 
