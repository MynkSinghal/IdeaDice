import SwiftUI
import AppKit

struct WritingEditor: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var historyManager = HistoryManager.shared
    @Binding var noteText: String
    @Binding var isLocked: Bool
    @Binding var opacity: Double
    @Binding var selectedText: String
    @Binding var showFormatToolbar: Bool
    @Binding var isEditorFocused: Bool
    @FocusState private var isTextFieldFocused: Bool
    
    // State to track if this is the first edit
    @State private var isFirstEdit: Bool = true
    
    // Default placeholder text
    private let placeholderText = "Start writing based on the inspiration words above...\n\nLet your thoughts flow freely without overthinking."
    
    // Callbacks
    var onFormatBold: () -> Void
    var onFormatItalic: () -> Void
    var onFormatUnderline: () -> Void
    var onTimerStart: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            TextEditor(text: Binding(
                get: { noteText },
                set: { newValue in
                    // Only update the text if not locked
                    if !isLocked {
                        // Check if this is the first edit and we still have the placeholder
                        if isFirstEdit && noteText == placeholderText {
                            // Clear the placeholder when user starts typing
                            noteText = newValue.replacingOccurrences(of: placeholderText, with: "")
                            isFirstEdit = false
                        } else {
                            noteText = newValue
                        }
                    }
                }
            ))
                .font(Font(settings.selectedFont.uiFont(size: 18)))
                .lineSpacing(6)
                .focused($isTextFieldFocused)
                .scrollContentBackground(.hidden)
                .background(Color.white)
                .foregroundColor(isFirstEdit && noteText == placeholderText ? .gray.opacity(0.7) : .black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(30)
                .scrollIndicators(.hidden)
                .disabled(isLocked)
                .onTapGesture {
                    if !isLocked {
                        // Clear placeholder on tap if it's the first edit
                        if isFirstEdit && noteText == placeholderText {
                            noteText = ""
                            isFirstEdit = false
                        }
                        
                        withAnimation(.easeInOut(duration: 0.4)) {
                            opacity = opacity == 1.0 ? 0.0 : 1.0
                        }
                    }
                }
                .onChange(of: noteText) { _, newValue in
                    if !isLocked {
                        // Don't save placeholder text to history
                        if !(isFirstEdit && newValue == placeholderText) {
                            historyManager.autoSave(newValue)
                            
                            // Use dispatchQueue to avoid modifying state during view update
                            DispatchQueue.main.async {
                                // Start the writing timer if it's not already running
                                if !newValue.isEmpty {
                                    onTimerStart()
                                }
                            }
                        }
                    } else {
                        // If locked, immediately revert any changes by restoring content from history
                        if let entryId = historyManager.currentlyViewingLockedEntryId ?? historyManager.currentlyEditingEntry?.id,
                           let entry = historyManager.entries.first(where: { $0.id == entryId }) {
                            DispatchQueue.main.async {
                                // Always revert when locked to ensure no edits are possible
                                noteText = entry.content
                            }
                        }
                    }
                }
                // Sync the FocusState with the binding
                .onChange(of: isTextFieldFocused) { _, newFocusValue in
                    isEditorFocused = newFocusValue
                }
                .overlay(
                    Group {
                        // Only show empty state placeholder when there's no text and placeholder has been cleared
                        if noteText.isEmpty && !isTextFieldFocused && !isFirstEdit {
                            Text("Begin typing based on the words above...")
                                .font(Font(settings.selectedFont.uiFont(size: 18)))
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(.top, 30)
                                .padding(.leading, 30)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .allowsHitTesting(false)
                        }
                        
                        // Lock overlay when content is locked
                        if isLocked {
                            ZStack {
                                // Semi-transparent overlay to prevent interaction
                                Color.white.opacity(0.05)
                                    .allowsHitTesting(true)
                                
                                VStack {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.black.opacity(0.3))
                                    Text("This writing is locked")
                                        .font(Font(settings.selectedFont.uiFont(size: 14)))
                                        .foregroundColor(.black.opacity(0.5))
                                }
                                .padding(20)
                                .background(Color.white.opacity(0.7))
                                .cornerRadius(12)
                            }
                        }
                    }
                )
            
            // Formatting toolbar overlay when text is selected
            if showFormatToolbar && !selectedText.isEmpty && !isLocked {
                GeometryReader { geometry in
                    FormatToolbar(
                        onBold: onFormatBold,
                        onItalic: onFormatItalic,
                        onUnderline: onFormatUnderline
                    )
                    .opacity(0.95)
                    .position(x: geometry.size.width / 2, y: 50)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: showFormatToolbar)
                }
            }
        }
        .onAppear {
            // Initialize with placeholder text if empty
            if noteText.isEmpty && historyManager.currentlyEditingEntry == nil {
                noteText = placeholderText
                isFirstEdit = true
            } else {
                isFirstEdit = false
            }
            
            // Focus the text editor when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
                isEditorFocused = true
            }
        }
    }
}

#Preview {
    WritingEditor(
        noteText: .constant("Sample text for preview..."),
        isLocked: .constant(false),
        opacity: .constant(1.0),
        selectedText: .constant(""),
        showFormatToolbar: .constant(false),
        isEditorFocused: .constant(false),
        onFormatBold: {},
        onFormatItalic: {},
        onFormatUnderline: {},
        onTimerStart: {}
    )
} 