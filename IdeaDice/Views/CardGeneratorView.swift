import SwiftUI
import AppKit

struct CardGeneratorView: View {
    @ObservedObject var appSettings = AppSettings.shared
    @State private var selectedCategory: String = "All"
    @State private var cardData: [String: [String]] = [:]
    @State private var currentWord: String = ""
    @State private var currentLabel: String = ""
    @State private var shouldShowLabel: Bool = true
    @State private var isFlipped: Bool = false
    @State private var isBold: Bool = false
    @State private var isItalic: Bool = false
    @State private var isUnderlined: Bool = false
    @State private var isAnimating: Bool = false
    
    let categories = ["All", "Character", "Plot", "Setting", "Theme", "Worldbuilding"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Picker
            Picker("Category", selection: $selectedCategory) {
                ForEach(categories, id: \.self) { category in
                    Text(category).tag(category)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Spacer()
            
            // Word Card
            ZStack {
                WordCardView(
                    word: currentWord,
                    label: currentLabel,
                    shouldShowLabel: shouldShowLabel,
                    isBold: isBold,
                    isItalic: isItalic,
                    isUnderlined: isUnderlined,
                    isFlipped: isFlipped
                )
                .onTapGesture {
                    withAnimation {
                        isFlipped.toggle()
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Format Toolbar
            FormatToolbar(
                onBold: { isBold.toggle() },
                onItalic: { isItalic.toggle() },
                onUnderline: { isUnderlined.toggle() }
            )
            .padding(.horizontal)
            .padding(.top, 16)
            
            // Generate Button
            Button(action: generateNewWord) {
                HStack {
                    Image(systemName: "dice.fill")
                    Text("Generate New Idea")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
                .shadow(radius: 3)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
        .onAppear {
            loadCardData()
            generateNewWord()
        }
    }
    
    private func loadCardData() {
        if let url = Bundle.main.url(forResource: "card_data", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                cardData = try JSONDecoder().decode([String: [String]].self, from: data)
            } catch {
                print("Error loading card data: \(error)")
            }
        }
    }
    
    private func generateNewWord() {
        // Simple haptic feedback
        #if os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
        #endif
        
        withAnimation {
            isAnimating = true
            isFlipped = false
            
            let categoryData: [String]
            if selectedCategory == "All" {
                categoryData = cardData.values.flatMap { $0 }
            } else {
                categoryData = cardData[selectedCategory] ?? []
            }
                
            if !categoryData.isEmpty {
                let randomIndex = Int.random(in: 0..<categoryData.count)
                let fullString = categoryData[randomIndex]
                
                // Split by colon for label:word format
                let components = fullString.components(separatedBy: ":")
                
                if components.count > 1 {
                    currentLabel = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    currentWord = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    shouldShowLabel = true
                } else {
                    currentLabel = selectedCategory
                    currentWord = fullString.trimmingCharacters(in: .whitespacesAndNewlines)
                    shouldShowLabel = selectedCategory != "All"
                }
            }
            
            // Reset animation state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isAnimating = false
            }
        }
    }
}

#Preview {
    CardGeneratorView()
} 