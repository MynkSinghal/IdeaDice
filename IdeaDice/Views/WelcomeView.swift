import SwiftUI
import AppKit

struct WelcomeView: View {
    @Binding var isShowingWelcome: Bool
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("Flow Writing")
                .font(Font(settings.selectedFont.uiFont(size: 28)))
                .foregroundColor(.black)
                .kerning(2)
            
            VStack(spacing: 30) {
                Text("A simple exercise to develop your creative thinking and writing skills.")
                    .font(Font(settings.selectedFont.uiFont(size: 16)))
                    .foregroundColor(.black)
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
                print("Begin button pressed, closing welcome screen")
                withAnimation(.easeOut(duration: 0.3)) {
                    isShowingWelcome = false
                }
            } label: {
                Text("Begin")
                    .font(Font(settings.selectedFont.uiFont(size: 16)))
                    .foregroundColor(.black)
                    .kerning(1)
                    .frame(width: 140, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.black.opacity(0.2), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .onAppear {
            print("WelcomeView appeared")
        }
    }
}

struct InfoRow: View {
    let number: String
    let text: String
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Text(number)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.black.opacity(0.4))
                .frame(width: 16, alignment: .center)
            
            Text(text)
                .font(Font(settings.selectedFont.uiFont(size: 16)))
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    WelcomeView(isShowingWelcome: .constant(true))
} 