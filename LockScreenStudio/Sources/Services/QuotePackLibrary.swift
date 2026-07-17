import Foundation

/// Curated, bundled quote packs for the Quote panel.
///
/// Content rules (enforced at review time, not runtime):
/// - Public-domain content only (published before 1928, classical, or proverb) — short
///   phrases aren't copyrightable, but we keep attribution risk at zero.
/// - Attributions verified against primary sources; famous-but-misattributed
///   lines ("We are what we repeatedly do…") are deliberately excluded.
/// - Kept short so they render well on a wallpaper.
///
/// Selection is deterministic per day: regenerating three times in one morning
/// yields the same quote (matching the app's "this is today's look" model);
/// tomorrow brings the next one.
enum QuotePackLibrary {

    struct Quote: Equatable {
        let text: String
        let author: String
    }

    struct Pack: Identifiable {
        let id: String
        let name: String
        let systemImage: String
        let quotes: [Quote]
    }

    /// Deterministic daily quote for a pack. Same calendar day → same quote,
    /// including across process relaunches (intents and background tasks run
    /// in fresh processes, so this must not depend on `String.hashValue`,
    /// which is seeded per process).
    static func todaysQuote(packID: String, on date: Date = .now) -> Quote? {
        guard let pack = pack(id: packID), !pack.quotes.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        // Offset by a process-stable per-pack hash so packs don't rotate in
        // lockstep.
        let offset = Int(stableHash(packID) % UInt64(pack.quotes.count))
        return pack.quotes[(day + offset) % pack.quotes.count]
    }

    /// FNV-1a over UTF-8 — stable across launches, devices, and app versions,
    /// unlike `String.hashValue`. Internal (not private) so a regression test
    /// can pin its output.
    static func stableHash(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }

    static func pack(id: String) -> Pack? {
        allPacks.first { $0.id == id }
    }

    static let allPacks: [Pack] = [
        Pack(
            id: "stoic",
            name: "Stoic",
            systemImage: "building.columns",
            quotes: [
                Quote(text: "Waste no more time arguing about what a good man should be. Be one.", author: "Marcus Aurelius"),
                Quote(text: "The happiness of your life depends upon the quality of your thoughts.", author: "Marcus Aurelius"),
                Quote(text: "What stands in the way becomes the way.", author: "Marcus Aurelius"),
                Quote(text: "Confine yourself to the present.", author: "Marcus Aurelius"),
                Quote(text: "Very little is needed to make a happy life; it is all within yourself.", author: "Marcus Aurelius"),
                Quote(text: "If it is not right, do not do it; if it is not true, do not say it.", author: "Marcus Aurelius"),
                Quote(text: "Do not act as if you were going to live ten thousand years.", author: "Marcus Aurelius"),
                Quote(text: "It is not death that a man should fear, but never beginning to live.", author: "Marcus Aurelius"),
                Quote(text: "How much time he gains who does not look to see what his neighbour does.", author: "Marcus Aurelius"),
                Quote(text: "The soul becomes dyed with the color of its thoughts.", author: "Marcus Aurelius"),
                Quote(text: "It is not that we have a short time to live, but that we waste a lot of it.", author: "Seneca"),
                Quote(text: "We suffer more often in imagination than in reality.", author: "Seneca"),
                Quote(text: "Begin at once to live, and count each separate day as a separate life.", author: "Seneca"),
                Quote(text: "He who is brave is free.", author: "Seneca"),
                Quote(text: "Difficulties strengthen the mind, as labor does the body.", author: "Seneca"),
                Quote(text: "While we wait for life, life passes.", author: "Seneca"),
                Quote(text: "No man was ever wise by chance.", author: "Seneca"),
                Quote(text: "Hang on to your youthful enthusiasms — you'll be able to use them better when you're older.", author: "Seneca"),
                Quote(text: "Wealth consists not in having great possessions, but in having few wants.", author: "Epictetus"),
                Quote(text: "First say to yourself what you would be; and then do what you have to do.", author: "Epictetus"),
                Quote(text: "No man is free who is not master of himself.", author: "Epictetus"),
                Quote(text: "Don't explain your philosophy. Embody it.", author: "Epictetus"),
                Quote(text: "Make the best use of what is in your power, and take the rest as it happens.", author: "Epictetus"),
                Quote(text: "It's not what happens to you, but how you react to it that matters.", author: "Epictetus"),
            ]
        ),
        Pack(
            id: "focus",
            name: "Focus & Discipline",
            systemImage: "scope",
            quotes: [
                Quote(text: "Well begun is half done.", author: "Aristotle"),
                Quote(text: "It does not matter how slowly you go as long as you do not stop.", author: "Confucius"),
                Quote(text: "The man who moves a mountain begins by carrying away small stones.", author: "Confucius"),
                Quote(text: "Do the difficult things while they are easy.", author: "Lao Tzu"),
                Quote(text: "A journey of a thousand miles begins with a single step.", author: "Lao Tzu"),
                Quote(text: "By failing to prepare, you are preparing to fail.", author: "Benjamin Franklin"),
                Quote(text: "Little strokes fell great oaks.", author: "Benjamin Franklin"),
                Quote(text: "Energy and persistence conquer all things.", author: "Benjamin Franklin"),
                Quote(text: "Never leave that till tomorrow which you can do today.", author: "Benjamin Franklin"),
                Quote(text: "Lost time is never found again.", author: "Benjamin Franklin"),
                Quote(text: "Diligence is the mother of good luck.", author: "Benjamin Franklin"),
                Quote(text: "One today is worth two tomorrows.", author: "Benjamin Franklin"),
                Quote(text: "Great works are performed not by strength but by perseverance.", author: "Samuel Johnson"),
                Quote(text: "What we hope ever to do with ease, we must learn first to do with diligence.", author: "Samuel Johnson"),
                Quote(text: "Genius is one percent inspiration, ninety-nine percent perspiration.", author: "Thomas Edison"),
                Quote(text: "There is no substitute for hard work.", author: "Thomas Edison"),
                Quote(text: "Concentrate all your thoughts upon the work in hand.", author: "Alexander Graham Bell"),
                Quote(text: "Patience and diligence, like faith, remove mountains.", author: "William Penn"),
                Quote(text: "Dripping water hollows out stone, not through force but through persistence.", author: "Ovid"),
                Quote(text: "The beginnings of all things are small.", author: "Cicero"),
                Quote(text: "He conquers who conquers himself.", author: "Publilius Syrus"),
                Quote(text: "When the wind does not serve, take to the oars.", author: "Latin proverb"),
                Quote(text: "Fall seven times and stand up eight.", author: "Japanese proverb"),
                Quote(text: "A smooth sea never made a skilled sailor.", author: "Proverb"),
            ]
        ),
        Pack(
            id: "calm",
            name: "Calm & Simplicity",
            systemImage: "leaf",
            quotes: [
                Quote(text: "Nature does not hurry, yet everything is accomplished.", author: "Lao Tzu"),
                Quote(text: "He who knows that enough is enough will always have enough.", author: "Lao Tzu"),
                Quote(text: "Knowing others is intelligence; knowing yourself is true wisdom.", author: "Lao Tzu"),
                Quote(text: "Silence is a source of great strength.", author: "Lao Tzu"),
                Quote(text: "Live in each season as it passes; breathe the air, drink the drink, taste the fruit.", author: "Henry David Thoreau"),
                Quote(text: "It's not what you look at that matters, it's what you see.", author: "Henry David Thoreau"),
                Quote(text: "Simplify, simplify.", author: "Henry David Thoreau"),
                Quote(text: "A man is rich in proportion to the number of things he can afford to let alone.", author: "Henry David Thoreau"),
                Quote(text: "This life is not for complaint, but for satisfaction.", author: "Henry David Thoreau"),
                Quote(text: "Adopt the pace of nature: her secret is patience.", author: "Ralph Waldo Emerson"),
                Quote(text: "Write it on your heart that every day is the best day in the year.", author: "Ralph Waldo Emerson"),
                Quote(text: "Finish each day and be done with it. You have done what you could.", author: "Ralph Waldo Emerson"),
                Quote(text: "Nothing can bring you peace but yourself.", author: "Ralph Waldo Emerson"),
                Quote(text: "The obstacle is the path.", author: "Zen proverb"),
                Quote(text: "Tension is who you think you should be. Relaxation is who you are.", author: "Chinese proverb"),
                Quote(text: "The best time to plant a tree was twenty years ago. The second best time is now.", author: "Proverb"),
                Quote(text: "Still waters run deep.", author: "Proverb"),
                Quote(text: "Rest is not idleness.", author: "John Lubbock"),
                Quote(text: "In character, in manner, in style, in all things, the supreme excellence is simplicity.", author: "Henry Wadsworth Longfellow"),
                Quote(text: "The day is of infinite length for him who knows how to appreciate and use it.", author: "Johann Wolfgang von Goethe"),
                Quote(text: "He is richest who is content with the least.", author: "Socrates"),
                Quote(text: "Beware the barrenness of a busy life.", author: "Socrates"),
                Quote(text: "Order your soul. Reduce your wants.", author: "Augustine"),
                Quote(text: "Everything has beauty, but not everyone sees it.", author: "Confucius"),
            ]
        ),
        Pack(
            id: "motivation",
            name: "Motivation",
            systemImage: "flame",
            quotes: [
                Quote(text: "Do what you can, with what you have, where you are.", author: "Theodore Roosevelt"),
                Quote(text: "It is hard to fail, but it is worse never to have tried to succeed.", author: "Theodore Roosevelt"),
                Quote(text: "Whatever you can do, or dream you can, begin it.", author: "Johann Wolfgang von Goethe"),
                Quote(text: "Knowing is not enough; we must apply. Willing is not enough; we must do.", author: "Johann Wolfgang von Goethe"),
                Quote(text: "Our greatest glory is not in never falling, but in rising every time we fall.", author: "Confucius"),
                Quote(text: "Hitch your wagon to a star.", author: "Ralph Waldo Emerson"),
                Quote(text: "Act as if what you do makes a difference. It does.", author: "William James"),
                Quote(text: "Alter your attitudes and you can alter your life.", author: "William James"),
                Quote(text: "Fortune favors the bold.", author: "Virgil"),
                Quote(text: "They can because they think they can.", author: "Virgil"),
                Quote(text: "While there's life, there's hope.", author: "Cicero"),
                Quote(text: "No pressure, no diamonds.", author: "Thomas Carlyle"),
                Quote(text: "Go as far as you can see; when you get there, you'll see farther.", author: "Thomas Carlyle"),
                Quote(text: "The best way out is always through.", author: "Robert Frost"),
                Quote(text: "Hope is the thing with feathers that perches in the soul.", author: "Emily Dickinson"),
                Quote(text: "We know what we are, but know not what we may be.", author: "William Shakespeare"),
                Quote(text: "It is not in the stars to hold our destiny but in ourselves.", author: "William Shakespeare"),
                Quote(text: "Heaven never helps the man who will not act.", author: "Sophocles"),
                Quote(text: "The secret of success is constancy to purpose.", author: "Benjamin Disraeli"),
                Quote(text: "Either I will find a way, or I will make one.", author: "Philip Sidney"),
                Quote(text: "What is not started today is never finished tomorrow.", author: "Johann Wolfgang von Goethe"),
                Quote(text: "Big results require big ambitions.", author: "Heraclitus"),
                Quote(text: "To dare is to lose one's footing momentarily. Not to dare is to lose oneself.", author: "Søren Kierkegaard"),
                Quote(text: "Strong reasons make strong actions.", author: "William Shakespeare"),
            ]
        ),
    ]
}
