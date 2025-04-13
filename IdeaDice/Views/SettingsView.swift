import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    
    // Ivory background color
    private let backgroundColor = Color(red: 255/255, green: 255/255, blue: 240/255)
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Settings")
                .font(.system(size: 20, weight: .light, design: .serif))
                .kerning(1)
            
            VStack(alignment: .leading, spacing: 20) {
                Toggle(isOn: $settings.soundEnabled) {
                    Text("Sound Effects")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                }
                .toggleStyle(.switch)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.secondary.opacity(0.6))
                    
                    Text("A minimalist writing tool designed to spark creativity through random word prompts. Write freely without distraction to develop creative thinking skills.")
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundStyle(.primary.opacity(0.8))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: 300)
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundStyle(.primary.opacity(0.7))
                    .frame(width: 120, height: 34)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 20)
        }
        .padding(.top, 30)
        .frame(width: 340, height: 320)
        .background(backgroundColor)
    }
}

#Preview {
    SettingsView()
} 