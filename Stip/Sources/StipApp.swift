import SwiftUI

@main
struct StipApp: App {
    @StateObject private var viewModel = StepViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(NotificationManager.shared)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Ask for notification permission
                    NotificationManager.shared.requestPermission()
                    // Request HealthKit access after a short delay
                    // so the window is fully visible (iOS requires this
                    // to present the Health authorization dialog)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.checkHealthKitAuthorizationStatus()
                    }
                }
        }
    }
}
