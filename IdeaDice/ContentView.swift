import SwiftUI

struct ContentView: View {
    @State private var noun = WordData.randomNoun()
    @State private var verb = WordData.randomVerb()
    @State private var emotion = WordData.randomEmotion()
    @State private var noteText = ""
    @State private var isRolling = false
    @State private var showSettings = false
    @State private var isShowingWelcome = true  // Keep this true for initial launch
    @State private var isInitialized = false    // Add initialization tracking
    @ObservedObject private var settings = AppSettings.shared
    @FocusState private var isTextFieldFocused: Bool
    @State private var opacity: Double = 1.0
    
    // References to card views for animation
    @State private var nounCard: WordCardView?
    @State private var verbCard: WordCardView?
    @State private var emotionCard: WordCardView?
    
    // Ivory color
    private let backgroundColor = Color(red: 255/255, green: 255/255, blue: 240/255)
    
    var body: some View {
        NavigationView {
            if isShowingWelcome {
                WelcomeView(isShowingWelcome: $isShowingWelcome)
                    .background(backgroundColor)
                    .navigationTitle("")
                    .navigationBarHidden(true)
            } else {
                mainView
                    .navigationTitle("")
                    .navigationBarHidden(true)
                    .sheet(isPresented: $showSettings) {
                        SettingsView()
                            .background(backgroundColor)
                    }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Force new word generation on launch
            if !isInitialized {
                let newWords = WordData.rollDice()
                self.noun = newWords.noun
                self.verb = newWords.verb
                self.emotion = newWords.emotion
                isInitialized = true
                
                // Print app state for debugging
                print("ContentView appeared: words initialized")
            }
        }
    }
    
    var mainView: some View {
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
                        .foregroundStyle(.secondary)
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
                        .foregroundStyle(.secondary)
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
            TextEditor(text: $noteText)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .lineSpacing(6)
                .focused($isTextFieldFocused)
                .scrollContentBackground(.hidden)
                .background(backgroundColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(30)
                .overlay(
                    Group {
                        if noteText.isEmpty && !isTextFieldFocused {
                            Text("Begin typing based on the words above...")
                                .font(.system(size: 18, weight: .regular, design: .serif))
                                .foregroundStyle(.secondary.opacity(0.6))
                                .padding(.top, 30)
                                .padding(.leading, 30)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .allowsHitTesting(false)
                        }
                    }
                )
                .onTapGesture {
                    opacity = opacity == 1.0 ? 0.0 : 1.0
                }
            
            // Word count in footer
            HStack {
                Text("\(wordCount) words")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .opacity(0.5)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button {
                        noteText = ""
                    } label: {
                        Text("Clear")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .opacity(0.5)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        rollDice()
                    } label: {
                        Text("New Words")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .opacity(0.5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
            .background(backgroundColor.opacity(0.8))
            .opacity(opacity)
            .animation(.easeInOut(duration: 0.4), value: opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .onAppear {
            // Focus the text editor when the main view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
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