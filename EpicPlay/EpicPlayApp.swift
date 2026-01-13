import SwiftUI

@main
struct EpicPlayApp: App {
    var body: some Scene {
        WindowGroup {
            WebViewWrapper() // 👈 Aquí llamamos al WebViewController como pantalla principal
        }
    }
}

