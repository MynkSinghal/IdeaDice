import SwiftUI
import AppKit

// Available fonts for the app
enum AppFont: String, CaseIterable, Identifiable {
    case system = "System Font"
    case serif = "Serif"
    case bradleyHand = "Bradley Hand"
    case arial = "Arial"
    case annyanteMN = "Annyante MN"
    case avenir = "Avenir"
    case futura = "Futura"
    case helveticaNeue = "Helvetica Neue"
    case garamond = "Garamond"
    case gilSans = "Gill Sans"
    case optima = "Optima"
    
    var id: String { self.rawValue }
    
    func fontName() -> String {
        switch self {
        case .system:
            return ".AppleSystemUIFont"
        case .serif:
            return ".AppleSystemUIFontSerif"
        case .bradleyHand:
            return "BradleyHandITCTT-Bold"
        case .arial:
            return "ArialMT"
        case .annyanteMN:
            return "AnnaiMN"
        case .avenir:
            return "Avenir-Book"
        case .futura:
            return "Futura-Medium"
        case .helveticaNeue:
            return "HelveticaNeue"
        case .garamond:
            return "AppleGaramond"
        case .gilSans:
            return "GillSans"
        case .optima:
            return "Optima"
        }
    }
    
    func uiFont(size: CGFloat) -> NSFont {
        return NSFont(name: fontName(), size: size) ?? NSFont.systemFont(ofSize: size)
    }
    
    static var next: (AppFont) -> AppFont = { current in
        let allFonts = AppFont.allCases
        guard let currentIndex = allFonts.firstIndex(of: current) else {
            return .system
        }
        let nextIndex = (currentIndex + 1) % allFonts.count
        return allFonts[nextIndex]
    }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var selectedFont: AppFont {
        didSet {
            UserDefaults.standard.set(selectedFont.rawValue, forKey: "selectedFont")
        }
    }
    
    // Add isSoundEnabled for backward compatibility
    @Published var isSoundEnabled: Bool = false
    
    // Add a flag to track first launch
    @Published var isFirstLaunch: Bool {
        didSet {
            UserDefaults.standard.set(!isFirstLaunch, forKey: "hasLaunchedBefore")
        }
    }
    
    private init() {
        // Initialize font setting
        if let savedFont = UserDefaults.standard.string(forKey: "selectedFont"),
           let font = AppFont(rawValue: savedFont) {
            self.selectedFont = font
        } else {
            self.selectedFont = .serif // Default font
        }
        
        // Check if this is first launch
        self.isFirstLaunch = !(UserDefaults.standard.bool(forKey: "hasLaunchedBefore"))
        
        // Log initialization for debugging
        print("AppSettings initialized: font=\(selectedFont.rawValue), firstLaunch=\(isFirstLaunch)")
    }
    
    func cycleToNextFont() {
        selectedFont = AppFont.next(selectedFont)
    }
} 