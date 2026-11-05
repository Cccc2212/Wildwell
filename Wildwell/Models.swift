import Foundation

struct World: Identifiable, Hashable {
    let id: String
    let name: String
    let dimension: String
    let subtitle: String
    let symbol: String
    let lesson: String
    let paragraphs: [String]
    let question: String
    let answers: [String]
    let correct: Int
    let explanation: String
    let challenge: String
    let instructions: String
    let alternative: String
    let minutes: Int
    let species: Species
}
struct Species: Identifiable, Hashable {
    let id: String
    let name: String
    let scientific: String
    let habitat: String
    let region: String
    let size: String
    let fact: String
    let source: String
    let sourceName: String
}
struct Practice: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    let worldID: String
    let method: String
    let seconds: Int
    var optionID: String?
    var speciesID: String?
    var rewardID: UUID?
    var reflection: String = ""
    var helpful: String = "Not recorded"
}
struct CheckIn: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    let mood: String
    let factor: String
    let note: String
}
struct WalkSession: Codable {
    let worldID: String
    var optionID: String?
    var gentler: Bool?
    var quickStart: Bool?
    var target: TimeInterval
    var accumulated: TimeInterval = 0
    var startedAt: Date?
    func elapsed(at date: Date = Date()) -> TimeInterval {
        min(target, max(0, accumulated + (startedAt.map { max(0, date.timeIntervalSince($0)) } ?? 0)))
    }
    mutating func pause(at date: Date = Date()) {
        accumulated = elapsed(at: date)
        startedAt = nil
    }
    mutating func resume(at date: Date = Date()) {
        guard startedAt == nil, accumulated < target else { return }
        startedAt = date
    }
}
struct SavedState: Codable {
    var learned: Set<String> = []
    var discoveries: [String: Date] = [:]
    var practices: [Practice] = []
    var checkIns: [CheckIn] = []
    var session: WalkSession?
    var pendingSpecies: String?
    var welcomed = false
    var preferences: Preferences?
    var pendingQueue: [String]?
    var lessonDrafts: [String: LessonDraft]?
    var rewards: [AnimalReward]?
    var pendingRewardIDs: [UUID]?
    var lastDailyPrompt: Date?
}

enum Catalog {
    static let worlds: [World] = [
        World(id: "forest", name: "Cloud Forest", dimension: "Physical wellbeing", subtitle: "A little movement. A fresh perspective.", symbol: "leaf.fill", lesson: "Make room for a movement break", paragraphs: ["A movement break is a short change from sitting or staying in one position. It can be a walk, a stretch, or movement that works for your body.", "Keep it manageable: choose a safe route and a comfortable pace. A break is an invitation to notice your surroundings, not a fitness test.", "Try linking a small break to something you already do, such as finishing a study session. Afterwards, notice whether the change felt useful to you."], question: "What makes a useful movement break?", answers: ["Pushing through discomfort", "Choosing movement that fits your body", "Beating yesterday’s distance"], correct: 1, explanation: "A comfortable, accessible choice is enough. Rest or adapt whenever you need.", challenge: "Take a noticing walk", instructions: "Choose a safe, familiar route. Move at your own pace and look for three different leaf shapes. Keep your attention on your surroundings rather than the screen.", alternative: "Stay seated and gently move your hands or shoulders, or simply observe three natural shapes from a window. This counts equally.", minutes: 5, species: Species(id: "panda", name: "Red panda", scientific: "Ailurus fulgens", habitat: "Temperate mountain forests with bamboo", region: "Himalayas and southwestern China", size: "Body 56–62.5 cm; tail 37–47.2 cm • 3.6–7.7 kg", fact: "A long, bushy tail helps with balance among branches. Bamboo makes up most of this tree-dweller’s diet.", source: "https://www.nationalzoo.si.edu/animals/red-panda", sourceName: "Smithsonian’s National Zoo")),
        World(id: "ocean", name: "Quiet Coast", dimension: "Mental wellbeing", subtitle: "Find an anchor in the here and now.", symbol: "water.waves", lesson: "Give your attention an anchor", paragraphs: ["Grounding means deliberately noticing what is around you. It is one way to bring your attention back when your thoughts feel busy.", "Pick a neutral object. Notice its colour, shape, texture, and the way light falls on it. You do not need to empty your mind or change how you feel.", "If an exercise feels uncomfortable, stop or switch to another activity. Different approaches suit different people and different days."], question: "When your mind wanders, you can…", answers: ["Gently return to one detail", "Decide you failed", "Force every thought away"], correct: 0, explanation: "Wandering is normal. Returning gently is the practice, and stopping is always an option.", challenge: "Notice five small details", instructions: "Look around a comfortable space. Find five things you can see and notice one detail about each. You can use sounds or textures instead if that suits you.", alternative: "Choose just one familiar object and describe its colour or texture to yourself. Stop whenever you want.", minutes: 3, species: Species(id: "otter", name: "Sea otter", scientific: "Enhydra lutris", habitat: "Coastal waters and kelp forests", region: "North Pacific coasts; southern subspecies along California", size: "Southern sea otters: up to about 1.2 m and 32 kg (aquarium overview)", fact: "Sea otters eat invertebrates such as crabs and sea urchins. Their feeding helps shape the coastal ecosystems they live in.", source: "https://www.montereybayaquarium.org/animals-the-ocean/animals-a-to-z/sea-otter", sourceName: "Monterey Bay Aquarium")),
        World(id: "woodland", name: "Kindred Woods", dimension: "Social wellbeing", subtitle: "Small moments of connection.", symbol: "tree.fill", lesson: "Connection can start small", paragraphs: ["Connection does not have to mean a big social event. A small, thoughtful exchange can be a way to express care or belonging.", "Try a specific message: ‘I remembered our walk last week. How are you going?’ Leave space for the other person to reply in their own time.", "Respect your boundaries too. You can draft a message without sending it, or think about a person or place that feels welcoming. A reply is not a measure of your worth."], question: "Which approach respects both people?", answers: ["Expecting an immediate reply", "Sending repeated messages until they answer", "Reaching out without demanding a response"], correct: 2, explanation: "Connection can be an invitation, with room for both people’s time and boundaries.", challenge: "Offer a little kindness", instructions: "Think of someone you feel comfortable contacting. Write a thoughtful message or thank them for something specific. Sending is your choice; Wildwell never sends messages for you.", alternative: "Draft a kind message without sending it, or remember a moment when someone made you feel welcome.", minutes: 2, species: Species(id: "fox", name: "Red fox", scientific: "Vulpes vulpes", habitat: "Woodland edges, grassland, farmland and cities", region: "Much of the Northern Hemisphere; introduced to Australia", size: "Head and body 45.5–90 cm; tail 30–55.5 cm • 3–14 kg", fact: "Red foxes adapt to many environments, including urban areas. Their diet includes small animals as well as fruit.", source: "https://animaldiversity.org/accounts/Vulpes_vulpes/", sourceName: "University of Michigan • Animal Diversity Web")),
        World(id: "wetland", name: "Feeling Wetlands", dimension: "Emotional wellbeing", subtitle: "Every feeling has room here.", symbol: "sun.haze.fill", lesson: "Name a feeling without judging it", paragraphs: ["Emotions can shift during the day, and more than one feeling can be present at once. There is no correct emotion to record.", "Try a simple observation: ‘I notice I feel tired, and I had a busy morning.’ This describes an experience without deciding that it is good or bad.", "Writing can help you remember what you noticed. It is optional and private on this device. A few entries cannot explain what caused a feeling or diagnose anything."], question: "Which is a non-judgmental observation?", answers: ["I should always feel happy", "I notice I feel unsettled today", "Feeling tired means I failed"], correct: 1, explanation: "Naming an experience leaves room for it without turning it into a score.", challenge: "Make space for a feeling", instructions: "Pause somewhere comfortable. Name a feeling silently, then notice one thing that may be on your mind. You may write about it afterwards, but you do not have to.", alternative: "If naming a feeling is not useful today, notice one neutral detail around you instead. Reflection and check-ins remain optional.", minutes: 1, species: Species(id: "axolotl", name: "Axolotl", scientific: "Ambystoma mexicanum", habitat: "Freshwater lakes and canals", region: "Valley of Mexico", size: "Up to 30 cm long", fact: "Axolotls keep feathery external gills throughout their aquatic lives. They can regrow entire limbs. Wild animals are usually dark; pale pink forms are familiar in captivity.", source: "https://www.amnh.org/explore/ology/ology-cards/366-axolotl", sourceName: "American Museum of Natural History"))
    ]
    static func world(_ id: String) -> World { worlds.first { $0.id == id } ?? worlds[0] }
}


struct Preferences: Codable {
    var minutes = 3
    var intention = "ocean"
    var gentler = false
    var favourites: Set<String> = []
}
struct PracticeOption: Identifiable, Hashable {
    let id: String
    let title: String
    let instructions: String
    let alternative: String
    let prompt: String
}
extension World {
    var speciesPool: [Species] { [species] + (Catalog.moreSpecies[id] ?? []) }
    var options: [PracticeOption] {
        [PracticeOption(id: id + "-1", title: challenge, instructions: instructions, alternative: alternative, prompt: "What did you notice? What might you keep or change next time?")] + (Catalog.moreOptions[id] ?? [])
    }
}
extension Catalog {
    static var allSpecies: [Species] { worlds.flatMap(\.speciesPool) }
    static func species(_ id: String) -> Species? { allSpecies.first { $0.id == id } }
    static func home(of species: Species) -> World { worlds.first { $0.speciesPool.contains(species) } ?? worlds[0] }
    static func option(_ id: String?, worldID: String) -> PracticeOption {
        let world = world(worldID)
        return world.options.first { $0.id == id } ?? world.options[0]
    }
    static let moreOptions: [String: [PracticeOption]] = [
        "forest": [
            PracticeOption(id: "forest-2", title: "Uncurl from your desk", instructions: "Pause your work. If comfortable, loosen your hands, change your seated position, and gently move your shoulders. Stay in a comfortable range; stop if anything hurts.", alternative: "Simply change where your hands rest or look away from your screen. Small adjustments count.", prompt: "Which change felt comfortable enough to use again?"),
            PracticeOption(id: "forest-3", title: "Plan a kinder wind-down", instructions: "Pick one small way to make this evening less busy: set a stopping point for work, put a book nearby, or write tomorrow’s first task. Choose just one.", alternative: "Think of one task that can wait. You do not have to make a full evening routine.", prompt: "What could make winding down easier in your real schedule?")
        ],
        "ocean": [
            PracticeOption(id: "ocean-2", title: "One thing at a time", instructions: "Choose one small task, such as tidying one corner or reading a paragraph. Give it your attention for your chosen time. If your mind wanders, gently return; finishing is not required.", alternative: "Choose one object to look at instead of doing a task. Notice just one feature.", prompt: "What helped you return your attention?"),
            PracticeOption(id: "ocean-3", title: "Park a busy thought", instructions: "Write one unfinished task or thought on paper. Add one tiny next step, or mark it ‘not for now’. Set it aside for this short break. You are not required to solve it.", alternative: "Silently name something you can leave until later. If this feels unhelpful, focus on a neutral object instead.", prompt: "Did setting something aside fit this moment? What would you change?")
        ],
        "woodland": [
            PracticeOption(id: "woodland-2", title: "Make room for a boundary", instructions: "Draft one sentence that protects your time kindly: ‘I can’t today, but I could…’ or ‘I need a little time to think’. You do not have to send it or explain further.", alternative: "Think of one request you are allowed to decline. No conversation is required.", prompt: "What boundary would make room for what matters to you?"),
            PracticeOption(id: "woodland-3", title: "Notice where you belong", instructions: "Remember a person, place, group or small routine where you feel welcome. Choose one realistic way to reconnect, whether visiting, drafting a message, or making a note for later.", alternative: "Imagine the qualities of a welcoming space. You do not have to name a person or take social action.", prompt: "What made that place or moment feel welcoming?")
        ],
        "wetland": [
            PracticeOption(id: "wetland-2", title: "Try a kinder sentence", instructions: "Think of a small difficulty today. Try describing it as you would to someone you care about: ‘That was a lot to handle’. You do not have to turn it into a positive story.", alternative: "Choose a neutral sentence, such as ‘This is the day I’m having’. Stop if reflection feels uncomfortable.", prompt: "Which words felt believable rather than forced?"),
            PracticeOption(id: "wetland-3", title: "Name one small need", instructions: "Ask yourself what would make the next hour a little more manageable. It might be quiet, company, water, a break or practical help. Choose one possible next step; it is okay if you cannot act on it yet.", alternative: "Simply notice a preference, like less noise or a different seat. You do not need an explanation.", prompt: "What did you need, and what might be possible next?")
        ]
    ]
    static let moreSpecies: [String: [Species]] = [
        "forest": [
            Species(id: "sloth", name: "Linnaeus’s two-toed sloth", scientific: "Choloepus didactylus", habitat: "Tropical rainforest canopy", region: "Northern South America", size: "Body 53–74 cm • about 4–8 kg", fact: "Algae can grow in grooves in a sloth’s coarse outer hairs, giving the fur a greenish tint that blends into the canopy.", source: "https://nationalzoo.si.edu/animals/two-toed-sloth", sourceName: "Smithsonian’s National Zoo"),
            Species(id: "lemur", name: "Ring-tailed lemur", scientific: "Lemur catta", habitat: "Dry forests and open areas", region: "Southwestern Madagascar", size: "Tail up to 61 cm • adult males about 3 kg", fact: "Travelling ring-tailed lemurs hold their striped tails upright like flags, helping a group stay together.", source: "https://nationalzoo.si.edu/animals/ring-tailed-lemur", sourceName: "Smithsonian’s National Zoo")
        ],
        "ocean": [
            Species(id: "turtle", name: "Green sea turtle", scientific: "Chelonia mydas", habitat: "Coastal feeding grounds and open ocean", region: "Tropical and subtropical waters worldwide", size: "About 0.9–1.2 m long • up to about 181 kg", fact: "Young green turtles eat a mixed diet. As they mature, seagrasses and algae become important foods.", source: "https://www.montereybayaquarium.org/animals-the-ocean/animals-a-to-z/green-turtle", sourceName: "Monterey Bay Aquarium"),
            Species(id: "ray", name: "Bat ray", scientific: "Myliobatis californica", habitat: "Sandy and muddy bays, kelp forests and reefs", region: "Eastern Pacific, from Oregon to the Gulf of California; also near the Galápagos", size: "Females: wingspan up to 1.8 m • up to 90.7 kg", fact: "Bat rays flap their broad pectoral fins to uncover buried prey. Their fused tooth plates crush hard shells.", source: "https://www.montereybayaquarium.org/animals-the-ocean/animals-a-to-z/bat-ray", sourceName: "Monterey Bay Aquarium")
        ],
        "woodland": [
            Species(id: "owl", name: "Great horned owl", scientific: "Bubo virginianus", habitat: "Woodlands, open fields and many other habitats", region: "North, Central and parts of South America", size: "Length 45.7–63.5 cm • wingspan 127–152.4 cm", fact: "Those ‘horns’ are feather tufts. This adaptable owl has forward-facing yellow eyes and a pale throat patch.", source: "https://animaldiversity.org/accounts/Bubo_virginianus/", sourceName: "University of Michigan • Animal Diversity Web"),
            Species(id: "rabbit", name: "Eastern cottontail", scientific: "Sylvilagus floridanus", habitat: "Edges between woody cover and open land", region: "Eastern and central North America into parts of Central and northern South America", size: "Adult length about 39.5–47.7 cm", fact: "The white underside of its short tail flashes as an eastern cottontail runs. Shrubby cover offers shelter near open feeding areas.", source: "https://animaldiversity.org/accounts/Sylvilagus_floridanus/", sourceName: "University of Michigan • Animal Diversity Web")
        ],
        "wetland": [
            Species(id: "frog", name: "American bullfrog", scientific: "Lithobates catesbeianus", habitat: "Ponds, lakes and other freshwater margins", region: "Native to eastern and central North America; introduced elsewhere", size: "Typical adult body length about 9–15.2 cm", fact: "A bullfrog begins life as a tadpole with a tail and gills. Development in the water may last several years before metamorphosis.", source: "https://animaldiversity.org/accounts/Lithobates_catesbeianus/", sourceName: "University of Michigan • Animal Diversity Web"),
            Species(id: "heron", name: "Great blue heron", scientific: "Ardea herodias", habitat: "Marshes, rivers, lakes and coastal shallows", region: "North and Central America and the Caribbean; some migrate farther south", size: "Length about 97–137 cm • about 2.1–2.5 kg", fact: "Great blue herons use waterside habitats to find food and often nest in groups called rookeries in nearby trees.", source: "https://animaldiversity.org/accounts/Ardea_herodias/", sourceName: "University of Michigan • Animal Diversity Web")
        ]
    ]
}

/// Calendar-day operations use Calendar arithmetic, so DST days need not be 24 hours.
enum MoodCalendar {
    static func monthStart(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .month, for: date)!.start
    }
    static func cells(in month: Date, calendar: Calendar = .current) -> [Date?] {
        let start = monthStart(month, calendar: calendar)
        let count = calendar.range(of: .day, in: .month, for: start)!.count
        let offset = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        let padding = (7 - (offset + count) % 7) % 7
        return Array(repeating: nil, count: offset) + (0..<count).map { calendar.date(byAdding: .day, value: $0, to: start) } + Array(repeating: nil, count: padding)
    }
    static func week(containing date: Date, calendar: Calendar = .current) -> [Date] {
        let start = calendar.dateInterval(of: .weekOfYear, for: date)!.start
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
    static func entries(_ entries: [CheckIn], on date: Date, calendar: Calendar = .current) -> [CheckIn] {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return entries.filter { $0.date >= start && $0.date < end }.sorted { $0.date < $1.date }
    }
    static func entries(_ entries: [CheckIn], in interval: DateInterval) -> [CheckIn] {
        entries.filter { $0.date >= interval.start && $0.date < interval.end }.sorted { $0.date < $1.date }
    }
}

// Cosmetic character rarity is independent of biology, mood, duration and effort.
enum CharacterRarity: String, Codable, CaseIterable, Identifiable {
    case rare, epic, myth
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String { switch self { case .rare: "diamond.fill"; case .epic: "sparkles"; case .myth: "crown.fill" } }
    static func rolled(_ value: Int) -> Self {
        precondition((0..<100).contains(value))
        return value < 70 ? .rare : value < 95 ? .epic : .myth
    }
}
struct RewardDraw {
    let speciesIndex: Int
    let rarityRoll: Int
    static func random(poolSize: Int) -> Self {
        RewardDraw(speciesIndex: Int.random(in: 0..<poolSize), rarityRoll: Int.random(in: 0..<100))
    }
}
struct AnimalReward: Codable, Identifiable, Hashable {
    var id = UUID()
    let speciesID: String
    let rarity: CharacterRarity
    let date: Date
    let practiceID: UUID?
    var originWorldID: String?
    var isDailyCheckIn: Bool?
    var backdropIndex: Int?
    var variantID: String { speciesID + "-" + rarity.rawValue }
}
struct CharacterVariant: Identifiable {
    let species: Species
    let rarity: CharacterRarity
    let copies: [AnimalReward]
    var id: String { species.id + "-" + rarity.rawValue }
}


struct LessonDraft: Codable, Equatable {
    var step: Int = 0
    var optionID: String
    var answer: Int?
}
extension CharacterRarity {
    var revealTaps: Int { switch self { case .rare: 1; case .epic: 2; case .myth: 3 } }
    var starCount: Int { switch self { case .rare: 6; case .epic: 12; case .myth: 18 } }
    var revealHint: String { switch self { case .rare: "A blue star is stirring"; case .epic: "A purple constellation is waking"; case .myth: "A crimson sky is about to bloom" } }
}


extension Species {
    // Illustrative intervals in millimetres. Where the guide lists a maximum,
    // use a narrower interval below it for the simulated card measurement.
    var cardMeasurement: (label: String, range: ClosedRange<Int>) {
        switch id {
        case "panda": ("Body length", 560...625)
        case "sloth": ("Body length", 530...740)
        case "lemur": ("Tail length", 500...610)
        case "otter": ("Total length", 1000...1200)
        case "turtle": ("Length", 900...1200)
        case "ray": ("Wingspan", 1200...1800)
        case "fox": ("Head and body", 455...900)
        case "owl": ("Body length", 457...635)
        case "rabbit": ("Body length", 395...477)
        case "frog": ("Body length", 90...152)
        case "heron": ("Body length", 970...1370)
        default: ("Total length", 200...300) // Axolotl
        }
    }
}

extension AnimalReward {
    // Each persisted UUID gives its copy a stable size, including older cards.
    func sizeInMillimetres(for species: Species) -> Int {
        let range = species.cardMeasurement.range
        let bytes = id.uuid
        let sample = Int(bytes.0) * 256 + Int(bytes.1)
        return range.lowerBound + sample % range.count
    }

    func sizeLabel(for species: Species) -> String {
        let centimetres = Double(sizeInMillimetres(for: species)) / 10
        return "\(species.cardMeasurement.label) · \(centimetres.formatted(.number.precision(.fractionLength(0...1)))) cm"
    }
}


enum CardBackdrop: Int, CaseIterable {
    case daylight, sunset, moonlight

    var title: String {
        switch self {
        case .daylight: "Daylight"
        case .sunset: "Sunset"
        case .moonlight: "Moonlight"
        }
    }
}

extension AnimalReward {
    var backdrop: CardBackdrop {
        let index = backdropIndex.flatMap(CardBackdrop.init(rawValue:))
        return index ?? CardBackdrop.allCases[Int(id.uuid.2) % CardBackdrop.allCases.count]
    }
}
