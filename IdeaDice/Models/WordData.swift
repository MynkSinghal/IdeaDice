import Foundation

struct WordData {
    static let nouns = [
        "Mirror", "Ocean", "Clock", "Forest", "Candle", "Cloud", "Dust", "Thread", "Path", "Flame",
        "Mountain", "River", "Book", "Door", "Window", "Sky", "Star", "Moon", "Sun", "Tree",
        "Bridge", "Island", "Desk", "Chair", "Pillow", "Bottle", "Glass", "Ring", "Key", "Coin",
        "Shadow", "Light", "Feather", "Stone", "Rain", "Snow", "Wind", "Fire", "Earth", "Water"
    ]
    
    static let verbs = [
        "Melt", "Breathe", "Collapse", "Bloom", "Chase", "Whisper", "Freeze", "Drift", "Grow", "Scatter",
        "Dance", "Sing", "Float", "Break", "Build", "Create", "Destroy", "Imagine", "Dream", "Fly",
        "Swim", "Run", "Jump", "Climb", "Fall", "Rise", "Shine", "Fade", "Transform", "Evolve",
        "Explore", "Discover", "Connect", "Separate", "Begin", "End", "Remember", "Forget", "Reflect", "Wonder"
    ]
    
    static let emotions = [
        "Nostalgia", "Anger", "Joy", "Serenity", "Confusion", "Hope", "Anxiety", "Delight", "Fear", "Wonder",
        "Love", "Hatred", "Excitement", "Boredom", "Curiosity", "Dread", "Peace", "Frustration", "Surprise", "Awe",
        "Gratitude", "Envy", "Pride", "Shame", "Trust", "Suspicion", "Longing", "Satisfaction", "Doubt", "Confidence",
        "Melancholy", "Bliss", "Contentment", "Regret", "Relief", "Anticipation", "Apathy", "Sympathy", "Loneliness", "Euphoria"
    ]
    
    static func randomNoun() -> String {
        return nouns.randomElement() ?? "Mirror"
    }
    
    static func randomVerb() -> String {
        return verbs.randomElement() ?? "Melt"
    }
    
    static func randomEmotion() -> String {
        return emotions.randomElement() ?? "Wonder"
    }
    
    static func rollDice() -> (noun: String, verb: String, emotion: String) {
        return (randomNoun(), randomVerb(), randomEmotion())
    }
} 