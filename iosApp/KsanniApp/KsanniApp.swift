import SwiftUI
import Firebase

@main
struct KsanniApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(InvoiceManager())
                .environmentObject(AuthManager())
                .environmentObject(ThemeManager())
        }
    }
}