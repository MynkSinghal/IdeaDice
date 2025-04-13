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
        // Basic Metal initialization without complexities
        if let _ = MTLCreateSystemDefaultDevice() {
            print("Metal device available")
        } else {
            print("Metal device not available")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .toolbar(.hidden, for: .windowToolbar)
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    print("App main view appeared")
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 700)
        .windowResizability(.contentSize)
    }
}

// AppDelegate to handle window configuration
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App launched - configuring window")
        
        // Configure main window after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.configureMainWindow()
        }
    }
    
    private func configureMainWindow() {
        if let window = NSApplication.shared.windows.first {
            // Basic window setup
            window.makeKeyAndOrderFront(nil)
            
            // Enter fullscreen mode if needed
            if !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
            
            // Ensure window is visible
            window.orderFrontRegardless()
            print("Window configured")
        } else {
            print("No window found to configure")
        }
    }
}
