# 🎲 Idea Dice – Creativity Spark Generator (macOS App)

## 1. Problem Statement  
Creators often face creative blocks. Whether you're a writer stuck on a blank page, a designer searching for a theme, or a poet looking for inspiration — a small spark can make all the difference. Most tools available are too bloated or online-dependent. There’s a need for a **simple, offline, beautiful Mac app** that provides just enough frictionless inspiration.

---

## 2. Solution Overview  
**Idea Dice** is a minimalist macOS app built in SwiftUI that shows three randomly selected words every time the user presses a button:
- One **noun** (e.g., "mirror")
- One **verb** (e.g., "fracture")
- One **emotion** (e.g., "nostalgia")

These word sets encourage spontaneous writing, design ideas, poetry sparks, or storyboarding — serving as bite-sized creative fuel.

---

## 3. Core Features  

| Feature | Description |
|--------|-------------|
| 🎲 Random Prompt Generator | Click a button to roll three words from local lists |
| 🖼️ Animated Dice Roll | Smooth flip or fade animation for visual joy |
| 🎨 Minimalist UI | Elegant typography and layout with inspiring aesthetic |
| 📝 Micro-Writing Box *(Optional)* | Type 1-2 lines instantly — no saving, just to express |
| 🎧 Optional Sound Effects | A soft roll sound or chime on each new prompt |
| 🌙 Dark Mode Support | Follows system dark/light theme for comfort |

---

## 4. Out of Scope (MVP)  
- User authentication or profiles  
- Data saving, syncing, or exporting  
- Advanced customization or settings panel  
- Cloud storage or APIs

---

## 5. User Flow  
**Home View (Main Window)**  
- App title or logo  
- Three word slots (noun, verb, emotion) shown on cards or blocks  
- “🎲 Roll the Dice” button  
- Optional `TextEditor` for quick idea jotting (disposable)  

**Interaction Flow**  
1. User launches the app  
2. Clicks the button → animations play → new words appear  
3. Optionally types a few lines based on prompt  
4. Exits or rolls again — no data is saved

---

## 6. Design Inspiration  
- Typography: Monospaced or rounded serif fonts (for creative feel)  
- Aesthetic: Inspired by iA Writer, Bear App, and vintage index cards  
- Color: Soft pastels / muted tones, with ambient color changes  
- Animations: SwiftUI transitions like `.opacity`, `.slide`, or `.rotation3DEffect`

---

## 7. Technical Requirements  
- **Language**: Swift 5  
- **UI Framework**: SwiftUI (target: macOS)  
- **Data**: Static local JSON or array for word banks  
- **Randomizer**: Native `Int.random(in:)` or `shuffled()` methods  
- **UI Elements**: `VStack`, `Button`, `Text`, `TextEditor`, with transitions

---

## 8. Word Bank (Sample)  
**Nouns**
- Mirror, Ocean, Clock, Forest, Candle, Cloud, Dust, Thread, Path, Flame

**Verbs**
- Melt, Breathe, Collapse, Bloom, Chase, Whisper, Freeze, Drift, Grow, Scatter

**Emotions**
- Nostalgia, Anger, Joy, Serenity, Confusion, Hope, Anxiety, Delight, Fear, Wonder

> Stored as static arrays or in a local `.json` or `.plist` file within the app bundle.

---

## 9. Timeline

| Week | Deliverable |
|------|-------------|
| Week 1 | SwiftUI project setup, layout design, word list creation |
| Week 2 | Randomizer logic, animations, dice-roll feature |
| Week 3 | Add optional writing area, sound effects, polish |
| Week 4 | Final design polish, dark mode, screen responsiveness testing |

---

## 10. Success Metrics  
- App launches fast and works entirely offline  
- Prompts are consistently unique and creatively stimulating  
- UI feels smooth, warm, and minimal — sparking joy and ideas  
- Users report using it as a go-to tool during creative blocks  
