import SwiftUI

struct WelcomeView: View {
    @Binding var isShowingWelcome: Bool
    
    // Ivory background color
    private let backgroundColor = Color(red: 255/255, green: 255/255, blue: 240/255)
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("Flow Writing")
                .font(.system(size: 28, weight: .light, design: .serif))
                .kerning(2)
            
            VStack(spacing: 30) {
                Text("A simple exercise to develop your creative thinking and writing skills.")
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)
                
                VStack(alignment: .leading, spacing: 20) {
                    InfoRow(
                        number: "1",
                        text: "Three random words will appear at the top of your screen"
                    )
                    
                    InfoRow(
                        number: "2",
                        text: "Write freely based on these words without overthinking"
                    )
                    
                    InfoRow(
                        number: "3",
                        text: "Tap anywhere on the screen to hide the interface and focus"
                    )
                    
                    InfoRow(
                        number: "4",
                        text: "Generate new words anytime when you need fresh inspiration"
                    )
                }
                .padding(.horizontal, 60)
            }
            
            Spacer()
            
            Button {
                withAnimation(.easeOut(duration: 0.3)) {
                    isShowingWelcome = false
                }
            } label: {
                Text("Begin")
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .kerning(1)
                    .foregroundStyle(.primary)
                    .frame(width: 140, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
    }
}

struct InfoRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Text(number)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(.primary.opacity(0.4))
                .frame(width: 16, alignment: .center)
            
            Text(text)
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    WelcomeView(isShowingWelcome: .constant(true))
} 