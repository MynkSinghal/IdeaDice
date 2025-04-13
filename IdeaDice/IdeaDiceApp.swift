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
        // Safely initialize Metal - properly handle errors
        if let device = MTLCreateSystemDefaultDevice() {
            do {
                // Try to create the Metal library
                let _ = try device.makeDefaultLibrary(bundle: Bundle.main)
            } catch {
                print("Metal initialization error: \(error)")
            }
        } else {
            print("Metal device not available on this system")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .toolbar(.hidden, for: .windowToolbar)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 700)
        .windowResizability(.contentSize)
    }
}

// Refined AppDelegate to handle window configuration more robustly
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Add a slight delay to ensure window is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.configureMainWindow()
        }
    }
    
    private func configureMainWindow() {
        if let window = NSApplication.shared.windows.first {
            // Ensure window is properly sized and visible
            window.makeKeyAndOrderFront(nil)
            
            // Enter fullscreen mode
            if !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
            
            // Make sure window is displayed at the front
            window.orderFrontRegardless()
        }
    }
}
