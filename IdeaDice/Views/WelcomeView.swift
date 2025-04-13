import SwiftUI
import AppKit

struct WelcomeView: View {
    @Binding var isShowingWelcome: Bool
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var historyManager = HistoryManager.shared
    
    // Animation states
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = -20
    @State private var descriptionOpacity: Double = 0
    @State private var infoRowsOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var isHovering: Bool = false
    @State private var floatingAnimation: Bool = false
    @State private var recentWritingsOpacity: Double = 0
    
    // Tutorial states
    @State private var showTutorial: Bool = false
    @State private var tutorialPage: Int = 0
    
    // For Recent Writings section
    private var hasRecentWritings: Bool {
        return !historyManager.entries.isEmpty
    }
    
    private var recentEntries: [WritingEntry] {
        Array(historyManager.entries.prefix(3))
    }
    
    var body: some View {
        ZStack {
            // Main welcome content
            VStack(spacing: 40) {
                Spacer()
                
                // Animated title with floating effect
                Text("Flow Writing")
                    .font(Font(settings.selectedFont.uiFont(size: 28)))
                    .foregroundColor(.black)
                    .kerning(2)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
                    .modifier(FloatingAnimation(isAnimating: floatingAnimation))
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.8)) {
                            titleOpacity = 1
                            titleOffset = 0
                        }
                        
                        // Start the gentle floating animation after initial appearance
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                                floatingAnimation = true
                            }
                        }
                    }
                
                VStack(spacing: 30) {
                    Text("A simple exercise to develop your creative thinking and writing skills.")
                        .font(Font(settings.selectedFont.uiFont(size: 16)))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 450)
                        .opacity(descriptionOpacity)
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                                descriptionOpacity = 1
                            }
                        }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        InfoRow(
                            number: "1",
                            text: "Three random words will appear at the top of your screen",
                            delay: 0.1
                        )
                        
                        InfoRow(
                            number: "2",
                            text: "Write freely based on these words without overthinking",
                            delay: 0.2
                        )
                        
                        InfoRow(
                            number: "3",
                            text: "Tap anywhere on the screen to hide the interface and focus",
                            delay: 0.3
                        )
                        
                        InfoRow(
                            number: "4",
                            text: "Generate new words anytime when you need fresh inspiration",
                            delay: 0.4
                        )
                    }
                    .padding(.horizontal, 60)
                    .opacity(infoRowsOpacity)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                            infoRowsOpacity = 1
                        }
                    }
                }
                
                Spacer()
                
                // Buttons row
                HStack(spacing: 20) {
                    // Tutorial button
                    Button {
                        withAnimation(.spring()) {
                            showTutorial = true
                            tutorialPage = 0
                        }
                    } label: {
                        Text("Quick Tutorial")
                            .font(Font(settings.selectedFont.uiFont(size: 14)))
                            .foregroundColor(.black.opacity(0.7))
                            .padding(.horizontal, 15)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    // Begin button
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
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white)
                                    .shadow(color: isHovering ? Color.black.opacity(0.15) : Color.black.opacity(0.1), 
                                           radius: isHovering ? 5 : 3, 
                                           x: 0, 
                                           y: isHovering ? 3 : 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.black.opacity(0.2), lineWidth: 0.5)
                            )
                            .scaleEffect(isHovering ? 1.03 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHovering = hovering
                        }
                    }
                }
                .padding(.bottom, 60)
                .opacity(buttonOpacity)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8).delay(0.9)) {
                        buttonOpacity = 1
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            
            // Tutorial overlay
            if showTutorial {
                TutorialOverlay(
                    isShowing: $showTutorial,
                    currentPage: $tutorialPage
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .onAppear {
            print("WelcomeView appeared")
        }
    }
}

// Interactive tutorial overlay
struct TutorialOverlay: View {
    @Binding var isShowing: Bool
    @Binding var currentPage: Int
    @ObservedObject private var settings = AppSettings.shared
    
    // Tutorial content data
    private let tutorials = [
        TutorialPage(
            title: "Inspiration Dice",
            description: "Three random words help spark your creativity. Click the refresh button to roll new words anytime.",
            imageName: "dice.fill",
            color: Color.blue.opacity(0.6)
        ),
        TutorialPage(
            title: "Focus Mode",
            description: "Tap anywhere on the writing area to hide interface elements and focus entirely on your writing.",
            imageName: "eye.fill",
            color: Color.purple.opacity(0.6)
        ),
        TutorialPage(
            title: "No Backspace Mode",
            description: "Enable 'No Backspace' mode to prevent editing and encourage forward momentum in your writing flow.",
            imageName: "delete.left.fill",
            color: Color.red.opacity(0.6)
        ),
        TutorialPage(
            title: "Lock Your Writing",
            description: "Lock completed writings to prevent accidental edits and keep them preserved exactly as you wrote them.",
            imageName: "lock.fill",
            color: Color.green.opacity(0.6)
        )
    ]
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Close tutorial when tapping outside
                    withAnimation {
                        isShowing = false
                    }
                }
            
            // Tutorial content card
            VStack(spacing: 25) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            isShowing = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.black.opacity(0.6))
                            .padding(8)
                            .background(Color.black.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Tutorial content - custom implementation for macOS
                ZStack {
                    // Show only the current tutorial page
                    ForEach(0..<tutorials.count, id: \.self) { index in
                        if index == currentPage {
                            TutorialPageView(page: tutorials[index])
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing),
                                    removal: .move(edge: .leading)
                                ))
                                .id(index) // Ensures view is refreshed when index changes
                        }
                    }
                }
                .frame(height: 300)
                .animation(.easeInOut, value: currentPage)
                .clipped() // Ensure content stays within bounds
                
                // Page indicator dots
                HStack(spacing: 10) {
                    ForEach(0..<tutorials.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.black.opacity(0.7) : Color.black.opacity(0.2))
                            .frame(width: 8, height: 8)
                            .onTapGesture {
                                withAnimation {
                                    currentPage = index
                                }
                            }
                    }
                }
                
                // Next/Prev buttons
                HStack {
                    // Back button
                    Button {
                        withAnimation {
                            currentPage = max(0, currentPage - 1)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14))
                            Text("Previous")
                                .font(Font(settings.selectedFont.uiFont(size: 14)))
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .foregroundColor(.black.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .opacity(currentPage > 0 ? 1 : 0.2)
                    .disabled(currentPage == 0)
                    
                    Spacer()
                    
                    // Next/Close button
                    Button {
                        withAnimation {
                            if currentPage < tutorials.count - 1 {
                                currentPage += 1
                            } else {
                                isShowing = false
                            }
                        }
                    } label: {
                        HStack {
                            Text(currentPage < tutorials.count - 1 ? "Next" : "Finish")
                                .font(Font(settings.selectedFont.uiFont(size: 14)))
                            
                            if currentPage < tutorials.count - 1 {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .frame(width: 500, height: 500)
            .clipShape(RoundedRectangle(cornerRadius: 16)) // Clip the entire card to prevent content overflow
        }
    }
}

// Tutorial page model
struct TutorialPage {
    let title: String
    let description: String
    let imageName: String
    let color: Color
}

// Individual tutorial page view
struct TutorialPageView: View {
    let page: TutorialPage
    @ObservedObject private var settings = AppSettings.shared
    @State private var animateIcon: Bool = false
    
    var body: some View {
        VStack(spacing: 25) {
            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 60))
                .foregroundColor(page.color)
                .scaleEffect(animateIcon ? 1.2 : 1.0)
                .padding(30)
                .background(
                    Circle()
                        .fill(page.color.opacity(0.1))
                )
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        animateIcon = true
                    }
                }
            
            // Title
            Text(page.title)
                .font(Font(settings.selectedFont.uiFont(size: 24)))
                .fontWeight(.medium)
                .foregroundColor(.black)
            
            // Description
            Text(page.description)
                .font(Font(settings.selectedFont.uiFont(size: 16)))
                .multilineTextAlignment(.center)
                .foregroundColor(.black.opacity(0.7))
                .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.top, 20)
    }
}

// Card view for recent writings
struct RecentWritingCard: View {
    let entry: WritingEntry
    let onTap: () -> Void
    
    @State private var isHovering: Bool = false
    @ObservedObject private var settings = AppSettings.shared
    
    // Format date
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: entry.date)
    }
    
    // Preview of content (first 80 chars)
    private var contentPreview: String {
        let content = entry.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let preview = String(content.prefix(80))
        return preview + (content.count > 80 ? "..." : "")
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(entry.title)
                    .font(Font(settings.selectedFont.uiFont(size: 14)))
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                // Date and word count
                HStack {
                    Text(formattedDate)
                        .font(Font(settings.selectedFont.uiFont(size: 11)))
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("\(entry.wordCount) words")
                        .font(Font(settings.selectedFont.uiFont(size: 11)))
                        .foregroundColor(.gray)
                    
                    if entry.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer(minLength: 5)
                
                // Content preview
                Text(contentPreview)
                    .font(Font(settings.selectedFont.uiFont(size: 12)))
                    .foregroundColor(.black.opacity(0.7))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: isHovering ? Color.black.opacity(0.15) : Color.black.opacity(0.08), 
                           radius: isHovering ? 8 : 5, 
                           x: 0, 
                           y: isHovering ? 4 : 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(isHovering ? 0.1 : 0.05), lineWidth: 0.5)
            )
            .scaleEffect(isHovering ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

// Custom floating animation modifier
struct FloatingAnimation: ViewModifier {
    let isAnimating: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(y: isAnimating ? -5 : 0)
    }
}

struct InfoRow: View {
    let number: String
    let text: String
    var delay: Double = 0
    
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 20
    
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
        .opacity(opacity)
        .offset(x: offset)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.5 + delay)) {
                opacity = 1
                offset = 0
            }
        }
    }
}

#Preview {
    WelcomeView(isShowingWelcome: .constant(true))
} 