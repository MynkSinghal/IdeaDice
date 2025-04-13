import SwiftUI
import AppKit
import Foundation

// Model for storing writing entries
struct WritingEntry: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var title: String
    var content: String
    var wordCount: Int
    
    static func createFromText(_ text: String) -> WritingEntry {
        let firstLine = text.split(separator: "\n").first ?? ""
        let title = String(firstLine.prefix(30))
        let wordCount = text.split(separator: " ").count
        
        return WritingEntry(
            date: Date(),
            title: title,
            content: text,
            wordCount: wordCount
        )
    }
}

// History manager to persist and retrieve writing entries
class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var entries: [WritingEntry] = []
    private let entriesKey = "writingEntries"
    
    init() {
        loadEntries()
    }
    
    func saveEntry(_ text: String) {
        guard !text.isEmpty else { return }
        
        let entry = WritingEntry.createFromText(text)
        entries.insert(entry, at: 0)
        saveEntries()
    }
    
    func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: entriesKey) {
            if let decodedEntries = try? JSONDecoder().decode([WritingEntry].self, from: data) {
                entries = decodedEntries
            }
        }
    }
    
    private func saveEntries() {
        if let encodedData = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encodedData, forKey: entriesKey)
        }
    }
    
    func deleteEntry(at indexSet: IndexSet) {
        entries.remove(atOffsets: indexSet)
        saveEntries()
    }
}

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
    @State private var showSidebar: Bool = false
    @ObservedObject private var historyManager = HistoryManager.shared
    
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
        
        // Get existing attributes from the current selection if possible
        let attributedString = NSMutableAttributedString(attributedString: currentEditor.attributedString())
        
        // Apply the appropriate style to the selected range, preserving existing attributes
        switch style {
        case .bold:
            // Get existing font or use system font
            let existingFont = attributedString.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? NSFont ?? NSFont.systemFont(ofSize: 18)
            
            // Create bold font with same size and other traits
            let fontDescriptor = existingFont.fontDescriptor
            let traits = fontDescriptor.symbolicTraits.union(.bold)
            let boldFontDescriptor = fontDescriptor.withSymbolicTraits(traits)
            
            if let boldFont = NSFont(descriptor: boldFontDescriptor, size: 0) {
                attributedString.addAttribute(.font, value: boldFont, range: selectedRange)
            } else {
                // Fallback to regular bold if we can't combine traits
                attributedString.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 18), range: selectedRange)
            }
            
        case .italic:
            // Get existing font or use system font
            let existingFont = attributedString.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? NSFont ?? NSFont.systemFont(ofSize: 18)
            
            // Create italic font with same size and other traits
            let fontDescriptor = existingFont.fontDescriptor
            let traits = fontDescriptor.symbolicTraits.union(.italic)
            let italicFontDescriptor = fontDescriptor.withSymbolicTraits(traits)
            
            if let italicFont = NSFont(descriptor: italicFontDescriptor, size: 0) {
                attributedString.addAttribute(.font, value: italicFont, range: selectedRange)
            }
            
        case .underline:
            // Add underline attribute (can coexist with other attributes)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: selectedRange)
        }
        
        // Apply the attributed string to the text view
        currentEditor.textStorage?.setAttributedString(attributedString)
        
        // Update the binding - convert to plain string for the binding
        noteText = currentEditor.string
        
        // Keep selection and toolbar visible to allow applying multiple formats
        currentEditor.setSelectedRange(selectedRange)
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
                HStack(spacing: 0) {
                    // Main content area
                    mainContent
                        .transition(.opacity)
                    
                    // History sidebar
                    if showSidebar {
                        historySidebar
                            .frame(width: 250)
                            .transition(.move(edge: .trailing))
                    }
                }
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
            forName: NSTextView.didChangeSelectionNotification,
            object: nil,
            queue: .main
        ) { [self] notification in
            guard let textView = notification.object as? NSTextView else { return }
            
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
        ZStack(alignment: .topTrailing) {
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
                    
                    // History toggle button
                    Button {
                        withAnimation(.spring()) {
                            showSidebar.toggle()
                        }
                    } label: {
                        Image(systemName: showSidebar ? "sidebar.right" : "sidebar.left")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.secondary)
                            .opacity(0.4)
                    }
                    .buttonStyle(.plain)
                    .help("Toggle History")
                    .padding(.trailing, 8)
                    
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
                        GeometryReader { geometry in
                            FormatToolbar(onBold: { formatSelectedText(style: .bold) },
                                       onItalic: { formatSelectedText(style: .italic) },
                                       onUnderline: { formatSelectedText(style: .underline) })
                                .opacity(0.95)
                                .position(x: geometry.size.width / 2, y: 50)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.2), value: showFormatToolbar)
                        }
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
                            // Save current entry before rolling new words
                            if !noteText.isEmpty {
                                historyManager.saveEntry(noteText)
                            }
                            
                            rollDice()
                            noteText = ""
                        } label: {
                            Text("Save & New")
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
            
            // Show small sidebar toggle button when sidebar is hidden
            if !showSidebar {
                sidebarToggleButton
                    .padding(.top, 70)
                    .padding(.trailing, 16)
                    .transition(.scale.combined(with: .opacity))
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
    
    // History sidebar view
    var historySidebar: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Writing History")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                Button {
                    withAnimation(.spring()) {
                        showSidebar = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(white: 0.97))
            
            // List of entries
            List {
                ForEach(historyManager.entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                        
                        HStack {
                            Text(formatDate(entry.date))
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("\(entry.wordCount) words")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Load this entry
                        noteText = entry.content
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    historyManager.deleteEntry(at: indexSet)
                }
            }
            
            // Bottom buttons
            VStack(spacing: 8) {
                // New Chat button
                Button {
                    // Save current entry if not empty
                    if !noteText.isEmpty {
                        historyManager.saveEntry(noteText)
                    }
                    
                    // Clear text and roll new words
                    noteText = ""
                    rollDice()
                } label: {
                    HStack {
                        Image(systemName: "plus.bubble")
                            .font(.system(size: 14))
                        Text("New Chat")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(white: 0.92))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                
                // Save button
                Button {
                    historyManager.saveEntry(noteText)
                } label: {
                    Text("Save Current Entry")
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .background(Color(white: 0.95))
                .disabled(noteText.isEmpty)
            }
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color.gray.opacity(0.2)), 
            alignment: .leading
        )
    }
    
    // Small sidebar toggle button that stays visible
    var sidebarToggleButton: some View {
        Button {
            withAnimation(.spring()) {
                showSidebar.toggle()
            }
        } label: {
            Image(systemName: "sidebar.left")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .padding(8)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .help("Show History")
    }
    
    // Helper function to format dates
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Separate formatting toolbar component
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
    ContentView()
} 