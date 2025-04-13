import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var hasWarnedAboutMissingFile = false
    
    private init() {
        // Check if sound file exists immediately
        checkSoundFileExists()
    }
    
    private func checkSoundFileExists() {
        if Bundle.main.url(forResource: "dice_roll", withExtension: "mp3") == nil && !hasWarnedAboutMissingFile {
            print("Sound file 'dice_roll.mp3' not found in bundle - sound effects won't work")
            hasWarnedAboutMissingFile = true
        }
    }
    
    func playDiceRollSound() {
        // Try to load from bundle
        guard let soundURL = Bundle.main.url(forResource: "dice_roll", withExtension: "mp3") else {
            // No need to warn every time
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Could not play the sound file: \(error)")
        }
    }
} 