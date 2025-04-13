import SwiftUI
import AppKit

struct ContentView: View {
    @State private var noun = WordData.randomNoun()
    @State private var verb = WordData.randomVerb()
    @State private var emotion = WordData.randomEmotion()
    @State private var noteText = ""
    @State private var isRolling = false
    @State private var showSettings = false
    @State private var isShowingWelcome = true
    @State private var isInitialized = false
    @ObservedObject private var settings = AppSettings.shared
    @FocusState private var isTextFieldFocused: Bool
    @State private var opacity: Double = 1.0
    @State private var selectedText: String = ""
    @State private var showFormatToolbar: Bool = false
    @State private var selectionObserver: Any?
    
    // References to card views for animation
    @State private var nounCard: WordCardView?
    @State private var verbCard: WordCardView?
    @State private var emotionCard: WordCardView?
    
    // Ivory color - using Color.white with opacity for better compatibility
    private let backgroundColor = Color.white
    
    // Text formatting functions
    func formatSelectedText(style: TextStyle) {
        guard !selectedText.isEmpty else { return }
        
        // Get the selected range from the current first responder
        guard let currentEditor = NSApp.keyWindow?.firstResponder as? NSTextView else { return }
        let selectedRange = currentEditor.selectedRange()
        
        let formattedText: String
        
        switch style {
        case .bold:
            formattedText = "**\(selectedText)**"
        case .italic:
            formattedText = "*\(selectedText)*"
        case .underline:
            formattedText = "_\(selectedText)_"
        }
        
        // Replace the selected text with the formatted text
        currentEditor.textStorage?.replaceCharacters(in: selectedRange, with: formattedText)
        
        // Update the binding
        noteText = currentEditor.string
        
        // Reset selection state
        selectedText = ""
        showFormatToolbar = false
    }
    
    enum TextStyle {
        case bold, italic, underline
    }
    
    var body: some View {
        ZStack {
            // Background - explicitly use Color.white which is more reliable
            Color.white.edgesIgnoringSafeArea(.all)
            
            // Main content
            if isShowingWelcome {
                WelcomeView(isShowingWelcome: $isShowingWelcome)
                    .transition(.opacity)
            } else {
                mainContent
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            print("ContentView appeared with isShowingWelcome: \(isShowingWelcome)")
            
            // Force new word generation on launch
            if !isInitialized {
                let newWords = WordData.rollDice()
                self.noun = newWords.noun
                self.verb = newWords.verb
                self.emotion = newWords.emotion
                isInitialized = true
                
                print("Words initialized: \(noun), \(verb), \(emotion)")
            }
            
            // Setup selection change notification observer
            setupSelectionObserver()
        }
        .onDisappear {
            // Clean up observers
            if let observer = selectionObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
    
    func setupSelectionObserver() {
        // Remove existing observer if any
        if let observer = selectionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Add notification observer for selection changes
        selectionObserver = NotificationCenter.default.addObserver(
            forName: NSText.didChangeSelectionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let textView = notification.object as? NSTextView else { return }
            
            let selectedRange = textView.selectedRange()
            if selectedRange.length > 0 {
                let selectedText = (textView.string as NSString).substring(with: selectedRange)
                self.selectedText = selectedText
                self.showFormatToolbar = true
            } else {
                self.selectedText = ""
                self.showFormatToolbar = false
            }
        }
    }
    
    var mainContent: some View {
        VStack(spacing: 0) {
            // Word Cards in a discreet horizontal row
            HStack(spacing: 16) {
                Spacer()
                
                // Word cards side by side at the top
                WordCardView(word: noun, label: "NOUN", color: .primary)
                    .frame(width: 120)
                    .overlay(GeometryReader { geometry in
                        Color.clear.onAppear {
                            nounCard = WordCardView(word: noun, label: "NOUN", color: .primary)
                        }
                    })
                
                WordCardView(word: verb, label: "VERB", color: .primary)
                    .frame(width: 120)
                    .overlay(GeometryReader { geometry in
                        Color.clear.onAppear {
                            verbCard = WordCardView(word: verb, label: "VERB", color: .primary)
                        }
                    })
                
                WordCardView(word: emotion, label: "EMOTION", color: .primary)
                    .frame(width: 120)
                    .overlay(GeometryReader { geometry in
                        Color.clear.onAppear {
                            emotionCard = WordCardView(word: emotion, label: "EMOTION", color: .primary)
                        }
                    })
                
                Button {
                    rollDice()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.secondary)
                        .opacity(0.6)
                }
                .buttonStyle(.plain)
                .help("Roll new words")
                .padding(.leading, 8)
                
                Spacer()
                
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.secondary)
                        .opacity(0.4)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
                .help("Settings")
            }
            .padding(.vertical, 16)
            .opacity(opacity)
            .animation(.easeInOut(duration: 0.4), value: opacity)
            
            // Enhanced Writing Area
            ZStack(alignment: .top) {
                TextEditor(text: $noteText)
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .lineSpacing(6)
                    .focused($isTextFieldFocused)
                    .scrollContentBackground(.hidden)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(30)
                    .overlay(
                        Group {
                            if noteText.isEmpty && !isTextFieldFocused {
                                Text("Begin typing based on the words above...")
                                    .font(.system(size: 18, weight: .regular, design: .serif))
                                    .foregroundColor(.secondary.opacity(0.6))
                                    .padding(.top, 30)
                                    .padding(.leading, 30)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    .allowsHitTesting(false)
                            }
                        }
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            opacity = opacity == 1.0 ? 0.0 : 1.0
                        }
                    }
                
                // Formatting toolbar overlay when text is selected
                if showFormatToolbar && !selectedText.isEmpty {
                    HStack(spacing: 16) {
                        Button(action: { formatSelectedText(style: .bold) }) {
                            Image(systemName: "bold")
                                .frame(width: 40, height: 30)
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)
                        .help("Bold")
                        
                        Button(action: { formatSelectedText(style: .underline) }) {
                            Image(systemName: "underline")
                                .frame(width: 40, height: 30)
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)
                        .help("Underline")
                        
                        Button(action: { formatSelectedText(style: .italic) }) {
                            Image(systemName: "italic")
                                .frame(width: 40, height: 30)
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)
                        .help("Italic")
                    }
                    .padding(8)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .padding(.top, 10)
                }
            }
            
            // Word count in footer
            HStack {
                Text("\(wordCount) words")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.secondary)
                    .opacity(0.5)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button {
                        noteText = ""
                    } label: {
                        Text("Clear")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(.secondary)
                            .opacity(0.5)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        rollDice()
                    } label: {
                        Text("New Words")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(.secondary)
                            .opacity(0.5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.8))
            .opacity(opacity)
            .animation(.easeInOut(duration: 0.4), value: opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Focus the text editor when the main view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
                print("Main content appeared, focusing text field")
            }
        }
    }
    
    private var wordCount: Int {
        noteText.split(separator: " ").count
    }
    
    func rollDice() {
        // Play animation
        isRolling = true
        
        // Animate card flips using optional chaining to handle potential nil values
        nounCard?.animate()
        verbCard?.animate()
        emotionCard?.animate()
        
        // Play sound effect if enabled
        if settings.soundEnabled {
            SoundManager.shared.playDiceRollSound()
        }
        
        // Update the words after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let newWords = WordData.rollDice()
            self.noun = newWords.noun
            self.verb = newWords.verb
            self.emotion = newWords.emotion
            
            // Reset rolling state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isRolling = false
            }
        }
    }
}

#Preview {
    ContentView()
} 