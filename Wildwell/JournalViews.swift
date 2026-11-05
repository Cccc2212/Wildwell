import SwiftUI
import Charts

struct CabinetView: View {
    @FocusState private var searchFocused: Bool
    @Environment(WildStore.self) private var store
    @State private var search = ""
    @State private var rarity = "all"
    @State private var worldFilter = "all"
    @State private var reviewing: AnimalReward?
    private var visibleVariants: [CharacterVariant] {
        store.variants.filter { variant in
            (worldFilter == "all" || Catalog.home(of: variant.species).id == worldFilter) && (rarity == "all" || variant.rarity.rawValue == rarity) && (search.isEmpty || variant.species.name.localizedCaseInsensitiveContains(search) || variant.species.scientific.localizedCaseInsensitiveContains(search))
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Eyebrow(text: "Your wild little company")
                Text("Animal characters").font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("\(store.rewards.count) characters • \(store.variants.count) animal & rarity variants").font(.subheadline).foregroundStyle(.secondary).accessibilityIdentifier("collection.totals")
                if let next = store.pendingRewards.first {
                    Button { reviewing = next } label: { Label("\(store.pendingRewards.count) arrival(s) to revisit", systemImage: "sparkles").frame(maxWidth: .infinity).panel() }.buttonStyle(.plain)
                }
                if search.isEmpty && worldFilter == "all" && rarity == "all" {
                    fieldGuide
                }
                HStack {
                    TextField("Search your animals", text: $search).textFieldStyle(.roundedBorder).accessibilityLabel("Search characters").focused($searchFocused).submitLabel(.search).onSubmit { searchFocused = false }
                    Picker("Rarity", selection: $rarity) {
                        Text("All rarities").tag("all")
                        ForEach(CharacterRarity.allCases) { Text($0.title).tag($0.rawValue) }
                    }.pickerStyle(.menu).accessibilityIdentifier("collection.rarity")
                }
                Picker("Study world", selection: $worldFilter) {
                    Text("All study worlds").tag("all")
                    ForEach(Catalog.worlds) { Text($0.name).tag($0.id) }
                }.pickerStyle(.menu).accessibilityIdentifier("collection.world")
                if visibleVariants.isEmpty {
                    ContentUnavailableView(store.rewards.isEmpty ? "Your first companion awaits" : "No matching characters", systemImage: "pawprint", description: Text(store.rewards.isEmpty ? "Finish a wellbeing practice or save today’s check-in to welcome a random animal character." : "Try another animal name or rarity."))
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 14)], spacing: 14) {
                    ForEach(visibleVariants) { variant in
                        NavigationLink { CharacterDetail(variant: variant) } label: {
                            VStack(alignment: .leading, spacing: 11) {
                                CharacterPortrait(species: variant.species, rarity: variant.rarity, backdrop: variant.copies.first?.backdrop ?? .daylight).frame(height: 150)
                                RarityBadge(rarity: variant.rarity)
                                Text(variant.species.name).font(.system(.subheadline, design: .rounded, weight: .bold)).frame(minHeight: 40, alignment: .topLeading)
                                Text(Catalog.home(of: variant.species).name).font(.caption2).foregroundStyle(Palette.tint(Catalog.home(of: variant.species).id))
                                Text("×\(variant.copies.count) collected").font(.caption).foregroundStyle(.secondary)
                            }.padding(12)
                                .background(.white, in: RoundedRectangle(cornerRadius: 26))
                                .contentShape(RoundedRectangle(cornerRadius: 26))
                        }.buttonStyle(.plain).accessibilityElement(children: .combine).accessibilityIdentifier("character.\(variant.id)")
                    }
                }
                DisclosureGroup("How character rewards work") {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Each study world has its own three animals. Completing any practice draws one animal from that world, including repeat activities. Animals in that world are equally likely; rarity is drawn independently.")
                        Text("Your first new check-in for today draws from all four worlds. The feeling you choose does not change the draw.")
                        HStack { RarityBadge(rarity: .rare); Spacer(); Text("70%") }
                        HStack { RarityBadge(rarity: .epic); Spacer(); Text("25%") }
                        HStack { RarityBadge(rarity: .myth); Spacer(); Text("5%") }
                        Text("Duplicate animal and rarity combinations add a copy. Every copy is kept. Mood, duration, timer use and gentler alternatives do not change the chances.")
                        Text("Rarity is a cosmetic game label, not a species’ conservation status. There are no purchases or paid draws.").font(.caption).foregroundStyle(.secondary)
                    }.font(.subheadline).padding(.top, 14)
                }.panel()
                if store.rewards.contains(where: { $0.practiceID == nil && $0.isDailyCheckIn != true }) {
                    Text("Your earlier species discoveries have been preserved as Rare characters, with their original discovery dates.").font(.caption).foregroundStyle(.secondary)
                }
            }.page().padding(.bottom, 24)
        }.background(Palette.cream).navigationTitle("Collection").navigationBarTitleDisplayMode(.inline)
            .sheet(item: $reviewing) { reward in
                NavigationStack { ScrollView { RewardRevealView(reward: reward) { store.acknowledgeReward(reward.id); reviewing = nil }.page() }.background(Palette.cream) }
            }
    }

    private var fieldGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Field guide").font(.system(.title2, design: .rounded, weight: .bold))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 135), spacing: 10)], spacing: 10) {
                ForEach(Catalog.worlds) { world in
                    NavigationLink {
                        WorldFieldGuide(world: world)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Label(world.name, systemImage: world.symbol)
                                .font(.subheadline.bold())
                                .foregroundStyle(Palette.tint(world.id))
                            Text("\(store.discoveredCount(in: world))/\(world.speciesPool.count) found")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .padding(8)
                        .background(Palette.sky(world.id).opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
                        .contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityIdentifier("guide.world.\(world.id)")
                }
            }
        }.panel()
    }
}

struct WorldFieldGuide: View {
    let world: World
    @Environment(WildStore.self) private var store

    var body: some View {
        let variants = store.variants
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Eyebrow(text: world.dimension)
                Text("\(store.discoveredCount(in: world)) of \(world.speciesPool.count) species found")
                    .font(.title2.bold())
                ForEach(world.speciesPool) { species in
                    let owned = CharacterRarity.allCases.compactMap { rarity in
                        variants.first { $0.species.id == species.id && $0.rarity == rarity }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text(species.name).font(.headline)
                        if owned.isEmpty {
                            Label("Still to discover", systemImage: "binoculars")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        ForEach(owned) { variant in
                            NavigationLink {
                                CharacterDetail(variant: variant)
                            } label: {
                                HStack {
                                    RarityBadge(rarity: variant.rarity)
                                    Text("×\(variant.copies.count)").font(.subheadline)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption.bold())
                                }.frame(minHeight: 44).contentShape(Rectangle())
                            }.buttonStyle(.plain).accessibilityIdentifier("guide.card.\(variant.id)")
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).panel()
                }
            }.page()
        }.background(Palette.cream).navigationTitle(world.name).navigationBarTitleDisplayMode(.inline)
    }
}
struct CharacterDetail: View {
    let variant: CharacterVariant
    @Environment(WildStore.self) private var store
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                CharacterPortrait(species: variant.species, rarity: variant.rarity, backdrop: variant.copies.first?.backdrop ?? .daylight).frame(height: 270)
                HStack {
                    RarityBadge(rarity: variant.rarity)
                    Spacer()
                    if let latest = variant.copies.first { CardShareButton(reward: latest, species: variant.species) }
                }
                Text(variant.species.name).font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("\(variant.copies.count) \(variant.copies.count == 1 ? "copy" : "copies") collected").font(.title3).foregroundStyle(.secondary)
                Label(Catalog.home(of: variant.species).name, systemImage: Catalog.home(of: variant.species).symbol).font(.subheadline).foregroundStyle(.secondary)
                Text(variant.species.fact).font(.subheadline).accessibilityIdentifier("card.wildlifeFact")
                Text("Your variants of this animal").font(.headline)
                HStack(spacing: 12) {
                    ForEach(CharacterRarity.allCases) { rarity in
                        let count = store.rewards.filter { $0.speciesID == variant.species.id && $0.rarity == rarity }.count
                        VStack(spacing: 8) { RarityBadge(rarity: rarity); Text(count == 0 ? "Not collected" : "×\(count)").font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity)
                    }
                }
                NavigationLink { SpeciesDetail(world: Catalog.home(of: variant.species), species: variant.species) } label: { Label("About this real species", systemImage: "book.closed").frame(maxWidth: .infinity).padding(8) }.buttonStyle(.borderedProminent)
                Text("Every arrival").font(.headline)
                Text("Each card has an illustrative size.").font(.caption).foregroundStyle(.secondary)
                ForEach(variant.copies) { copy in
                    VStack(alignment: .leading, spacing: 12) {
                        CharacterPortrait(species: variant.species, rarity: variant.rarity, backdrop: copy.backdrop)
                            .frame(height: 165)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(copy.backdrop.title) edition").font(.headline)
                                Text(copy.date.formatted(date: .abbreviated, time: .shortened)).font(.subheadline.bold())
                                Label(copy.sizeLabel(for: variant.species), systemImage: "ruler").font(.subheadline)
                            }
                            Spacer()
                            CardShareButton(reward: copy, species: variant.species)
                        }
                        if let practiceID = copy.practiceID, let practice = store.state.practices.first(where: { $0.id == practiceID }) {
                            Text(Catalog.option(practice.optionID, worldID: practice.worldID).title).font(.caption).foregroundStyle(.secondary)
                        } else { Text(copy.isDailyCheckIn == true ? "Daily check-in" : "Preserved from an earlier discovery").font(.caption).foregroundStyle(.secondary) }
                    }.frame(maxWidth: .infinity, alignment: .leading).panel()
                }
            }.page()
        }.background(Palette.cream).navigationTitle("Character card").navigationBarTitleDisplayMode(.inline)
    }
}

struct SpeciesDetail: View {
    let world: World
    var species: Species? = nil
    private var animal: Species { species ?? world.species }
    @Environment(WildStore.self) private var store
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HabitatArt(world: world, species: animal).frame(height: 290).clipShape(RoundedRectangle(cornerRadius: 30))
                Eyebrow(text: "Field guide • \(world.name)")
                Text(animal.name).font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text(animal.scientific).font(.title3).italic()
                if let date = store.state.discoveries[animal.id] { Label("Discovered \(date.formatted(date: .abbreviated, time: .omitted))", systemImage: "checkmark.seal.fill").font(.subheadline).foregroundStyle(Palette.green) }
                VStack(alignment: .leading, spacing: 18) {
                    fact("Home", animal.habitat, "leaf")
                    fact("Where in the world", animal.region, "globe.americas")
                    fact("Size", animal.size, "ruler")
                }.frame(maxWidth: .infinity, alignment: .leading).panel()
                Text("A wild little fact").font(.title2.bold())
                Text(animal.fact).font(.title3).lineSpacing(5)
                Text("Original cartoon artwork; simplified features and colours. Not a wildlife identification guide. Size varies by individual and population.").font(.footnote).foregroundStyle(.secondary)
                Link(destination: URL(string: animal.source)!) { Label(animal.sourceName, systemImage: "arrow.up.right.square") }
                Text("Facts checked November 2026. Source links open in your browser; the app’s content works offline.").font(.caption).foregroundStyle(.secondary)
                NavigationLink("Revisit this world") { WorldView(world: world) }.buttonStyle(.bordered)
            }.page()
        }.background(Palette.cream).navigationTitle("Species card").navigationBarTitleDisplayMode(.inline)
    }
    private func fact(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack(alignment: .top, spacing: 14) { Image(systemName: icon).frame(width: 24).foregroundStyle(Palette.tint(world.id)); VStack(alignment: .leading, spacing: 5) { Text(title).font(.caption.bold()).foregroundStyle(.secondary); Text(value) } }
    }
}
struct CheckInView: View {
    var initialDate: Date = Date()
    var existing: CheckIn? = nil
    var daily = false
    @State private var earnedReward: AnimalReward?
    @State private var recordedDate = Date()
    @Environment(WildStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var mood: String?
    @State private var factor = "Nothing in particular"
    @State private var note = ""
    let moods = ["Bright", "Steady", "Tired", "Unsettled", "Low", "Mixed"]
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let earnedReward {
                        RewardRevealView(reward: earnedReward) {
                            store.acknowledgeReward(earnedReward.id)
                            dismiss()
                        }
                    } else {
                        Eyebrow(text: daily ? "Daily check-in" : "A moment to notice")
                        Text(existing == nil ? "How did this moment feel?" : "A closer look at this moment").font(.system(.largeTitle, design: .rounded, weight: .bold))
                        Text(daily ? "Take a moment for yourself. Save a check-in to find a surprise animal card. Every feeling is welcome." : "All feelings belong. The feeling you choose never changes your card or progress.").foregroundStyle(.secondary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(moods, id: \.self) { item in
                                Button { mood = item } label: { HStack { MoodEmblem(mood: item, size: 26); Text(item); Spacer(); Image(systemName: mood == item ? "checkmark.circle.fill" : "circle") }.padding(18).foregroundStyle(Palette.ink).background(mood == item ? Palette.sky("forest") : .white, in: RoundedRectangle(cornerRadius: 18)) }.buttonStyle(.plain).accessibilityAddTraits(mood == item ? .isSelected : [])
                            }
                        }
                        DisclosureGroup("Add a detail") {
                            VStack(alignment: .leading, spacing: 16) {
                                if !daily {
                                    DatePicker("Recorded moment", selection: $recordedDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                                        .accessibilityIdentifier("mood.recordedDate")
                                }
                                Picker("Contributing factor", selection: $factor) {
                                    ForEach(["Nothing in particular", "Study", "Work", "Sleep", "Relationships", "Other"], id: \.self) { Text($0) }
                                }.pickerStyle(.menu)
                                TextField("Optional note, just for you", text: $note, axis: .vertical).lineLimit(3...6).panel()
                            }.padding(.top, 12)
                        }.panel()
                        Text("Stored locally on this device. You decide whether to include it in an export.").font(.footnote).foregroundStyle(.secondary)
                    }
                }.page()
            }
                .id(earnedReward?.id)
                .background(Palette.cream)
                .safeAreaInset(edge: .bottom) {
                    if earnedReward == nil {
                        PrimaryButton(title: "Save check-in", symbol: "checkmark", action: save)
                            .disabled(mood == nil)
                            .opacity(mood == nil ? 0.5 : 1)
                            .padding(.horizontal, 20).padding(.vertical, 8)
                            .background(Palette.cream)
                    }
                }
                .toolbar {
                    if earnedReward == nil {
                        ToolbarItem(placement: .cancellationAction) { Button(daily ? "Skip today" : "Cancel") { dismiss() } }
                    }
                }
                .onAppear {
                    if let existing { mood = existing.mood; factor = existing.factor; note = existing.note; recordedDate = existing.date }
                    else { recordedDate = Calendar.current.isDateInToday(initialDate) ? Date() : Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: initialDate)! }
                }
        }
    }

    private func save() {
        guard let mood else { return }
        let date = daily ? Date() : recordedDate
        if let reward = store.checkIn(mood: mood, factor: factor, note: note.trimmingCharacters(in: .whitespacesAndNewlines), date: date, editingID: existing?.id) {
            earnedReward = reward
        } else {
            dismiss()
        }
    }
}
struct MoodLook {
    static let names = ["Bright", "Low", "Mixed", "Steady", "Tired", "Unsettled"]
    static func color(_ mood: String) -> Color {
        switch mood {
        case "Bright": Color(red: 0.82, green: 0.52, blue: 0.16)
        case "Steady": Color(red: 0.23, green: 0.52, blue: 0.46)
        case "Low": Color(red: 0.49, green: 0.45, blue: 0.68)
        case "Tired": Color(red: 0.34, green: 0.48, blue: 0.65)
        case "Unsettled": Color(red: 0.72, green: 0.42, blue: 0.38)
        default: Color(red: 0.62, green: 0.43, blue: 0.59)
        }
    }
    static func symbol(_ mood: String) -> String {
        switch mood {
        case "Bright": "sun.max.fill"
        case "Steady": "leaf.fill"
        case "Low": "cloud.fill"
        case "Tired": "moon.fill"
        case "Unsettled": "wind"
        default: "circle.lefthalf.filled"
        }
    }
}
struct MoodFlower: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        for step in 0...180 {
            let angle = Double(step) / 180 * .pi * 2
            let r = radius * (0.82 + 0.18 * cos(6 * angle))
            let point = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath(); return path
    }
}
struct MoodEmblem: View {
    let mood: String
    var size: CGFloat = 32
    var body: some View {
        ZStack {
            MoodFlower().fill(MoodLook.color(mood).opacity(0.18))
            Image(systemName: MoodLook.symbol(mood)).font(.system(size: size * 0.40, weight: .semibold)).foregroundStyle(MoodLook.color(mood))
        }.frame(width: size, height: size).accessibilityHidden(true)
    }
}
struct JourneyView: View {
    @Environment(WildStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    @State private var period = "Month"
    @State private var checkIn = false
    @State private var editing: CheckIn?
    @State private var includePrivate = false
    @State private var chartDate: Date?
    private var calendar: Calendar { .current }
    private var dayEntries: [CheckIn] { MoodCalendar.entries(store.state.checkIns, on: selectedDate) }
    private var dayPractices: [Practice] { store.state.practices.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }.sorted { $0.date < $1.date } }
    private var monthInterval: DateInterval { calendar.dateInterval(of: .month, for: displayedMonth)! }
    private var monthEntries: [CheckIn] { MoodCalendar.entries(store.state.checkIns, in: monthInterval) }
    private var weekDays: [Date] { MoodCalendar.week(containing: selectedDate) }
    private var weekInterval: DateInterval { DateInterval(start: weekDays[0], end: calendar.date(byAdding: .day, value: 1, to: weekDays[6])!) }
    private var weekEntries: [CheckIn] { MoodCalendar.entries(store.state.checkIns, in: weekInterval) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack { Eyebrow(text: "A picture of your days"); Spacer(); Button("Today") { goToToday() }.font(.subheadline.bold()).accessibilityIdentifier("calendar.today") }
                Text("Your days, in colour.").font(.system(.title, design: .rounded, weight: .bold))
                Text("A place for every feeling. Notice your days without judging them.").font(.subheadline).foregroundStyle(.secondary)
                Picker("Calendar view", selection: $period) { Text("Month").tag("Month"); Text("Week").tag("Week") }.pickerStyle(.segmented)
                calendarPanel
                if period == "Week" { weekRecap; weekChart }
                selectedDayPanel
                monthSummary
                DisclosureGroup("Progress & reflection history") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("\(store.state.learned.count) lessons • \(store.state.practices.count) practices • \(store.rewards.count) characters").font(.subheadline).foregroundStyle(.secondary)
                        if store.state.practices.isEmpty { Text("Your practices will appear here when you try one.").font(.subheadline) }
                        ForEach(store.state.practices) { practice in practiceLink(practice) }
                    }.padding(.top, 12)
                }.panel()
                exportPanel
            }.page().padding(.bottom, 24)
        }.background(Palette.cream).navigationTitle("Mood calendar").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $checkIn) { CheckInView(initialDate: selectedDate) }
            .sheet(item: $editing) { entry in CheckInView(initialDate: entry.date, existing: entry) }
            .onChange(of: chartDate) { _, value in
                if let value, value <= Date(), weekInterval.contains(value) { selectedDate = value; displayedMonth = value }
            }
    }
    private var calendarPanel: some View {
        VStack(spacing: 12) {
            HStack {
                Button { movePeriod(-1) } label: { Image(systemName: "chevron.left").frame(width: 40, height: 40) }.accessibilityLabel("Previous \(period.lowercased())").accessibilityIdentifier("calendar.previous")
                Spacer()
                VStack(spacing: 3) {
                    Text(period == "Month" ? displayedMonth.formatted(.dateTime.month(.wide).year()) : weekDays[0].formatted(.dateTime.month(.abbreviated).day()) + " – " + weekDays[6].formatted(.dateTime.month(.abbreviated).day())).font(.system(.headline, design: .rounded))
                    if period == "Month" { Text("Tap a day to look a little closer").font(.caption).foregroundStyle(.secondary) }
                }
                Spacer()
                Button { movePeriod(1) } label: { Image(systemName: "chevron.right").frame(width: 40, height: 40) }.disabled(!canMoveForward).accessibilityLabel("Next \(period.lowercased())").accessibilityIdentifier("calendar.next")
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 4) {
                ForEach(0..<7, id: \.self) { index in
                    Text(calendar.shortStandaloneWeekdaySymbols[(calendar.firstWeekday - 1 + index) % 7]).font(.caption2.bold()).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
                if period == "Month" {
                    let cells = MoodCalendar.cells(in: displayedMonth)
                    ForEach(cells.indices, id: \.self) { index in
                        if let date = cells[index] { dayCell(date) } else { Color.clear.frame(height: 52).accessibilityHidden(true) }
                    }
                } else {
                    ForEach(weekDays, id: \.self) { dayCell($0) }
                }
            }
            HStack(spacing: 14) {
                Label("Feeling logged", systemImage: "sun.max.fill")
                Label("Practice", systemImage: "leaf.fill")
                Spacer()
            }.font(.caption2).foregroundStyle(.secondary)
            DisclosureGroup("Feeling colours & symbols") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 85))], alignment: .leading, spacing: 10) {
                    ForEach(MoodLook.names, id: \.self) { mood in HStack(spacing: 5) { MoodEmblem(mood: mood, size: 24); Text(mood).font(.caption) } }
                }.padding(.top, 10)
            }.font(.caption)
            Text("Symbols show the latest feeling. Dots mean more entries; blank days have no entry.").font(.caption2).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
        }.panel()
    }
    private func dayCell(_ date: Date) -> some View {
        let entries = MoodCalendar.entries(store.state.checkIns, on: date)
        let selected = calendar.isDate(date, inSameDayAs: selectedDate)
        let future = calendar.startOfDay(for: date) > calendar.startOfDay(for: Date())
        let practiceCount = store.state.practices.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
        return Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { selectedDate = date; if period == "Week" { displayedMonth = date } }
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: date))").font(.system(.caption, design: .rounded, weight: selected || calendar.isDateInToday(date) ? .bold : .regular))
                if let last = entries.last { MoodEmblem(mood: last.mood, size: 22) }
                else { Circle().stroke(Palette.ink.opacity(future ? 0.04 : 0.10), lineWidth: 1).frame(width: 20, height: 20).padding(1) }
                HStack(spacing: 2) {
                    if entries.count > 1 {
                        ForEach(Array(entries.dropLast().suffix(2).enumerated()), id: \.offset) { _, entry in Circle().fill(MoodLook.color(entry.mood)).frame(width: 4, height: 4) }
                        if entries.count > 3 { Text("+").font(.system(size: 8)) }
                    }
                    if practiceCount > 0 { Image(systemName: "leaf.fill").font(.system(size: 7)).foregroundStyle(Palette.green) }
                }.frame(height: 5)
            }.frame(maxWidth: .infinity, minHeight: 48).padding(.vertical, 2)
                .background(selected ? Palette.green.opacity(0.09) : .clear, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(selected ? Palette.green : .clear, lineWidth: 1.5))
                .foregroundStyle(future ? Palette.ink.opacity(0.25) : Palette.ink)
        }.buttonStyle(.plain).disabled(future)
            .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
            .accessibilityValue("\(entries.count) check-ins\(entries.last.map { ", latest feeling: " + $0.mood } ?? ""), \(practiceCount) practices")
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityIdentifier("mood.day.\(calendar.component(.year, from: date))-\(calendar.component(.month, from: date))-\(calendar.component(.day, from: date))")
    }
    private var selectedDayPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(calendar.isDateInToday(selectedDate) ? "Today" : selectedDate.formatted(.dateTime.weekday(.wide))).font(.system(.title2, design: .rounded, weight: .bold))
                    Text(selectedDate.formatted(date: .long, time: .omitted)).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if let last = dayEntries.last { MoodEmblem(mood: last.mood, size: 50) }
            }
            if dayEntries.isEmpty {
                Text("No feeling recorded for this day.").font(.headline)
                Text("You can leave it blank, or add something you remember. Every day does not need an entry.").font(.subheadline).foregroundStyle(.secondary)
            } else {
                ForEach(dayEntries) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        MoodEmblem(mood: entry.mood, size: 36)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack { Text(entry.mood).font(.headline); Spacer(); Text(entry.date.formatted(date: .omitted, time: .shortened)).font(.caption).foregroundStyle(.secondary) }
                            if entry.factor != "Nothing in particular" { Text(entry.factor).font(.caption).foregroundStyle(MoodLook.color(entry.mood)) }
                            if !entry.note.isEmpty { Text(entry.note).font(.subheadline) }
                            Button("Edit entry") { editing = entry }.font(.caption).accessibilityLabel("Edit \(entry.mood) entry")
                        }
                    }.padding(.vertical, 6)
                }
            }
            PrimaryButton(title: dayEntries.isEmpty ? "Log a feeling" : "Add another moment", symbol: "plus") { checkIn = true }.accessibilityIdentifier("mood.add")
            if !dayPractices.isEmpty {
                Divider()
                Label("Also part of this day", systemImage: "leaf.fill").font(.headline)
                ForEach(dayPractices) { practice in practiceLink(practice) }
                Text("Shown together as context, not evidence that an activity caused a feeling.").font(.caption).foregroundStyle(.secondary)
            }
        }.panel()
    }
    private var weekRecap: some View {
        let tagged = Dictionary(grouping: weekEntries.filter { $0.factor != "Nothing in particular" }, by: \.factor)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Your weekly recap").font(.system(.title2, design: .rounded, weight: .bold))
            Text("\(weekEntries.count) recorded \(weekEntries.count == 1 ? "check-in" : "check-ins")")
                .font(.subheadline).foregroundStyle(.secondary)
            if tagged.isEmpty {
                Text("Optional details like Sleep or Study will appear here when you tag a check-in.")
                    .font(.subheadline)
            }
            ForEach(tagged.keys.sorted(), id: \.self) { factor in
                let entries = tagged[factor] ?? []
                NavigationLink {
                    factorEntries(factor, entries: entries)
                } label: {
                    HStack {
                        Text("\(factor) appeared in \(entries.count) \(entries.count == 1 ? "check-in" : "check-ins")")
                        Spacer()
                        Image(systemName: "chevron.right").accessibilityHidden(true)
                    }.padding(.vertical, 8)
                }.accessibilityIdentifier("recap.factor.\(factor)")
            }
            Text("These counts describe the details you chose to record.").font(.caption).foregroundStyle(.secondary)
        }.panel()
    }

    private func factorEntries(_ factor: String, entries: [CheckIn]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(entries.reversed()) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        MoodEmblem(mood: entry.mood, size: 36)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(entry.mood).font(.headline)
                            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption).foregroundStyle(.secondary)
                            if !entry.note.isEmpty { Text(entry.note).font(.subheadline) }
                        }
                        Spacer()
                    }.panel()
                }
            }.page()
        }.background(Palette.cream).navigationTitle(factor).navigationBarTitleDisplayMode(.inline)
    }

    private var weekChart: some View {
        let categories = Array(Set(MoodLook.names + weekEntries.map(\.mood))).sorted()
        return VStack(alignment: .leading, spacing: 16) {
            Text("Feelings through the week").font(.system(.title2, design: .rounded, weight: .bold))
            Text("Each dot is one check-in. Feelings are categories, not scores.").font(.caption).foregroundStyle(.secondary)
            if weekEntries.isEmpty {
                ContentUnavailableView("Room for your moments", systemImage: "chart.dots.scatter", description: Text("Check-ins for this week will appear here. Nothing is filled in automatically."))
            } else {
                Chart {
                    ForEach(weekEntries) { entry in
                        PointMark(x: .value("Date", entry.date), y: .value("Feeling row", Double(categories.count - 1 - (categories.firstIndex(of: entry.mood) ?? 0))))
                            .foregroundStyle(MoodLook.color(entry.mood)).symbolSize(90)
                            .accessibilityLabel(entry.date.formatted()).accessibilityValue(entry.mood)
                    }
                }.chartXScale(domain: weekInterval.start...weekInterval.end)
                    .chartYScale(domain: (-0.5)...(Double(categories.count) - 0.5))
                    .chartXAxis { AxisMarks(values: weekDays) { _ in AxisGridLine(); AxisValueLabel(format: .dateTime.weekday(.narrow)) } }
                    .chartYAxis { AxisMarks(position: .leading, values: Array(categories.indices)) { tick in
                        AxisGridLine()
                        AxisValueLabel(anchor: .trailing) {
                            if let row = tick.as(Int.self), categories.indices.contains(row) { Text(categories[categories.count - 1 - row]) }
                        }
                    } }
                    .chartLegend(.hidden).chartXSelection(value: $chartDate)
                    .frame(height: 220).padding(.leading, 70).accessibilityIdentifier("mood.weekChart")
                Text("Touch and hold the chart to select a day. Use the calendar above for an entry-by-entry view.").font(.caption2).foregroundStyle(.secondary)
            }
        }.panel()
    }
    private var monthSummary: some View {
        let entries = monthEntries
        let groups = Dictionary(grouping: entries, by: \.mood)
        let days = Set(entries.map { calendar.startOfDay(for: $0.date) }).count
        return VStack(alignment: .leading, spacing: 16) {
            HStack { Text("A month of moments").font(.system(.title2, design: .rounded, weight: .bold)); Spacer(); Text(displayedMonth.formatted(.dateTime.month(.abbreviated))).font(.caption).foregroundStyle(.secondary) }
            Text("\(entries.count) check-ins across \(days) recorded day\(days == 1 ? "" : "s")").font(.subheadline).foregroundStyle(.secondary)
            if entries.isEmpty { Text("Your recorded feelings will appear here, without filling in days you haven’t logged.").font(.subheadline) }
            ForEach(groups.keys.sorted(), id: \.self) { mood in
                HStack(spacing: 10) {
                    MoodEmblem(mood: mood, size: 28)
                    Text(mood).font(.subheadline).frame(width: 76, alignment: .leading)
                    GeometryReader { geo in
                        Capsule().fill(MoodLook.color(mood).opacity(0.09))
                        Capsule().fill(MoodLook.color(mood).opacity(0.65)).frame(width: geo.size.width * Double(groups[mood]!.count) / Double(max(1, entries.count)))
                    }.frame(height: 9)
                    Text("\(groups[mood]!.count)").font(.subheadline.monospacedDigit()).frame(minWidth: 22, alignment: .trailing)
                }.accessibilityElement(children: .ignore).accessibilityLabel("\(mood), \(groups[mood]!.count) check-ins")
            }
            Text("Counts describe only what you recorded. They aren’t a wellbeing score, a diagnosis, or a daily target.").font(.caption2).foregroundStyle(.secondary)
        }.panel()
    }
    private func practiceLink(_ practice: Practice) -> some View {
        NavigationLink { ReflectionDetail(practiceID: practice.id) } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: Catalog.world(practice.worldID).symbol).foregroundStyle(Palette.green)
                VStack(alignment: .leading, spacing: 5) {
                    Text(Catalog.option(practice.optionID, worldID: practice.worldID).title).font(.subheadline.bold())
                    Text(practice.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                    Text(practice.reflection.isEmpty ? "Add a reflection" : practice.reflection).font(.caption).lineLimit(3)
                }
                Spacer(); Image(systemName: "chevron.right").font(.caption)
            }.padding(.vertical, 8)
        }.buttonStyle(.plain)
    }
    private var exportPanel: some View {
        DisclosureGroup("Export & privacy") {
            VStack(alignment: .leading, spacing: 14) {
                Text("Progress is shared by default. Include your private calendar entries and reflections only if you choose.").font(.subheadline)
                Toggle("Include moods and reflections", isOn: $includePrivate)
                ShareLink(item: includePrivate ? store.privateExport : store.progressExport) { Label("Export \(includePrivate ? "with private journal" : "progress only")", systemImage: "square.and.arrow.up") }.buttonStyle(.borderedProminent)
                Text("Saved on this device. No Apple Health connection or automatic mood detection. Device backups may include this data.").font(.caption).foregroundStyle(.secondary)
            }.padding(.top, 14)
        }.panel()
    }
    private var canMoveForward: Bool {
        if period == "Month" { return MoodCalendar.monthStart(displayedMonth) < MoodCalendar.monthStart(Date()) }
        return weekInterval.end <= calendar.startOfDay(for: Date())
    }
    private func movePeriod(_ direction: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            if period == "Month" {
                displayedMonth = calendar.date(byAdding: .month, value: direction, to: MoodCalendar.monthStart(displayedMonth))!
                selectedDate = calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month) ? Date() : displayedMonth
            } else {
                selectedDate = min(calendar.date(byAdding: .day, value: direction * 7, to: selectedDate)!, Date())
                displayedMonth = selectedDate
            }
            chartDate = nil
        }
    }
    private func goToToday() {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { selectedDate = Date(); displayedMonth = Date(); chartDate = nil }
    }
}

struct ReflectionDetail: View {
    let practiceID: UUID
    @Environment(WildStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let practice = store.state.practices.first(where: { $0.id == practiceID }) {
                    Eyebrow(text: "Your practice note")
                    Text(Catalog.option(practice.optionID, worldID: practice.worldID).title).font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text(practice.date.formatted()).foregroundStyle(.secondary)
                    ReflectionEditor(practiceID: practiceID) { dismiss() }
                    NavigationLink("Try this practice again") { ChallengeView(world: Catalog.world(practice.worldID)) }
                }
            }.page()
        }.background(Palette.cream).navigationTitle("Reflection").navigationBarTitleDisplayMode(.inline)
    }
}
