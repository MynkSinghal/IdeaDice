import SwiftUI
import AppKit

struct WordCardView: View {
    let word: String
    let label: String
    let shouldShowLabel: Bool
    let isBold: Bool
    let isItalic: Bool
    let isUnderlined: Bool
    let isFlipped: Bool
    @State private var isAnimating = false
    @ObservedObject private var settings = AppSettings.shared
    
    init(
        word: String,
        label: String,
        shouldShowLabel: Bool = true,
        isBold: Bool = false,
        isItalic: Bool = false,
        isUnderlined: Bool = false,
        isFlipped: Bool = false
    ) {
        self.word = word
        self.label = label
        self.shouldShowLabel = shouldShowLabel
        self.isBold = isBold
        self.isItalic = isItalic
        self.isUnderlined = isUnderlined
        self.isFlipped = isFlipped
    }
    
    var body: some View {
        VStack(spacing: 5) {
            if shouldShowLabel {
                Text(label)
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .kerning(1.0)
                    .foregroundColor(.gray)
                    .opacity(0.7)
            }
            
            Text(word)
                .font(Font(settings.selectedFont.uiFont(size: 16)))
                .bold(isBold)
                .italic(isItalic)
                .underline(isUnderlined)
                .foregroundColor(.black)
                .scaleEffect(isAnimating ? 0.9 : 1.0)
                .opacity(isAnimating ? 0.6 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isAnimating)
        }
        .padding(.vertical, 4)
    }
    
    func animate() {
        isAnimating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isAnimating = false
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            WordCardView(
                word: "Mirror", 
                label: "NOUN", 
                shouldShowLabel: true,
                isBold: false,
                isItalic: false,
                isUnderlined: false,
                isFlipped: false
            )
            WordCardView(
                word: "Whisper", 
                label: "VERB", 
                shouldShowLabel: true,
                isBold: true,
                isItalic: false,
                isUnderlined: false,
                isFlipped: false
            )
            WordCardView(
                word: "Nostalgia", 
                label: "EMOTION", 
                shouldShowLabel: true,
                isBold: false,
                isItalic: true,
                isUnderlined: false,
                isFlipped: false
            )
        }
    }
    .padding()
    .background(Color.white)
} 