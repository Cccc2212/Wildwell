import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers

enum Palette {
    static let ink = Color(red: 0.12, green: 0.25, blue: 0.23)
    static let cream = Color(red: 0.98, green: 0.97, blue: 0.92)
    static let green = Color(red: 0.20, green: 0.43, blue: 0.32)
    static func tint(_ id: String) -> Color {
        switch id {
        case "ocean": Color(red: 0.16, green: 0.43, blue: 0.55)
        case "woodland": Color(red: 0.58, green: 0.34, blue: 0.18)
        case "wetland": Color(red: 0.44, green: 0.36, blue: 0.58)
        default: green
        }
    }
    static func sky(_ id: String) -> Color {
        switch id {
        case "ocean": Color(red: 0.68, green: 0.86, blue: 0.9)
        case "woodland": Color(red: 0.98, green: 0.85, blue: 0.62)
        case "wetland": Color(red: 0.83, green: 0.80, blue: 0.91)
        default: Color(red: 0.76, green: 0.86, blue: 0.68)
        }
    }
}

/// Original vector artwork. Stylised characters, not field-identification diagrams.
struct HabitatArt: View {
    let world: World
    var species: Species? = nil
    var mystery = false
    var backdrop: CardBackdrop = .daylight
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                sky
                Circle().fill(luminary).frame(width: 64, height: 64).position(x: w * 0.78, y: h * 0.22)
                if backdrop == .moonlight {
                    ForEach(0..<9) { i in
                        Circle().fill(.white.opacity(0.7)).frame(width: 3, height: 3)
                            .position(x: w * (0.08 + Double(i) * 0.10), y: h * (0.12 + Double(i % 3) * 0.09))
                    }
                }
                Ellipse().fill(.white.opacity(0.3)).frame(width: w * 0.8, height: h * 0.35).position(x: w * 0.2, y: h * 0.45)
                Ellipse().fill(Palette.tint(world.id).opacity(0.18)).frame(width: w * 1.4, height: h * 0.8).position(x: w * 0.65, y: h * 0.9)
                Ellipse().fill(Palette.tint(world.id).opacity(0.3)).frame(width: w * 1.3, height: h * 0.5).position(x: w * 0.2, y: h)
                ForEach(0..<5) { i in
                    let x = CGFloat(i) * w / 4
                    if world.id == "ocean" || world.id == "wetland" {
                        Capsule().fill(Palette.tint(world.id).opacity(0.35)).frame(width: 7, height: 45 + CGFloat(i % 3) * 16).rotationEffect(.degrees(Double(i * 9 - 15))).position(x: x, y: h * 0.88)
                    } else {
                        Capsule().fill(Palette.tint(world.id).opacity(0.22)).frame(width: 13, height: h * 0.6).position(x: x, y: h * 0.64)
                        Ellipse().fill(Palette.tint(world.id).opacity(0.4)).frame(width: w * 0.3, height: h * 0.52).position(x: x, y: h * 0.3)
                    }
                }
                AnimalArt(kind: (species ?? world.species).id).frame(width: min(w * 0.66, h * 0.95), height: h * 0.86)
                    .brightness(mystery ? -0.8 : 0).position(x: w * 0.53, y: h * 0.58)
                if mystery { Text("?").font(.system(size: 45, weight: .black, design: .rounded)).foregroundStyle(.white).position(x: w * 0.53, y: h * 0.55) }
                ForEach(0..<3) { i in
                    Image(systemName: "sparkle").font(.system(size: 12 + CGFloat(i * 3))).foregroundStyle(.white.opacity(0.8)).position(x: w * (0.22 + Double(i) * 0.28), y: h * (i == 1 ? 0.18 : 0.5))
                }
            }.clipped()
        }.accessibilityHidden(true)
    }

    private var sky: some View {
        let colours: [Color] = switch backdrop {
        case .daylight: [Palette.sky(world.id), Palette.sky(world.id)]
        case .sunset: [Color(red: 0.98, green: 0.67, blue: 0.62), Color(red: 1, green: 0.87, blue: 0.65)]
        case .moonlight: [Color(red: 0.20, green: 0.25, blue: 0.48), Color(red: 0.47, green: 0.54, blue: 0.70)]
        }
        return LinearGradient(colors: colours, startPoint: .top, endPoint: .bottom)
    }

    private var luminary: Color {
        switch backdrop {
        case .daylight: .white.opacity(0.65)
        case .sunset: Color(red: 1, green: 0.93, blue: 0.70)
        case .moonlight: Color(red: 0.91, green: 0.94, blue: 1)
        }
    }
}

struct AnimalArt: View {
    let kind: String
    var body: some View {
        Canvas { c, size in
            let sx = size.width / 240
            let sy = size.height / 240
            c.scaleBy(x: sx, y: sy)
            func ellipse(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ color: Color) {
                c.fill(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
            }
            func shape(_ points: [CGPoint], _ color: Color) {
                var p = Path(); p.addLines(points); p.closeSubpath(); c.fill(p, with: .color(color))
            }
            let orange = Color(red: 0.79, green: 0.35, blue: 0.17)
            let dark = Color(red: 0.20, green: 0.20, blue: 0.18)
            let ivory = Color(red: 1, green: 0.94, blue: 0.81)
            let brown = Color(red: 0.46, green: 0.32, blue: 0.22)
            ellipse(38, 212, 170, 16, .black.opacity(0.10))
            func line(_ points: [CGPoint], _ color: Color, _ width: Double = 5) {
                var p = Path(); p.addLines(points); c.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            }
            func eyes(_ y: Double, _ left: Double = 83, _ right: Double = 148) {
                ellipse(left, y, 10, 13, dark); ellipse(right, y, 10, 13, dark)
                ellipse(left + 3, y + 1, 3, 4, .white); ellipse(right + 3, y + 1, 3, 4, .white)
            }
            func smile(_ y: Double) {
                var p = Path(); p.move(to: CGPoint(x: 108, y: y)); p.addQuadCurve(to: CGPoint(x: 133, y: y), control: CGPoint(x: 120, y: y + 13)); c.stroke(p, with: .color(dark), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            let sage = Color(red: 0.40, green: 0.57, blue: 0.32)
            let slate = Color(red: 0.43, green: 0.55, blue: 0.62)
            if kind == "turtle" {
                ellipse(34, 83, 51, 28, sage); ellipse(157, 83, 51, 28, sage)
                ellipse(42, 174, 48, 23, sage); ellipse(150, 174, 48, 23, sage)
                ellipse(62, 68, 117, 139, Color(red: 0.26, green: 0.43, blue: 0.28))
                ellipse(74, 82, 92, 112, Color(red: 0.55, green: 0.65, blue: 0.37))
                line([CGPoint(x: 120,y: 90),CGPoint(x: 91,y: 113),CGPoint(x: 91,y: 154),CGPoint(x: 120,y: 178),CGPoint(x: 149,y: 154),CGPoint(x: 149,y: 113),CGPoint(x: 120,y: 90)], sage, 4)
                line([CGPoint(x: 91,y: 113),CGPoint(x: 77,y: 105)],sage,4); line([CGPoint(x: 149,y: 113),CGPoint(x: 164,y: 105)],sage,4)
                ellipse(82, 29, 76, 70, sage); eyes(55, 99, 132); smile(79)
                return
            }
            if kind == "ray" {
                line([CGPoint(x:120,y:145),CGPoint(x:130,y:199),CGPoint(x:152,y:224)],dark,5)
                var p = Path(); p.move(to: CGPoint(x:120,y:66)); p.addCurve(to:CGPoint(x:17,y:139),control1:CGPoint(x:83,y:74),control2:CGPoint(x:40,y:87)); p.addQuadCurve(to:CGPoint(x:95,y:159),control:CGPoint(x:37,y:174)); p.addQuadCurve(to:CGPoint(x:145,y:159),control:CGPoint(x:120,y:189)); p.addQuadCurve(to:CGPoint(x:224,y:139),control:CGPoint(x:199,y:174)); p.addCurve(to:CGPoint(x:120,y:66),control1:CGPoint(x:200,y:87),control2:CGPoint(x:157,y:74)); c.fill(p,with:.color(slate))
                ellipse(87,83,19,20,slate);ellipse(137,83,19,20,slate);eyes(87,92,142)
                line([CGPoint(x:45,y:137),CGPoint(x:76,y:127)],.white.opacity(0.25),4);line([CGPoint(x:164,y:127),CGPoint(x:195,y:137)],.white.opacity(0.25),4)
                return
            }
            if kind == "heron" {
                line([CGPoint(x:105,y:164),CGPoint(x:99,y:211),CGPoint(x:80,y:217)],dark,5)
                line([CGPoint(x:137,y:165),CGPoint(x:143,y:211),CGPoint(x:163,y:217)],dark,5)
                ellipse(62,115,109,63,slate);ellipse(77,123,78,42,Palette.ink.opacity(0.25))
                line([CGPoint(x:140,y:132),CGPoint(x:160,y:108),CGPoint(x:128,y:82),CGPoint(x:130,y:58)],slate,22)
                ellipse(107,36,53,40,slate);shape([CGPoint(x:153,y:50),CGPoint(x:209,y:63),CGPoint(x:152,y:68)],.orange)
                line([CGPoint(x:111,y:40),CGPoint(x:89,y:45)],dark,6);ellipse(137,47,9,10,.yellow);ellipse(140,49,5,7,dark)
                return
            }
            if kind == "frog" {
                ellipse(36,155,73,53,sage);ellipse(132,155,73,53,sage)
                ellipse(69,114,103,94,sage);ellipse(89,145,64,61,ivory.opacity(0.6))
                ellipse(47,85,147,80,sage);ellipse(61,65,50,51,sage);ellipse(132,65,50,51,sage)
                ellipse(70,71,31,34,ivory);ellipse(141,71,31,34,ivory);eyes(80,82,150);smile(137)
                line([CGPoint(x:80,y:164),CGPoint(x:70,y:201),CGPoint(x:59,y:208)],sage,13);line([CGPoint(x:159,y:164),CGPoint(x:170,y:201),CGPoint(x:181,y:208)],sage,13)
                for x in [59.0,172.0] { ellipse(x,117,10,7,Palette.green.opacity(0.4)) }
                return
            }
            if kind == "owl" {
                ellipse(58,91,124,121,brown);ellipse(76,136,88,69,ivory)
                ellipse(46,126,32,71,brown);ellipse(163,126,32,71,brown)
                shape([CGPoint(x:56,y:95),CGPoint(x:49,y:43),CGPoint(x:101,y:78)],brown)
                shape([CGPoint(x:139,y:78),CGPoint(x:191,y:43),CGPoint(x:184,y:95)],brown)
                ellipse(50,66,140,102,brown);ellipse(60,76,65,74,ivory);ellipse(117,76,65,74,ivory)
                ellipse(77,92,32,35,.yellow);ellipse(134,92,32,35,.yellow);eyes(102,88,145)
                shape([CGPoint(x:110,y:126),CGPoint(x:130,y:126),CGPoint(x:120,y:144)],.orange)
                for y in [163.0,180.0] { line([CGPoint(x:104,y:y),CGPoint(x:120,y:y+5),CGPoint(x:136,y:y)],brown,4) }
                line([CGPoint(x:87,y:211),CGPoint(x:100,y:211)],.orange,5);line([CGPoint(x:140,y:211),CGPoint(x:153,y:211)],.orange,5)
                return
            }
            if kind == "rabbit" {
                let fur = Color(red:0.65,green:0.54,blue:0.44)
                ellipse(173,166,37,37,.white);ellipse(66,125,115,91,fur)
                ellipse(70,18,36,94,fur);ellipse(133,18,36,94,fur)
                ellipse(80,29,15,65,ivory);ellipse(143,29,15,65,ivory)
                ellipse(50,78,140,94,fur);ellipse(85,131,70,32,ivory);eyes(110)
                ellipse(114,133,13,10,Color.pink);smile(148)
                ellipse(58,193,49,23,fur);ellipse(134,193,49,23,fur)
                return
            }
            if kind == "sloth" {
                line([CGPoint(x:25,y:34),CGPoint(x:210,y:34)],brown,15)
                ellipse(69,105,105,108,brown)
                line([CGPoint(x:78,y:149),CGPoint(x:51,y:112),CGPoint(x:55,y:36)],brown,24)
                line([CGPoint(x:163,y:149),CGPoint(x:192,y:112),CGPoint(x:186,y:36)],brown,24)
                for x in [48.0,59.0,179.0,190.0] { line([CGPoint(x:x,y:42),CGPoint(x:x+2,y:27)],ivory,5) }
                ellipse(50,66,140,109,brown);ellipse(61,76,118,86,ivory)
                ellipse(67,96,45,32,brown);ellipse(130,96,45,32,brown);eyes(104)
                ellipse(113,125,16,11,dark);smile(143)
                return
            }
            if kind == "lemur" {
                let fur = Color(red:0.59,green:0.61,blue:0.60)
                line([CGPoint(x:164,y:192),CGPoint(x:199,y:156),CGPoint(x:204,y:43)],fur,29)
                for i in 0..<7 { line([CGPoint(x:194,y:49+Double(i*17)),CGPoint(x:214,y:49+Double(i*17))],i.isMultiple(of:2) ? ivory : dark,12) }
                ellipse(65,123,111,92,fur);ellipse(49,63,43,45,ivory);ellipse(146,63,43,45,ivory)
                ellipse(55,66,126,105,ivory);ellipse(69,95,43,39,dark);ellipse(128,95,43,39,dark)
                ellipse(80,104,19,20,.orange);ellipse(140,104,19,20,.orange);eyes(108,85,145)
                ellipse(112,135,17,12,dark);smile(151)
                ellipse(64,195,43,22,fur);ellipse(135,195,43,22,fur)
                return
            }
            if kind == "axolotl" {
                let pink = Color(red: 0.94, green: 0.64, blue: 0.67)
                let gill = Color(red: 0.78, green: 0.33, blue: 0.45)
                ellipse(90, 130, 70, 85, pink)
                shape([CGPoint(x: 140,y: 190), CGPoint(x: 221,y: 148), CGPoint(x: 191,y: 209), CGPoint(x: 130,y: 215)], pink)
                for x in [38.0, 182.0] {
                    for y in [70.0, 95.0, 120.0] {
                        var p = Path(); p.move(to: CGPoint(x: 120, y: 116)); p.addLine(to: CGPoint(x: x, y: y))
                        c.stroke(p, with: .color(gill), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        ellipse(x - 7, y - 7, 14, 14, gill)
                    }
                }
                ellipse(53, 65, 134, 98, pink)
                ellipse(67, 178, 40, 20, pink); ellipse(143, 178, 40, 20, pink)
            } else if kind == "otter" {
                ellipse(157, 153, 53, 62, brown)
                ellipse(64, 112, 115, 105, brown)
                ellipse(86, 127, 70, 77, Color(red: 0.67, green: 0.51, blue: 0.35))
                ellipse(48, 56, 39, 39, brown); ellipse(152, 56, 39, 39, brown)
                ellipse(54, 57, 129, 108, Color(red: 0.67, green: 0.51, blue: 0.35))
                ellipse(76, 106, 89, 46, ivory)
                ellipse(70, 166, 44, 25, brown); ellipse(134, 166, 44, 25, brown)
                ellipse(104, 160, 41, 29, Color(red: 0.71, green: 0.77, blue: 0.75))
            } else {
                ellipse(130, 133, 92, 81, orange)
                if kind == "panda" {
                    for i in 0..<4 { ellipse(167 + Double(i * 9), 143 + Double(i * 12), 37, 16, i % 2 == 0 ? ivory : brown) }
                } else { ellipse(176, 170, 44, 42, ivory) }
                ellipse(67, 123, 104, 94, kind == "panda" ? dark : orange)
                ellipse(79, 185, 31, 31, dark); ellipse(134, 185, 31, 31, dark)
                shape([CGPoint(x: 49,y: 92), CGPoint(x: 48,y: 24), CGPoint(x: 100,y: 68)], orange)
                shape([CGPoint(x: 142,y: 68), CGPoint(x: 192,y: 24), CGPoint(x: 188,y: 100)], orange)
                shape([CGPoint(x: 60,y: 70), CGPoint(x: 58,y: 40), CGPoint(x: 84,y: 68)], ivory)
                shape([CGPoint(x: 155,y: 68), CGPoint(x: 182,y: 40), CGPoint(x: 177,y: 77)], ivory)
                ellipse(43, 59, 151, 109, orange)
                ellipse(49, 98, 64, 56, ivory); ellipse(127, 98, 61, 56, ivory)
                if kind == "panda" { ellipse(72, 95, 28, 31, brown); ellipse(142, 95, 28, 31, brown) }
            }
            let eyeY = kind == "axolotl" ? 108.0 : 107.0
            ellipse(83, eyeY, 10, 13, dark); ellipse(148, eyeY, 10, 13, dark)
            ellipse(86, eyeY + 1, 3, 4, .white); ellipse(151, eyeY + 1, 3, 4, .white)
            if kind != "axolotl" { ellipse(112, 126, 16, 11, dark) }
            var smile = Path(); smile.move(to: CGPoint(x: 108, y: 140)); smile.addQuadCurve(to: CGPoint(x: 133, y: 140), control: CGPoint(x: 120, y: 152))
            c.stroke(smile, with: .color(dark), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
    }
}

extension CharacterRarity {
    var color: Color {
        switch self {
        case .rare: Color(red: 0.16, green: 0.39, blue: 0.80)
        case .epic: Color(red: 0.51, green: 0.26, blue: 0.73)
        case .myth: Color(red: 0.78, green: 0.19, blue: 0.28)
        }
    }
}
struct RarityBadge: View {
    let rarity: CharacterRarity
    var body: some View {
        Label(rarity.title, systemImage: rarity.symbol).font(.system(.caption, design: .rounded, weight: .bold))
            .padding(.horizontal, 12).padding(.vertical, 7).foregroundStyle(rarity.color)
            .background(rarity.color.opacity(0.10), in: Capsule())
    }
}
struct CharacterPortrait: View {
    let species: Species
    let rarity: CharacterRarity
    var backdrop: CardBackdrop = .daylight
    var body: some View {
        ZStack {
            HabitatArt(world: Catalog.home(of: species), species: species, backdrop: backdrop)
            LinearGradient(colors: [.clear, rarity.color.opacity(0.35)], startPoint: .center, endPoint: .bottom)
            VStack { HStack { Spacer(); Image(systemName: rarity.symbol).foregroundStyle(.white).padding(10).background(rarity.color, in: Circle()).padding(12) }; Spacer() }
        }.clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(rarity.color.opacity(0.8), lineWidth: 3))
            .accessibilityHidden(true)
    }
}

private struct CardPNG: Transferable {
    let data: Data
    let name: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { $0.data }
            .suggestedFileName { $0.name }
    }
}

struct CardShareButton: View {
    let reward: AnimalReward
    let species: Species
    @State private var image: CardPNG?

    var body: some View {
        ZStack {
            Color.clear.frame(width: 44, height: 44).accessibilityHidden(true)
            if let image {
                ShareLink(item: image, preview: SharePreview(species.name, image: image)) {
                    Label("Share card", systemImage: "square.and.arrow.up").labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                        .background(reward.rarity.color.opacity(0.09), in: Circle())
                }
                .accessibilityLabel("Share \(species.name) card")
                .accessibilityIdentifier("card.share")
            }
        }
        .task(id: reward.id) {
            let card = VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Eyebrow(text: "Wildwell • \(Catalog.home(of: species).name)")
                    Spacer(minLength: 8)
                    RarityBadge(rarity: reward.rarity)
                }
                CharacterPortrait(species: species, rarity: reward.rarity, backdrop: reward.backdrop).frame(height: 248)
                Text(species.name).font(.system(size: 32, weight: .bold, design: .rounded))
                Text(species.scientific).font(.subheadline.italic())
                Label(reward.sizeLabel(for: species), systemImage: "ruler").font(.headline)
                Text("\(reward.backdrop.title) edition · Illustrative card size").font(.caption)
            }
            .padding(22)
            .frame(width: 390)
            .foregroundStyle(Palette.ink)
            .background(Palette.cream)
            .environment(\.colorScheme, .light)
            .environment(\.dynamicTypeSize, .medium)

            let renderer = ImageRenderer(content: card)
            renderer.scale = 2
            if let data = renderer.uiImage?.pngData() {
                image = CardPNG(data: data, name: "Wildwell - \(species.name) - \(reward.rarity.title)")
            }
        }
    }
}
