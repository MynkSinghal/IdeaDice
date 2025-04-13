import SwiftUI

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        }
    }
    
    // Add a flag to track first launch
    @Published var isFirstLaunch: Bool {
        didSet {
            UserDefaults.standard.set(!isFirstLaunch, forKey: "hasLaunchedBefore")
        }
    }
    
    private init() {
        // Set sound option with safer initialization
        let soundSetting = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool
        self.soundEnabled = soundSetting ?? false
        
        // Check if this is first launch
        self.isFirstLaunch = !(UserDefaults.standard.bool(forKey: "hasLaunchedBefore"))
        
        // Log initialization for debugging
        print("AppSettings initialized: sound=\(soundEnabled), firstLaunch=\(isFirstLaunch)")
    }
} 