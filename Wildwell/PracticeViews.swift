import SwiftUI

struct ActivitiesView: View {
    @State private var savedOnly = false
    @Environment(WildStore.self) private var store
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Eyebrow(text: "A small invitation")
                Text("Make it real.").font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Return to something you’ve learned. Adapt it to the day you’re having.").foregroundStyle(.secondary)
                Toggle("Show saved favourites", isOn: $savedOnly).font(.subheadline)
                if savedOnly && store.preferences.favourites.isEmpty { Text("Save a world with its heart button. It will be easy to find here.").foregroundStyle(.secondary) }
                ForEach(Catalog.worlds.filter { !savedOnly || store.preferences.favourites.contains($0.id) }) { world in
                    VStack(alignment: .leading, spacing: 14) {
                        Label(world.dimension, systemImage: world.symbol).font(.caption.bold()).foregroundStyle(Palette.tint(world.id))
                        HStack { Text(world.name).font(.system(.title2, design: .rounded, weight: .bold)); Spacer(); Button { store.toggleFavourite(world.id) } label: { Image(systemName: store.preferences.favourites.contains(world.id) ? "heart.fill" : "heart").frame(width: 44, height: 44) }.accessibilityLabel("Save \(world.name) to favourites") }
                        ForEach(world.options) { option in
                            HStack { Text(option.title).font(.subheadline); Spacer(); if store.didPractise(option, in: world) { Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.green).accessibilityLabel("Practised") } }
                        }
                        Text("\(store.state.practices.filter { $0.worldID == world.id }.count) practices recorded • no daily target").font(.footnote).foregroundStyle(.secondary)
                        if store.state.learned.contains(world.id) {
                            NavigationLink { ChallengeView(world: world) } label: { Label(store.state.session?.worldID == world.id ? "Resume activity" : "Choose this practice", systemImage: "arrow.right") }.buttonStyle(.borderedProminent)
                        } else {
                            NavigationLink("Start with the lesson") { LessonView(world: world) }
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).panel()
                }
            }.page()
        }.background(Palette.cream).navigationTitle("Practise").navigationBarTitleDisplayMode(.inline)
    }
}
struct ChallengeView: View {
    let world: World
    var initialOptionID: String? = nil
    var quickMinutes: Int? = nil
    @Environment(WildStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var minutes = 5
    @State private var manualConfirmation = false
    @State private var cancelConfirmation = false
    @State private var practiceID: UUID?
    @State private var stage = 0
    @State private var alternate = false
    @State private var selectedOptionID = ""
    @State private var revealedReward: AnimalReward?
    private var option: PracticeOption { Catalog.option(store.state.session?.worldID == world.id ? store.state.session?.optionID : selectedOptionID, worldID: world.id) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if stage == 1 {
                    if let reward = revealedReward { RewardRevealView(reward: reward) { store.acknowledgeReward(reward.id); stage = 2 } }
                } else if stage == 2, let practiceID {
                    Text("A moment for you.").font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("You made a little room for yourself. Your practice is saved; reflection is entirely up to you.").foregroundStyle(.secondary)
                    ReflectionEditor(practiceID: practiceID) { dismiss() }
                } else {
                    Eyebrow(text: world.dimension)
                    if store.state.session?.worldID != world.id && quickMinutes == nil {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Choose what fits today").font(.headline)
                            ForEach(world.options) { choice in
                                Button { withAnimation { selectedOptionID = choice.id } } label: {
                                    HStack { Image(systemName: option.id == choice.id ? "largecircle.fill.circle" : "circle"); Text(choice.title).frame(maxWidth: .infinity, alignment: .leading); if store.didPractise(choice, in: world) { Image(systemName: "checkmark").accessibilityLabel("Practised before") } }.padding(14).background(option.id == choice.id ? Palette.sky(world.id) : .white, in: RoundedRectangle(cornerRadius: 16)).contentShape(RoundedRectangle(cornerRadius: 16))
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    Text(option.title).font(.system(.largeTitle, design: .rounded, weight: .bold)).accessibilityIdentifier("practice.title")
                    Text(alternate ? option.alternative : option.instructions).font(.title3).lineSpacing(5)
                    Toggle("Use the gentler alternative", isOn: $alternate).font(.subheadline).panel()
                        .onChange(of: alternate) { _, value in if store.state.session?.worldID == world.id { store.setSessionGentler(value) } }
                    Label("Complete this practice to meet a random \(world.name) character.", systemImage: "sparkles").font(.subheadline).foregroundStyle(Palette.green)
                    if let session = store.state.session, session.worldID != world.id {
                        Text("You already have an activity in progress. You can return to it, or end it before starting this one.").panel()
                        NavigationLink("Return to active practice") { ChallengeView(world: Catalog.world(session.worldID)) }
                        Button("End the previous activity", role: .destructive) { cancelConfirmation = true }
                    } else if let session = store.state.session {
                        TimelineView(.periodic(from: .now, by: 1)) { timeline in
                            let elapsed = session.elapsed(at: timeline.date)
                            let remaining = max(0, Int(ceil(session.target - elapsed)))
                            VStack(spacing: 18) {
                                ZStack {
                                    Circle().stroke(Palette.sky(world.id), lineWidth: 14)
                                    Circle().trim(from: 0, to: elapsed / session.target).stroke(Palette.tint(world.id), style: StrokeStyle(lineWidth: 14, lineCap: .round)).rotationEffect(.degrees(-90))
                                    VStack(spacing: 6) {
                                        Text(String(format: "%02d:%02d", remaining / 60, remaining % 60)).font(.system(size: 48, weight: .bold, design: .rounded)).monospacedDigit().contentTransition(.numericText())
                                        Text(remaining == 0 ? "Ready when you are" : session.startedAt == nil ? "At your pace" : "Time for your practice").font(.caption)
                                    }
                                }.frame(width: 235, height: 235).frame(maxWidth: .infinity).padding(16)
                                if remaining > 0 {
                                    PrimaryButton(title: session.startedAt == nil ? "Start / resume timer" : "Pause timer", symbol: session.startedAt == nil ? "play.fill" : "pause.fill") { store.toggleTimer() }
                                } else {
                                    PrimaryButton(title: "Finish practice", symbol: "checkmark") { finish(manual: false) }
                                }
                            }
                        }
                        Button("I completed it without the timer") { manualConfirmation = true }.frame(maxWidth: .infinity)
                        Text("The timer is optional, not proof of activity. It continues while the app is closed; pause it whenever you need.").font(.footnote).foregroundStyle(.secondary)
                        Button("End this activity for now", role: .destructive) { cancelConfirmation = true }.frame(maxWidth: .infinity)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            if quickMinutes == nil {
                                Text("Choose a comfortable length").font(.headline)
                                Picker("Practice length", selection: $minutes) {
                                    ForEach([1, 3, 5, 10], id: \.self) { Text("\($0) min").tag($0) }
                                }.pickerStyle(.segmented)
                            } else {
                                Label("\(minutes)-minute practice", systemImage: "clock").font(.headline)
                            }
                            PrimaryButton(title: "Prepare my practice", symbol: "leaf") { store.begin(world, minutes: minutes, optionID: option.id, gentler: alternate, quickStart: quickMinutes != nil) }
                            Text("You can pause, finish manually, or come back later. No progress is lost by taking a break.").font(.footnote).foregroundStyle(.secondary)
                        }.panel()
                    }
                }
            }.page()
        }.background(Palette.cream).navigationTitle(stage == 0 ? "Your practice" : "Well explored").navigationBarTitleDisplayMode(.inline)
            .onAppear {
                minutes = quickMinutes ?? store.preferences.minutes
                if let session = store.state.session, session.worldID == world.id { selectedOptionID = session.optionID ?? world.options[0].id; alternate = session.gentler ?? false }
                else { selectedOptionID = initialOptionID ?? store.suggestedOption(in: world).id; alternate = store.preferences.gentler }
            }
            .confirmationDialog("Record this practice as completed?", isPresented: $manualConfirmation, titleVisibility: .visible) {
                Button("Yes, record my practice") { finish(manual: true) }
            } message: { Text("This records a self-reported completion. Choosing an alternative counts equally.") }
            .confirmationDialog("End the active activity?", isPresented: $cancelConfirmation, titleVisibility: .visible) {
                Button("End activity", role: .destructive) { store.cancelSession() }
            } message: { Text("This clears its timer. Your lessons, discoveries, and earlier practices stay safe.") }
    }
    private func finish(manual: Bool) {
        guard let id = store.complete(world, manual: manual) else { return }
        practiceID = id
        let rewardID = store.state.practices.first(where: { $0.id == id })?.rewardID
        revealedReward = store.rewards.first { $0.id == rewardID }
        withAnimation { stage = revealedReward == nil ? 2 : 1 }
    }
}
struct RewardRevealView: View {
    let reward: AnimalReward
    let done: () -> Void
    @Environment(WildStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var taps = 0
    @State private var revealed = false
    private var species: Species { Catalog.species(reward.speciesID)! }
    private var copyCount: Int { store.rewards.filter { $0.variantID == reward.variantID }.count }
    var body: some View {
        VStack(spacing: 20) {
            Eyebrow(text: Catalog.home(of: species).name + " • a wild arrival")
            Text(revealed ? "Look who found you." : reward.rarity.revealHint).font(.system(.title, design: .rounded, weight: .bold)).multilineTextAlignment(.center)
            RarityBadge(rarity: reward.rarity)
            ZStack {
                if revealed {
                    CharacterPortrait(species: species, rarity: reward.rarity, backdrop: reward.backdrop).transition(.scale(scale: 0.85).combined(with: .opacity))
                } else {
                    Button(action: tapStar) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 28).fill(reward.rarity.color.opacity(0.06))
                            Circle().fill(RadialGradient(colors: [reward.rarity.color.opacity(0.24), reward.rarity.color.opacity(0.02)], center: .center, startRadius: 5, endRadius: 110)).frame(width: 210, height: 210)
                            if reward.rarity == .myth {
                                ForEach(0..<3) { ring in Circle().stroke(reward.rarity.color.opacity(0.15 + Double(ring) * 0.06), lineWidth: 2).frame(width: CGFloat(140 + ring * 28), height: CGFloat(140 + ring * 28)).scaleEffect(taps == 0 ? 0.85 : 1 + Double(taps) * 0.04) }
                            }
                            Image(systemName: reward.rarity.symbol).font(.system(size: 68, weight: .semibold)).foregroundStyle(reward.rarity.color).rotationEffect(.degrees(reduceMotion ? 0 : Double(taps * (reward.rarity == .rare ? 6 : 18)))).scaleEffect(taps.isMultiple(of: 2) ? 1 : 1.15)
                            VStack { Spacer(); Text("Tap the star • \(taps)/\(reward.rarity.revealTaps)").font(.system(.subheadline, design: .rounded, weight: .semibold)).foregroundStyle(reward.rarity.color).padding(.bottom, 20) }
                        }
                    }.buttonStyle(.plain).accessibilityIdentifier("reward.open")
                        .accessibilityLabel("Reveal \(reward.rarity.title) character")
                        .accessibilityValue("\(taps) of \(reward.rarity.revealTaps) taps")
                }
                RarityStars(rarity: reward.rarity, pulse: reduceMotion ? 0 : taps, revealed: revealed)
            }.frame(height: 260)
            if revealed {
                HStack {
                    Text(species.name).font(.system(.title, design: .rounded, weight: .bold)).accessibilityIdentifier("reward.species")
                    CardShareButton(reward: reward, species: species)
                }
                Label(reward.sizeLabel(for: species), systemImage: "ruler")
                    .font(.subheadline)
                Text("Illustrative card size").font(.caption).foregroundStyle(.secondary)
                Text(copyCount > 1 ? "Copy \(copyCount) of this \(reward.rarity.title) character. Every arrival is kept." : "A new character variant for your collection.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Text(species.fact).font(.subheadline).multilineTextAlignment(.center)
                PrimaryButton(title: "Continue", symbol: "checkmark", action: done)
            } else {
                Text(reward.rarity == .rare ? "One gentle tap sends blue stars bouncing." : reward.rarity == .epic ? "Two gentle taps wake a purple star spiral." : "Three gentle taps bloom into red and gold stars.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button("Reveal without animation") { openImmediately() }.font(.subheadline).accessibilityIdentifier("reward.skipAnimation")
            }
            Label("Already saved to your collection", systemImage: "checkmark.seal.fill").font(.caption).foregroundStyle(Palette.green)
        }.padding(.vertical, 24).sensoryFeedback(.impact(weight: reward.rarity == .myth ? .heavy : .light), trigger: taps)
    }
    private func tapStar() {
        guard !revealed else { return }
        let damping: Double = reward.rarity == .rare ? 0.62 : reward.rarity == .epic ? 0.48 : 0.38
        withAnimation(reduceMotion ? nil : .spring(response: reward.rarity == .myth ? 0.85 : 0.65, dampingFraction: damping)) {
            taps += 1
            if taps >= reward.rarity.revealTaps { revealed = true }
        }
    }
    private func openImmediately() { taps = reward.rarity.revealTaps; revealed = true }
}
struct RarityStars: View {
    let rarity: CharacterRarity
    let pulse: Int
    let revealed: Bool
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<rarity.starCount, id: \.self) { index in
                let angle = Double(index) * .pi * 2 / Double(rarity.starCount) + Double(pulse) * (rarity == .epic ? 0.45 : 0.12)
                let radius = (revealed ? 0.45 : 0.25 + Double(pulse) * 0.035) * min(geo.size.width, geo.size.height)
                Image(systemName: index.isMultiple(of: 3) ? "sparkle" : "star.fill")
                    .font(.system(size: CGFloat(10 + index % 4 * 4), weight: .bold))
                    .foregroundStyle(starColor(index))
                    .rotationEffect(.degrees(Double(pulse * 45 + index * 20)))
                    .scaleEffect(pulse.isMultiple(of: 2) ? 0.75 : 1.25)
                    .position(x: geo.size.width / 2 + cos(angle) * radius, y: geo.size.height / 2 + sin(angle) * radius * (rarity == .myth ? 0.9 : 0.75))
                    .opacity(revealed ? 0.35 : 0.85)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
    private func starColor(_ index: Int) -> Color {
        if rarity == .myth && index.isMultiple(of: 3) { return .orange }
        if rarity == .epic && index.isMultiple(of: 2) { return Color(red: 0.78, green: 0.52, blue: 0.94) }
        if rarity == .rare && index.isMultiple(of: 2) { return .cyan }
        return rarity.color
    }
}

struct ReflectionEditor: View {
    let practiceID: UUID
    let done: () -> Void
    @Environment(WildStore.self) private var store
    @State private var note = ""
    @State private var helpful = "Not sure"
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What’s worth keeping?").font(.title2.bold())
            if let practice = store.state.practices.first(where: { $0.id == practiceID }) { Text(Catalog.option(practice.optionID, worldID: practice.worldID).prompt).font(.subheadline).foregroundStyle(Palette.green) }
            Text("Optional. An activity does not have to change your mood to count.").foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(["I noticed…", "Next time I might…", "This didn’t fit today because…"], id: \.self) { prompt in Button(prompt) { note = note.isEmpty ? prompt + " " : note + "\n" + prompt + " " }.font(.caption).buttonStyle(.bordered) } } }
            TextField("A thought to keep…", text: $note, axis: .vertical).lineLimit(4...8).padding().background(.white, in: RoundedRectangle(cornerRadius: 18))
            Text("Did this feel useful today?").font(.headline)
            Picker("Helpfulness", selection: $helpful) { ForEach(["Yes", "Not sure", "Not today"], id: \.self) { Text($0) } }.pickerStyle(.segmented)
            PrimaryButton(title: "Save reflection", symbol: "book.closed") { store.reflect(practiceID, text: note.trimmingCharacters(in: .whitespacesAndNewlines), helpful: helpful); done() }
            Button("Skip for now", action: done).frame(maxWidth: .infinity)
            Text("You can add or edit this later in Mood.").font(.footnote).foregroundStyle(.secondary)
        }.onAppear {
            if let p = store.state.practices.first(where: { $0.id == practiceID }) { note = p.reflection; helpful = p.helpful == "Not recorded" ? "Not sure" : p.helpful }
        }
    }
}
