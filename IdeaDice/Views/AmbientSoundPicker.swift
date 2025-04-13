import SwiftUI

struct AmbientSoundPicker: View {
    @ObservedObject private var soundPlayer = AmbientSoundPlayer.shared
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            HStack {
                Text("Ambient Sounds")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 15))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 5)
            
            // Sound options
            VStack(spacing: 10) {
                ForEach(AmbientSound.allCases) { sound in
                    SoundOption(sound: sound, isSelected: soundPlayer.currentSound == sound)
                        .onTapGesture {
                            soundPlayer.currentSound = sound
                        }
                }
            }
            
            // Volume slider (only if a sound is selected)
            if soundPlayer.currentSound != .none {
                Divider()
                    .padding(.vertical, 5)
                
                VStack(spacing: 8) {
                    // Volume label and percentage
                    HStack {
                        Text("Volume")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.black.opacity(0.75))
                        
                        Spacer()
                        
                        Text("\(Int(soundPlayer.volume * 100))%")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    
                    // Custom volume slider
                    CustomVolumeSlider(value: $soundPlayer.volume)
                        .frame(height: 24)
                }
            }
        }
        .padding()
        .frame(width: 250)
        .background(Color.white)
    }
}

// Custom volume slider that matches app aesthetic
struct CustomVolumeSlider: View {
    @Binding var value: Float
    @State private var isDragging: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.08))
                    .frame(height: 8)
                
                // Filled portion
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.6),
                                Color.blue.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, min(CGFloat(value) * geometry.size.width, geometry.size.width)), height: 8)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .shadow(color: Color.black.opacity(0.15), radius: isDragging ? 4 : 2, x: 0, y: isDragging ? 2 : 1)
                    .offset(x: max(0, min(CGFloat(value) * geometry.size.width - 8, geometry.size.width - 16)))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                isDragging = true
                                let newValue = Float(gesture.location.x / geometry.size.width)
                                value = max(0, min(newValue, 1.0))
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
                
                // Invisible overlay for better touch target
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .frame(height: 24)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                isDragging = true
                                let newValue = Float(gesture.location.x / geometry.size.width)
                                value = max(0, min(newValue, 1.0))
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
            }
            .frame(height: 24)
            .animation(.interactiveSpring(), value: isDragging)
        }
    }
}

struct SoundOption: View {
    let sound: AmbientSound
    let isSelected: Bool
    
    var body: some View {
        HStack {
            // Icon
            Image(systemName: sound.iconName)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .blue : .gray)
                .frame(width: 20)
            
            // Text
            Text(sound.rawValue)
                .font(.system(size: 13))
                .foregroundColor(.black)
            
            Spacer()
            
            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                    .font(.system(size: 11))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
}

#Preview {
    AmbientSoundPicker(isPresented: .constant(true))
        .frame(width: 250)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 5)
} 