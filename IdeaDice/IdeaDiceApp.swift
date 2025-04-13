//
//  IdeaDiceApp.swift
//  IdeaDice
//
//  Created by Mayank Singhal on 13/04/25.
//

import SwiftUI
import MetalKit

@main
struct IdeaDiceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Force Metal to initialize early to avoid runtime errors
        let device = MTLCreateSystemDefaultDevice()
        let library = try? device?.makeDefaultLibrary(bundle: Bundle.main)
        if library == nil {
            print("Warning: Could not initialize Metal library. UI effects may be limited.")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .toolbar(.hidden, for: .windowToolbar)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 700)
        .windowResizability(.contentSize)
    }
}

// Add AppDelegate to handle window configuration
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            // Enter fullscreen mode automatically
            if !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        }
    }
}
