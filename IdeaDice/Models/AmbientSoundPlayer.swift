import Foundation
import AVFoundation
import AppKit  // Add AppKit import for NSApplication

// Enum for available ambient sounds
enum AmbientSound: String, CaseIterable, Identifiable {
    case none = "None"
    case rain = "Rain"
    case coffee = "Coffee Shop"
    case nature = "Nature"
    case fireplace = "Fireplace"
    case flute = "Flute Melody"
    
    var id: String { self.rawValue }
    
    // Get system icon name for the sound
    var iconName: String {
        switch self {
        case .none:
            return "speaker.slash"
        case .rain:
            return "cloud.rain"
        case .coffee:
            return "cup.and.saucer"
        case .nature:
            return "leaf"
        case .fireplace:
            return "flame"
        case .flute:
            return "music.note"
        }
    }
    
    // Get resource name for the sound
    var resourceName: String? {
        switch self {
        case .none:
            return nil
        case .rain:
            return "rain_ambient"
        case .coffee:
            return "coffee_shop_ambient"
        case .nature:
            return "nature_ambient"
        case .fireplace:
            return "fireplace_ambient"
        case .flute:
            return "flute_ambient"
        }
    }
}

class AmbientSoundPlayer: ObservableObject {
    static let shared = AmbientSoundPlayer()
    
    @Published var currentSound: AmbientSound = .none {
        didSet {
            if oldValue != currentSound {
                stopCurrentSound()
                if currentSound != .none {
                    playSound(currentSound)
                }
                // Save the preference
                UserDefaults.standard.set(currentSound.rawValue, forKey: "selectedAmbientSound")
            }
        }
    }
    
    @Published var volume: Float = 0.5 {
        didSet {
            audioPlayer?.volume = volume
            UserDefaults.standard.set(volume, forKey: "ambientSoundVolume")
        }
    }
    
    @Published var isPlaying: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    
    // For player status observation (macOS friendly)
    private var playerObserver: Any?
    
    private init() {
        // Load saved sound preference
        if let savedSound = UserDefaults.standard.string(forKey: "selectedAmbientSound"),
           let sound = AmbientSound(rawValue: savedSound) {
            self.currentSound = sound
        }
        
        // Load saved volume preference
        if let savedVolume = UserDefaults.standard.object(forKey: "ambientSoundVolume") as? Float {
            self.volume = savedVolume
        }
        
        // Initialize player if we have a saved sound
        if currentSound != .none {
            playSound(currentSound)
        }
        
        // Set up notification center observer for app termination to clean up resources
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppTermination),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopCurrentSound()
    }
    
    @objc private func handleAppTermination() {
        // Clean up resources when app is terminating
        stopCurrentSound()
    }
    
    private func playSound(_ sound: AmbientSound) {
        guard let resourceName = sound.resourceName,
              let path = Bundle.main.path(forResource: resourceName, ofType: "mp3") else {
            print("Could not find sound file for \(sound.rawValue)")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            // Set up audio player (macOS compatible)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            
            // Configure for looping
            audioPlayer?.numberOfLoops = -1  // Loop indefinitely
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            
            // Log successful playback
            print("Started playing ambient sound: \(sound.rawValue)")
            
            // Set up a timer to check if audio stops unexpectedly (simplified approach for macOS)
            setupPlaybackMonitoring()
        } catch {
            print("Could not play ambient sound: \(error.localizedDescription)")
        }
    }
    
    // Monitor playback to ensure continuous looping
    private func setupPlaybackMonitoring() {
        // Create a repeating timer to check playback status
        DispatchQueue.main.async {
            let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self, let player = self.audioPlayer else { return }
                
                // If player exists but isn't playing and should be playing, restart it
                if !player.isPlaying && self.isPlaying && self.currentSound != .none {
                    print("Detected playback interruption, restarting...")
                    player.play()
                }
            }
            
            // Store timer for later cleanup
            if let existingTimer = self.playerObserver as? Timer {
                existingTimer.invalidate()
            }
            self.playerObserver = timer
        }
    }
    
    func stopCurrentSound() {
        // Clean up audio player
        audioPlayer?.stop()
        audioPlayer = nil
        
        // Clean up timer
        if let timer = playerObserver as? Timer {
            timer.invalidate()
            playerObserver = nil
        }
        
        isPlaying = false
    }
    
    func toggleSound() {
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
        } else if currentSound != .none {
            audioPlayer?.play()
            isPlaying = true
        }
    }
    
    func cycleToNextSound() {
        let allSounds = AmbientSound.allCases
        guard let currentIndex = allSounds.firstIndex(of: currentSound) else {
            return
        }
        
        let nextIndex = (currentIndex + 1) % allSounds.count
        currentSound = allSounds[nextIndex]
    }
} 