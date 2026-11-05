import SwiftUI

@main struct WildwellApp: App {
    @State private var store: WildStore
    init() {
        var testFile: URL?
        var draw: (Int) -> RewardDraw = RewardDraw.random
        #if DEBUG
        if let value = ProcessInfo.processInfo.environment["WILDWELL_TEST_ID"], let id = UUID(uuidString: value) {
            testFile = URL.documentsDirectory.appending(path: "wildwell-ui-test-\(id.uuidString).json")
            if let value = ProcessInfo.processInfo.environment["WILDWELL_TEST_REVEAL"], let rarity = CharacterRarity(rawValue: value), let file = testFile {
                draw = { _ in RewardDraw(speciesIndex: 0, rarityRoll: rarity == .rare ? 0 : rarity == .epic ? 70 : 95) }
                if !FileManager.default.fileExists(atPath: file.path) {
                    var fixture = SavedState(); fixture.welcomed = true; fixture.learned = ["forest"]
                    if let data = try? JSONEncoder().encode(fixture) { try? data.write(to: file, options: .atomic) }
                }
            }
        }
        #endif
        _store = State(initialValue: WildStore(file: testFile, drawReward: draw))
    }
    var body: some Scene {
        WindowGroup { RootView().environment(store).tint(Palette.green).preferredColorScheme(.light) }
    }
}

struct PrimaryButton: View {
    let title: String
    var symbol: String = "arrow.right"
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Text(title); Spacer(); Image(systemName: symbol) }
                .font(.system(.headline, design: .rounded)).padding(18)
                .foregroundStyle(.white).background(Palette.green, in: RoundedRectangle(cornerRadius: 20))
        }.buttonStyle(.plain)
    }
}
extension View {
    func panel() -> some View {
        padding(20).background(.white, in: RoundedRectangle(cornerRadius: 24)).overlay(RoundedRectangle(cornerRadius: 24).stroke(Palette.ink.opacity(0.07)))
    }
    func page() -> some View { frame(maxWidth: 680).padding(20).frame(maxWidth: .infinity) }
}
struct Eyebrow: View {
    let text: String
    var body: some View { Text(text.uppercased()).font(.system(.caption, design: .rounded, weight: .bold)).tracking(2).foregroundStyle(Palette.green) }
}
struct RootView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(WildStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var onboarding = false
    @State private var dailyCheckIn = false
    var body: some View {
        TabView {
            NavigationStack { ExploreView() }.tabItem { Label("Today", systemImage: "sun.max.fill") }
            NavigationStack { ActivitiesView() }.tabItem { Label("Practise", systemImage: "figure.walk") }
            NavigationStack { CabinetView() }.tabItem { Label("Collection", systemImage: "square.grid.2x2.fill") }
            NavigationStack { JourneyView() }.tabItem { Label("Mood", systemImage: "calendar") }
        }.foregroundStyle(Palette.ink)
            .transaction { if reduceMotion { $0.animation = nil } }
            .sheet(isPresented: $onboarding, onDismiss: offerDailyCheckIn) { WelcomeView { store.welcome(); onboarding = false }.interactiveDismissDisabled() }
            .sheet(isPresented: $dailyCheckIn) { CheckInView(daily: true) }
            .task {
                onboarding = !store.state.welcomed
                offerDailyCheckIn()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { offerDailyCheckIn() }
            }
            .alert("Local storage needs attention", isPresented: Binding(get: { store.storageError != nil }, set: { _ in })) {
                Button("Retry saving") { store.retrySave() }
            } message: { Text(store.storageError ?? "") }
    }
    private func offerDailyCheckIn() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["WILDWELL_SKIP_DAILY_PROMPT"] == "1" { return }
        #endif
        guard store.state.welcomed, !onboarding, !dailyCheckIn else { return }
        dailyCheckIn = store.shouldOfferDailyCheckIn()
    }
}
struct WelcomeView: View {
    let done: () -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HabitatArt(world: Catalog.worlds[0]).frame(height: 290).clipShape(RoundedRectangle(cornerRadius: 32))
                Eyebrow(text: "Welcome to Wildwell")
                Text("A little care.\nA wild discovery.").font(.system(size: 38, weight: .bold, design: .rounded))
                Text("Explore wellbeing through small lessons and real-life practice. Meet remarkable animals along the way.").font(.title3)
                Label("Go at your own pace. Your progress stays.", systemImage: "leaf")
                Label("Check-ins are optional. Every feeling is welcome.", systemImage: "heart")
                Label("Stored on this device. No account or tracking.", systemImage: "lock")
                Text("Wildwell is a learning companion, not clinical care. Choose activities that feel safe and accessible to you.").font(.footnote).foregroundStyle(.secondary)
            }.page()
        }.background(Palette.cream)
            .safeAreaInset(edge: .bottom) { PrimaryButton(title: "Let’s explore", action: done).padding(20).background(Palette.cream) }
    }
}
struct ExploreView: View {
    @Environment(WildStore.self) private var store
    @State private var checkIn = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Eyebrow(text: "Wildwell")
                    Spacer()
                    Button { checkIn = true } label: { Label("Check in", systemImage: "heart.text.clipboard").font(.subheadline.bold()).frame(minHeight: 44) }.accessibilityIdentifier("today.checkIn")
                }
                Text("A moment for you.").font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("One small practice can be enough for today.").foregroundStyle(.secondary)
                if let session = store.state.session {
                    NavigationLink { ChallengeView(world: Catalog.world(session.worldID)) } label: {
                        HStack(spacing: 14) { Image(systemName: "play.circle.fill").font(.largeTitle); VStack(alignment: .leading, spacing: 5) { Text("Pick up where you left off").bold(); Text(Catalog.option(session.optionID, worldID: session.worldID).title).font(.subheadline) }; Spacer(); Image(systemName: "chevron.right") }.panel()
                    }.buttonStyle(.plain)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("How much time do you have?").font(.headline)
                    Picker("Available time", selection: Binding(get: { todayMinutes }, set: { store.setMinutes($0) })) {
                        ForEach([1, 3, 5], id: \.self) { Text("\($0) min").tag($0) }
                    }.pickerStyle(.segmented).accessibilityIdentifier("today.duration")
                    suggestedCard
                }
                VStack(alignment: .leading, spacing: 18) {
                    Text("What would help right now?").font(.system(.title2, design: .rounded, weight: .bold))
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        intention("forest", "Move a little", "figure.walk")
                        intention("ocean", "Find some focus", "water.waves")
                        intention("woodland", "Feel connected", "heart")
                        intention("wetland", "Make space", "sun.haze")
                    }
                    Toggle("Keep it extra gentle", isOn: Binding(get: { store.preferences.gentler }, set: { store.setGentler($0) })).font(.subheadline)
                    Text("We’ll remember your choices. Change them any time.").font(.caption).foregroundStyle(.secondary)
                }.panel()
                if !store.usefulWorlds.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Worth another visit").font(.headline)
                        Text("You marked a practice in these worlds as useful. That’s your experience, not a prediction.").font(.caption).foregroundStyle(.secondary)
                        ForEach(store.usefulWorlds) { world in NavigationLink { ChallengeView(world: world) } label: { Label(world.name, systemImage: world.symbol) }.padding(.vertical, 5) }
                    }.panel()
                }
                HStack { Text("Choose your world").font(.system(.title2, design: .rounded, weight: .bold)); Spacer(); Text("4 trails").font(.caption).foregroundStyle(.secondary) }
                ForEach(Catalog.worlds) { world in
                    NavigationLink { WorldView(world: world) } label: { WorldCard(world: world) }.buttonStyle(.plain)
                }
                Text("Come back whenever it suits you. No catching up needed.").font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }.page().padding(.bottom, 24)
        }.background(Palette.cream).toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $checkIn) { CheckInView() }

    }
    private func intention(_ id: String, _ title: String, _ symbol: String) -> some View {
        Button { withAnimation { store.setIntention(id) } } label: {
            VStack(alignment: .leading, spacing: 10) { Image(systemName: symbol).font(.title2); Text(title).font(.system(.subheadline, design: .rounded, weight: .semibold)) }.frame(maxWidth: .infinity, minHeight: 65, alignment: .leading).padding(14).background(store.preferences.intention == id ? Palette.sky(id) : Palette.cream, in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(store.preferences.intention == id ? Palette.tint(id) : .clear, lineWidth: 2))
        }.buttonStyle(.plain).accessibilityAddTraits(store.preferences.intention == id ? .isSelected : [])
    }
    private var todayMinutes: Int { min(store.preferences.minutes, 5) }

    private var suggestedCard: some View {
        let world = store.suggestedWorld
        let option = store.quickOption(in: world, minutes: todayMinutes)
        return VStack(alignment: .leading, spacing: 16) {
            HStack { Eyebrow(text: "A \(todayMinutes)-minute idea"); Spacer(); Image(systemName: world.symbol) }
            Text(option.title).font(.system(.title2, design: .rounded, weight: .bold))
            Text(store.preferences.gentler ? option.alternative : option.instructions).font(.subheadline)
            NavigationLink {
                ChallengeView(world: world, initialOptionID: option.id, quickMinutes: todayMinutes)
            } label: {
                Label("Try this practice", systemImage: "arrow.right").frame(maxWidth: .infinity).padding(10)
            }.buttonStyle(.borderedProminent).accessibilityIdentifier("today.tryPractice")
        }.panel()
    }
}
struct WorldCard: View {
    let world: World
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: world.symbol).font(.title2).foregroundStyle(Palette.tint(world.id)).frame(width: 46, height: 46).background(Palette.sky(world.id).opacity(0.5), in: RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 7) {
                Text(world.name).font(.system(.headline, design: .rounded))
                Text(world.dimension).font(.caption).foregroundStyle(Palette.tint(world.id))
                Text(world.subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0); Image(systemName: "chevron.right").font(.caption).padding(.top, 15)
        }.panel()
    }
}
struct WorldView: View {
    let world: World
    @Environment(WildStore.self) private var store
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HabitatArt(world: world).frame(height: 250).clipShape(RoundedRectangle(cornerRadius: 28))
                Eyebrow(text: world.dimension)
                Text(world.name).font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text(world.subtitle).font(.title3).foregroundStyle(.secondary)
                Button { store.toggleFavourite(world.id) } label: { Label(store.preferences.favourites.contains(world.id) ? "Saved to your favourites" : "Save this world", systemImage: store.preferences.favourites.contains(world.id) ? "heart.fill" : "heart") }.buttonStyle(.bordered)
                VStack(alignment: .leading, spacing: 18) {
                    Label("01 • Learn", systemImage: store.state.learned.contains(world.id) ? "checkmark.circle.fill" : "book.fill").font(.headline)
                    Text(world.lesson).font(.title3.bold())
                    NavigationLink { LessonView(world: world) } label: { Label(store.state.learned.contains(world.id) ? "Revisit lesson" : store.lessonDraft(for: world).step > 0 ? "Resume guide" : "Open bite-size lesson", systemImage: "arrow.right") }.buttonStyle(.borderedProminent)
                }.frame(maxWidth: .infinity, alignment: .leading).panel()
                VStack(alignment: .leading, spacing: 18) {
                    Label("02 • Practise", systemImage: "figure.walk").font(.headline)
                    Text("Three ways to make it yours").font(.title3.bold())
                    Text("Choose from three practical ideas, each with a gentler alternative. Every completed practice, including repeats, welcomes a random \(world.name) animal character to your collection.").foregroundStyle(.secondary)
                    if store.state.learned.contains(world.id) {
                        NavigationLink { ChallengeView(world: world) } label: { Label("Choose your practice", systemImage: "arrow.right") }.buttonStyle(.borderedProminent)
                    } else { Text("Finish the lesson to open this practice.").font(.footnote) }
                }.frame(maxWidth: .infinity, alignment: .leading).panel()
                Label("03 • Receive a random character from this world, then reflect if you like.", systemImage: "sparkles").font(.subheadline)
                DisclosureGroup("Animals in this study world") {
                    VStack(alignment: .leading, spacing: 10) { ForEach(world.speciesPool) { species in Label(species.name, systemImage: "pawprint").font(.subheadline) }; Text("Each is equally likely. Rarity is independent: Rare 70%, Epic 25%, Myth 5%.").font(.caption).foregroundStyle(.secondary) }.padding(.top, 12)
                }.panel()
                Text("World themes are creative learning maps. They are not scientific habitat classifications; species cards describe actual habitats.").font(.footnote).foregroundStyle(.secondary)
            }.page()
        }.background(Palette.cream).navigationTitle("Your trail").navigationBarTitleDisplayMode(.inline)
    }
}
struct LessonView: View {
    let world: World
    @Environment(WildStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0
    @State private var answer: Int?
    @State private var chosenOptionID = ""
    @State private var restored = false
    private let stages = ["Notice", "Explore", "Make a plan", "Check your idea", "Ready to try"]
    private var chosen: PracticeOption { Catalog.option(chosenOptionID, worldID: world.id) }
    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Color.clear.frame(height: 0).id("lesson.top")
                    HStack { Label(world.name, systemImage: world.symbol).font(.caption.bold()).foregroundStyle(Palette.tint(world.id)); Spacer(); Text("\(step + 1) of 5").font(.caption.monospacedDigit()).foregroundStyle(.secondary) }
                    HStack(spacing: 7) { ForEach(0..<5, id: \.self) { index in Capsule().fill(index <= step ? Palette.tint(world.id) : Palette.tint(world.id).opacity(0.12)).frame(height: 5) } }.accessibilityLabel("Lesson step \(step + 1) of 5")
                    Eyebrow(text: stages[step])
                    Text(headline).font(.system(.largeTitle, design: .rounded, weight: .bold)).fixedSize(horizontal: false, vertical: true)
                    lessonContent
                    if step < 4 { Text("Your place is saved. Leave whenever you need and come back to this step.").font(.caption).foregroundStyle(.secondary) }
                }.page().padding(.bottom, 12)
            }.background(Palette.cream)
                .safeAreaInset(edge: .bottom) { lessonControls.padding(.horizontal, 20).padding(.vertical, 12).frame(maxWidth: 680).frame(maxWidth: .infinity).background(Palette.cream) }
                .onChange(of: step) { _, _ in reader.scrollTo("lesson.top", anchor: .top) }
        }.navigationTitle(world.dimension).navigationBarTitleDisplayMode(.inline)
            .onAppear {
                guard !restored else { return }
                let draft = store.lessonDraft(for: world)
                step = draft.step; chosenOptionID = draft.optionID; answer = draft.answer; restored = true
            }
    }
    private var headline: String {
        switch step {
        case 0: world.lesson
        case 1: "What fits your real day?"
        case 2: "Keep your next step small."
        case 3: "A moment to make sense of it."
        default: "You’ve got a small next step."
        }
    }
    @ViewBuilder private var lessonContent: some View {
        switch step {
        case 0:
            ZStack {
                RoundedRectangle(cornerRadius: 28).fill(Palette.sky(world.id))
                HStack(spacing: 22) { Image(systemName: world.symbol).font(.system(size: 54)).foregroundStyle(Palette.tint(world.id)); VStack(alignment: .leading, spacing: 7) { Text("One idea. Your own pace.").font(.system(.headline, design: .rounded)); Text("Read → choose → try").font(.subheadline).foregroundStyle(.secondary) } }
            }.frame(height: 145).accessibilityHidden(true)
            Text(world.paragraphs[0]).font(.title3).lineSpacing(6)
            Text("By the end, you’ll have chosen a manageable way to try this idea in your own life.").font(.subheadline).panel()
        case 1:
            Text("Choose one small action to explore. You can change your mind later.").font(.subheadline).foregroundStyle(.secondary)
            VStack(spacing: 10) {
                ForEach(world.options) { option in
                    Button {
                        chosenOptionID = option.id
                        store.saveLessonDraft(LessonDraft(step: step, optionID: option.id, answer: answer), for: world)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: chosen.id == option.id ? "checkmark.circle.fill" : "circle")
                            Text(option.title).font(.system(.headline, design: .rounded)).frame(maxWidth: .infinity, alignment: .leading)
                        }.padding(18).background(chosen.id == option.id ? Palette.sky(world.id).opacity(0.55) : .white, in: RoundedRectangle(cornerRadius: 20)).contentShape(RoundedRectangle(cornerRadius: 20))
                    }.buttonStyle(.plain).accessibilityAddTraits(chosen.id == option.id ? .isSelected : []).accessibilityIdentifier("lesson.example.\(option.id)")
                }
            }
            VStack(alignment: .leading, spacing: 14) {
                Label("Picture it in your day", systemImage: world.symbol).font(.headline).foregroundStyle(Palette.tint(world.id))
                Text(chosen.instructions).font(.subheadline).lineSpacing(4)
                Label(chosen.alternative, systemImage: "leaf").font(.caption).foregroundStyle(.secondary)
            }.panel()
            Text(world.paragraphs[1]).font(.subheadline).lineSpacing(4).foregroundStyle(.secondary)
        case 2:
            Text(world.paragraphs[2]).font(.title3).lineSpacing(5)
            VStack(alignment: .leading, spacing: 16) {
                Label("Your practice plan", systemImage: "leaf.fill").font(.headline).foregroundStyle(Palette.tint(world.id))
                Text(chosen.title).font(.system(.title2, design: .rounded, weight: .bold)).accessibilityIdentifier("lesson.plannedPractice")
                Text(store.preferences.gentler ? chosen.alternative : chosen.instructions).font(.subheadline)
                Picker("Time for your plan", selection: Binding(get: { store.preferences.minutes }, set: { store.setMinutes($0) })) { ForEach([1, 3, 5, 10], id: \.self) { Text("\($0) min").tag($0) } }.pickerStyle(.segmented)
                Toggle("Use the gentler version", isOn: Binding(get: { store.preferences.gentler }, set: { store.setGentler($0) })).font(.subheadline)
                Button("Choose a different example") { go(to: 1) }.font(.subheadline)
            }.panel()
            Text("This is a plan, not a commitment. You can adapt or stop when you try it.").font(.caption).foregroundStyle(.secondary)
        case 3:
            Text(world.question).font(.title2.bold())
            Text("No score and no penalty. Choose an answer, then see the reasoning.").font(.subheadline).foregroundStyle(.secondary)
            ForEach(world.answers.indices, id: \.self) { index in
                Button { answer = index; savePlace() } label: {
                    HStack(alignment: .top, spacing: 12) { Image(systemName: answer == index ? "largecircle.fill.circle" : "circle"); Text(world.answers[index]).frame(maxWidth: .infinity, alignment: .leading) }.padding(18).background(answer == index ? Palette.sky(world.id).opacity(0.55) : .white, in: RoundedRectangle(cornerRadius: 20))
                }.buttonStyle(.plain).accessibilityAddTraits(answer == index ? .isSelected : [])
            }
            if let answer {
                VStack(alignment: .leading, spacing: 8) {
                    Label(answer == world.correct ? "That’s the idea" : "Try a gentler approach", systemImage: answer == world.correct ? "lightbulb.fill" : "arrow.triangle.turn.up.right.diamond").font(.headline)
                    Text(answer == world.correct ? world.explanation : "Consider an answer that leaves room for choice and comfort. Revisit an example if you like, then try another answer.").font(.subheadline).lineSpacing(4)
                }.frame(maxWidth: .infinity, alignment: .leading).panel().accessibilityIdentifier("lesson.feedback")
            }
        default:
            Label("Guide completed", systemImage: "checkmark.seal.fill").font(.headline).foregroundStyle(Palette.green)
            Text(world.explanation).font(.title3).lineSpacing(5)
            VStack(alignment: .leading, spacing: 14) {
                Text("Your next step").font(.caption.bold()).foregroundStyle(.secondary)
                Text(chosen.title).font(.system(.title2, design: .rounded, weight: .bold)).accessibilityIdentifier("lesson.plannedPractice")
                Label("\(store.preferences.minutes) minutes • \(store.preferences.gentler ? "gentler version" : "your own pace")", systemImage: "clock").font(.subheadline)
                Text("After your practice, a random \(world.name) animal arrives in Rare, Epic or Myth rarity.").font(.subheadline).foregroundStyle(.secondary)
            }.panel()
            Text("Learning is complete. You can try the activity now, or return to Practise later.").font(.caption).foregroundStyle(.secondary)
        }
    }
    private var lessonControls: some View {
        VStack(spacing: 8) {
            if step == 4 {
                NavigationLink { ChallengeView(world: world, initialOptionID: chosen.id) } label: { HStack { Text("Put it into practice"); Spacer(); Image(systemName: "arrow.right") }.font(.headline).padding(18).foregroundStyle(.white).background(Palette.green, in: RoundedRectangle(cornerRadius: 20)) }.buttonStyle(.plain)
                Button("Review this guide") { go(to: 0) }.font(.caption).padding(5)
            } else {
                PrimaryButton(title: step == 3 ? (answer == world.correct ? "Finish lesson" : "Choose an answer above") : "Continue") {
                    if step == 3 { guard answer == world.correct else { return }; store.learn(world.id) }
                    go(to: step + 1)
                }.disabled(step == 3 && answer != world.correct).opacity(step == 3 && answer != world.correct ? 0.45 : 1)
                if step > 0 { Button("Back a step") { go(to: step - 1) }.font(.caption).padding(5) }
            }
        }
    }
    private func go(to next: Int) {
        step = next
        savePlace()
    }
    private func savePlace() { store.saveLessonDraft(LessonDraft(step: step, optionID: chosen.id, answer: answer), for: world) }
}
