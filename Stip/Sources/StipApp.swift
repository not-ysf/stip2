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
                }
        }
    }
}
