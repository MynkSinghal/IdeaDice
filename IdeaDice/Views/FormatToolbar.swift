import SwiftUI

struct FormatToolbar: View {
    var onBold: () -> Void
    var onItalic: () -> Void
    var onUnderline: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onBold) {
                Image(systemName: "bold")
                    .frame(width: 24, height: 24)
                    .foregroundColor(.black)
            }
            .buttonStyle(FormatButtonStyle())
            .help("Bold")
            
            Button(action: onUnderline) {
                Image(systemName: "underline")
                    .frame(width: 24, height: 24)
                    .foregroundColor(.black)
            }
            .buttonStyle(FormatButtonStyle())
            .help("Underline")
            
            Button(action: onItalic) {
                Image(systemName: "italic")
                    .frame(width: 24, height: 24)
                    .foregroundColor(.black)
            }
            .buttonStyle(FormatButtonStyle())
            .help("Italic")
        }
        .padding(8)
        .background(Color(white: 0.98))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
}

// Custom button style for format buttons
struct FormatButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(configuration.isPressed ? Color.gray.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    FormatToolbar(
        onBold: {},
        onItalic: {},
        onUnderline: {}
    )
} 