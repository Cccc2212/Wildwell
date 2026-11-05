import Foundation
import Observation

@MainActor @Observable final class WildStore {
    private(set) var state: SavedState
    var storageError: String?
    private let file: URL
    private let drawReward: (Int) -> RewardDraw
    private var needsRecoveryCopy = false
    init(file: URL? = nil, drawReward: @escaping (Int) -> RewardDraw = RewardDraw.random) {
        self.drawReward = drawReward
        self.file = file ?? URL.documentsDirectory.appending(path: "wildwell-v1.json")
        do {
            let data = try Data(contentsOf: self.file)
            state = try JSONDecoder().decode(SavedState.self, from: data)
        } catch {
            state = SavedState()
            if FileManager.default.fileExists(atPath: self.file.path) {
                needsRecoveryCopy = true
                storageError = "Your saved file could not be read. Retry will preserve a recovery copy and start a fresh journal."
            }
        }
        if storageError == nil, state.rewards == nil {
            // Upgrade old discoveries once, preserving dates and interrupted reveals.
            let migrated = state.discoveries.sorted { $0.key < $1.key }.compactMap { id, date -> AnimalReward? in
                guard Catalog.species(id) != nil else { return nil }
                return AnimalReward(speciesID: id, rarity: .rare, date: date, practiceID: nil)
            }
            state.rewards = migrated
            let oldPending = [state.pendingSpecies].compactMap { $0 } + (state.pendingQueue ?? [])
            state.pendingRewardIDs = oldPending.compactMap { speciesID in migrated.first { $0.speciesID == speciesID }?.id }
            state.pendingSpecies = nil; state.pendingQueue = nil
            save()
        }
    }
    private func save() {
        guard storageError == nil else { return }
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: file, options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch { storageError = "Changes could not be saved. Keep the app open, free some device storage, then retry." }
    }
    func retrySave() {
        if needsRecoveryCopy {
            do {
                let backup = file.deletingLastPathComponent().appendingPathComponent("wildwell-recovery-\(UUID()).json")
                try FileManager.default.copyItem(at: file, to: backup)
                needsRecoveryCopy = false
            } catch {
                storageError = "A recovery copy could not be created. Your original file has not been changed. Free some storage and retry."
                return
            }
        }
        storageError = nil; save()
    }
    func welcome() { state.welcomed = true; save() }
    func learn(_ id: String) { state.learned.insert(id); save() }
    func lessonDraft(for world: World) -> LessonDraft {
        guard let draft = state.lessonDrafts?[world.id], (0...4).contains(draft.step),
              world.options.contains(where: { $0.id == draft.optionID }),
              draft.answer == nil || world.answers.indices.contains(draft.answer!),
              draft.step < 4 || state.learned.contains(world.id) else { return LessonDraft(optionID: world.options[0].id) }
        return draft
    }
    func saveLessonDraft(_ draft: LessonDraft, for world: World) {
        guard (0...4).contains(draft.step), world.options.contains(where: { $0.id == draft.optionID }),
              draft.answer == nil || world.answers.indices.contains(draft.answer!),
              draft.step < 4 || state.learned.contains(world.id) else { return }
        var drafts = state.lessonDrafts ?? [:]; drafts[world.id] = draft; state.lessonDrafts = drafts; save()
    }
    var preferences: Preferences { state.preferences ?? Preferences() }
    func setMinutes(_ value: Int) { var p = preferences; p.minutes = [1, 3, 5, 10].contains(value) ? value : 3; state.preferences = p; save() }
    func setIntention(_ id: String) { guard Catalog.worlds.contains(where: { $0.id == id }) else { return }; var p = preferences; p.intention = id; state.preferences = p; save() }
    func setGentler(_ value: Bool) { var p = preferences; p.gentler = value; state.preferences = p; save() }
    func toggleFavourite(_ id: String) { var p = preferences; if p.favourites.contains(id) { p.favourites.remove(id) } else { p.favourites.insert(id) }; state.preferences = p; save() }
    func didPractise(_ option: PracticeOption, in world: World) -> Bool {
        state.practices.contains { $0.worldID == world.id && ($0.optionID ?? world.options[0].id) == option.id }
    }
    func suggestedOption(in world: World) -> PracticeOption {
        world.options.first { !didPractise($0, in: world) } ?? world.options[0]
    }
    func discoveredCount(in world: World) -> Int { world.speciesPool.filter { state.discoveries[$0.id] != nil }.count }
    var suggestedWorld: World { Catalog.world(preferences.intention) }
    var usefulWorlds: [World] {
        Catalog.worlds.filter { w in state.practices.contains { $0.worldID == w.id && $0.helpful == "Yes" } }
    }
    func quickOption(in world: World, minutes: Int) -> PracticeOption {
        if minutes == 1, world.id == "forest" { return Catalog.option("forest-2", worldID: world.id) }
        if minutes == 1, world.id == "wetland" { return Catalog.option("wetland-3", worldID: world.id) }
        return suggestedOption(in: world)
    }

    func begin(_ world: World, minutes: Int, optionID: String? = nil, gentler: Bool = false, quickStart: Bool = false) {
        guard state.session == nil, [1, 2, 3, 5, 10].contains(minutes) else { return }
        let option = Catalog.option(optionID, worldID: world.id)
        state.session = WalkSession(worldID: world.id, optionID: option.id, gentler: gentler, quickStart: quickStart ? true : nil, target: Double(minutes * 60)); save()
    }
    func toggleTimer() {
        guard var session = state.session else { return }
        if session.startedAt == nil { session.resume() } else { session.pause() }
        state.session = session; save()
    }
    func setSessionGentler(_ value: Bool) { state.session?.gentler = value; save() }
    func cancelSession() { state.session = nil; save() }
    @discardableResult func complete(_ world: World, manual: Bool) -> UUID? {
        guard let session = state.session, session.worldID == world.id,
              state.learned.contains(world.id) || session.quickStart == true else { return nil }
        if !manual && session.elapsed() < session.target { return nil }
        let option = Catalog.option(session.optionID, worldID: world.id)
        let draw = drawReward(world.speciesPool.count)
        let species = world.speciesPool[draw.speciesIndex]
        var practice = Practice(worldID: world.id, method: manual ? "Self-reported" : "Timer completed", seconds: Int(session.elapsed()))
        let reward = makeReward(species: species, rarity: CharacterRarity.rolled(draw.rarityRoll), date: practice.date, practiceID: practice.id, worldID: world.id)
        practice.optionID = option.id
        practice.speciesID = species.id
        practice.rewardID = reward.id
        state.practices.insert(practice, at: 0)
        state.session = nil
        state.rewards = [reward] + (state.rewards ?? [])
        state.pendingRewardIDs = (state.pendingRewardIDs ?? []) + [reward.id]
        if state.discoveries[species.id] == nil { state.discoveries[species.id] = reward.date }
        save(); return practice.id
    }
    private func makeReward(species: Species, rarity: CharacterRarity, date: Date, practiceID: UUID? = nil,
                            worldID: String? = nil, daily: Bool? = nil) -> AnimalReward {
        let previous = rewards.first { $0.speciesID == species.id && $0.rarity == rarity }
        let nextBackdrop = previous.map { ($0.backdrop.rawValue + 1) % CardBackdrop.allCases.count } ?? 0
        return AnimalReward(speciesID: species.id, rarity: rarity, date: date, practiceID: practiceID,
                            originWorldID: worldID, isDailyCheckIn: daily, backdropIndex: nextBackdrop)
    }

    var rewards: [AnimalReward] { state.rewards ?? [] }
    var pendingRewards: [AnimalReward] {
        (state.pendingRewardIDs ?? []).compactMap { id in rewards.first { $0.id == id } }
    }
    var variants: [CharacterVariant] {
        Dictionary(grouping: rewards, by: \.variantID).values.compactMap { copies in
            guard let first = copies.first, let species = Catalog.species(first.speciesID) else { return nil }
            return CharacterVariant(species: species, rarity: first.rarity, copies: copies.sorted { $0.date > $1.date })
        }.sorted { $0.copies[0].date > $1.copies[0].date }
    }
    func acknowledgeReward(_ id: UUID) { state.pendingRewardIDs?.removeAll { $0 == id }; save() }
    func reflect(_ id: UUID, text: String, helpful: String) {
        guard let index = state.practices.firstIndex(where: { $0.id == id }) else { return }
        state.practices[index].reflection = text
        state.practices[index].helpful = helpful; save()
    }
    func shouldOfferDailyCheckIn(at now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard storageError == nil else { return false }
        if let last = state.lastDailyPrompt, calendar.isDate(last, inSameDayAs: now) { return false }
        guard !state.checkIns.contains(where: { calendar.isDate($0.date, inSameDayAs: now) }) else { return false }
        state.lastDailyPrompt = now
        save()
        return true
    }

    @discardableResult
    func checkIn(mood: String, factor: String, note: String, date: Date = Date(), editingID: UUID? = nil,
                 now: Date = Date(), calendar: Calendar = .current) -> AnimalReward? {
        guard date <= now else { return nil }
        if let editingID {
            guard let index = state.checkIns.firstIndex(where: { $0.id == editingID }) else { return nil }
            state.checkIns[index] = CheckIn(id: editingID, date: date, mood: mood, factor: factor, note: note)
        } else {
            state.checkIns.append(CheckIn(date: date, mood: mood, factor: factor, note: note))
        }
        state.checkIns.sort { $0.date > $1.date }

        var earned: AnimalReward?
        if editingID == nil, calendar.isDate(date, inSameDayAs: now),
           !rewards.contains(where: { $0.isDailyCheckIn == true && calendar.isDate($0.date, inSameDayAs: now) }) {
            let pool = Catalog.allSpecies
            let draw = drawReward(pool.count)
            let species = pool[draw.speciesIndex]
            let reward = makeReward(species: species, rarity: CharacterRarity.rolled(draw.rarityRoll), date: now, daily: true)
            state.rewards = [reward] + rewards
            state.pendingRewardIDs = (state.pendingRewardIDs ?? []) + [reward.id]
            if state.discoveries[species.id] == nil { state.discoveries[species.id] = now }
            earned = reward
        }
        save()
        return earned
    }
    var progressExport: String {
        let learning = Catalog.worlds.map { world in
            "\(world.name): lesson \(state.learned.contains(world.id) ? "completed" : "not yet completed"), \(state.practices.filter { $0.worldID == world.id }.count) practices"
        }.joined(separator: "\n")
        let collection = variants.map { "\($0.species.name) • \($0.rarity.title) ×\($0.copies.count)" }.joined(separator: "\n")
        return "Wildwell — learning & character collection\n" + learning + "\n\nCHARACTERS\n" + collection
    }
    var privateExport: String {
        progressExport + "\n\nPRIVATE JOURNAL\n" + state.checkIns.map { "\($0.date.formatted()): \($0.mood) · \($0.factor)\n\($0.note)" }.joined(separator: "\n\n") + "\n\nREFLECTIONS\n" + state.practices.map { "\($0.date.formatted()) · \(Catalog.option($0.optionID, worldID: $0.worldID).title) · \($0.method)\nHelpfulness: \($0.helpful)\n\($0.reflection)" }.joined(separator: "\n\n")
    }
}
