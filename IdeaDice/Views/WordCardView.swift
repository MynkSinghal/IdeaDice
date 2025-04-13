import SwiftUI

struct WordCardView: View {
    let word: String
    let label: String
    let color: Color
    @State private var isAnimating = false
    
    // Ivory background color
    private let backgroundColor = Color(red: 255/255, green: 255/255, blue: 240/255)
    
    var body: some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .kerning(1.0)
                .foregroundStyle(.secondary)
                .opacity(0.5)
            
            Text(word)
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundStyle(.primary)
                .frame(height: 22)
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
            WordCardView(word: "Mirror", label: "NOUN", color: .primary)
            WordCardView(word: "Whisper", label: "VERB", color: .primary)
            WordCardView(word: "Nostalgia", label: "EMOTION", color: .primary)
        }
    }
    .padding()
    .background(Color(red: 255/255, green: 255/255, blue: 240/255))
} 