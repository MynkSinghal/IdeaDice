import SwiftUI

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        }
    }
    
    private init() {
        // Use a safer approach to get default value - if there's an error, default to false to avoid sound issues
        let defaultValue = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool
        self.soundEnabled = defaultValue ?? false
    }
} 