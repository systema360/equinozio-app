//
//  EquinozioWidget.swift
//  EquinozioWidget
//
//  Widget Home Screen · mostra l'equilibrio settimanale corrente.
//  Legge lo snapshot scritto dall'app in UserDefaults condivisi (App Group).
//  Vedi WidgetSnapshot (app) e docs/widget-setup.md.
//

import WidgetKit
import SwiftUI

private let gruppoCondiviso = "group.it.systema360.equinozio"

// MARK: - Timeline

struct EquinozioEntry: TimelineEntry {
    let date: Date
    let equilibrio: Int
    let passione: Int
    let talento: Int
    let missione: Int
    let professione: Int
    let delta: Int
    let haTrend: Bool
    let haRiflessioni: Bool
    let spunto: String

    var quote: [Int] { [passione, talento, missione, professione] }

    static let esempio = EquinozioEntry(
        date: .now, equilibrio: 72, passione: 40, talento: 30, missione: 20,
        professione: 10, delta: 6, haTrend: true, haRiflessioni: true,
        spunto: "Settimana in equilibrio."
    )
    static let vuoto = EquinozioEntry(
        date: .now, equilibrio: 50, passione: 0, talento: 0, missione: 0,
        professione: 0, delta: 0, haTrend: false, haRiflessioni: false, spunto: ""
    )
}

struct EquinozioProvider: TimelineProvider {
    func placeholder(in context: Context) -> EquinozioEntry { .esempio }

    func getSnapshot(in context: Context, completion: @escaping (EquinozioEntry) -> Void) {
        completion(leggiEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EquinozioEntry>) -> Void) {
        let entry = leggiEntry()
        // Aggiornamento di cortesia ogni ora (l'app aggiorna lo snapshot al salvataggio).
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600))))
    }

    private func leggiEntry() -> EquinozioEntry {
        let d = UserDefaults(suiteName: gruppoCondiviso)
        let haRifl = d?.bool(forKey: "haRiflessioni") ?? false
        return EquinozioEntry(
            date: .now,
            equilibrio: (d?.object(forKey: "equilibrioCorrente") as? Int) ?? 50,
            passione: d?.integer(forKey: "quotaPassione") ?? 0,
            talento: d?.integer(forKey: "quotaTalento") ?? 0,
            missione: d?.integer(forKey: "quotaMissione") ?? 0,
            professione: d?.integer(forKey: "quotaProfessione") ?? 0,
            delta: d?.integer(forKey: "trendDelta") ?? 0,
            haTrend: d?.bool(forKey: "haTrend") ?? false,
            haRiflessioni: haRifl,
            spunto: leggiSpunto()
        )
    }

    private func settimanaCorrenteID() -> String {
        let c = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)
        return "\(c.yearForWeekOfYear ?? 0)-W\(c.weekOfYear ?? 0)"
    }

    private func leggiSpunto() -> String {
        let d = UserDefaults(suiteName: gruppoCondiviso)
        let sid = d?.string(forKey: "settimanaID") ?? ""
        guard sid == settimanaCorrenteID() else { return "" }
        return d?.string(forKey: "spuntoTesto") ?? ""
    }
}

// MARK: - Palette dei quattro cerchi (fissa: il widget non condivide l'asset catalog)

private let cerchiEquinozio: [(nome: String, colore: Color)] = [
    ("Passione", Color(red: 0.827, green: 0.557, blue: 0.549)),
    ("Talento", Color(red: 0.761, green: 0.745, blue: 0.494)),
    ("Missione", Color(red: 0.533, green: 0.737, blue: 0.592)),
    ("Professione", Color(red: 0.510, green: 0.686, blue: 0.776)),
]

// MARK: - Vista

struct EquinozioWidgetView: View {
    @Environment(\.widgetFamily) private var famiglia
    var entry: EquinozioEntry

    var body: some View {
        contenutoHome
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(famiglia == .systemSmall ? 16 : 20)
            .containerBackground(.background, for: .widget)
            .widgetURL(URL(string: "equinozio://riflessione"))
    }

    @ViewBuilder private var contenutoHome: some View {
        if !entry.haRiflessioni {
            statoVuoto
        } else {
            switch famiglia {
            case .systemLarge: grande
            case .systemMedium: medio
            default: piccolo
            }
        }
    }

    // systemSmall: numero + tendenza + barra segmentata
    private var piccolo: some View {
        VStack(alignment: .leading, spacing: 6) {
            etichetta
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                numero
                tendenza
            }
            Spacer(minLength: 0)
            barraSegmentata
            HStack(spacing: 5) {
                Spacer()
                marchio
            }
        }
    }

    // systemMedium: numero + spunto a sinistra, barre dei cerchi a destra
    private var medio: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                etichetta
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    numero
                    tendenza
                }
                if !entry.spunto.isEmpty {
                    Text(entry.spunto)
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                Spacer(minLength: 0)
                marchio
            }
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(cerchiEquinozio.indices, id: \.self) { i in
                    rigaBarra(i)
                }
            }
            .frame(width: 150)
        }
    }

    // systemLarge: numero grande + spunto + barre etichettate
    private var grande: some View {
        VStack(alignment: .leading, spacing: 14) {
            etichetta
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(entry.equilibrio)")
                        .font(.system(size: 64, weight: .thin))
                        .monospacedDigit()
                    Text("%")
                        .font(.system(size: 22, weight: .thin))
                        .foregroundStyle(.secondary)
                }
                tendenza
            }

            Divider()

            if !entry.spunto.isEmpty {
                Text(entry.spunto)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(cerchiEquinozio.indices, id: \.self) { i in
                    rigaBarra(i)
                }
            }

            Spacer(minLength: 0)
            marchio
        }
    }

    // MARK: - Componenti

    private var etichetta: some View {
        Text("EQUILIBRIO")
            .font(.system(size: 10, weight: .medium))
            .tracking(1.6)
            .foregroundStyle(.secondary)
    }

    private var numero: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("\(entry.equilibrio)")
                .font(.system(size: 46, weight: .thin))
                .monospacedDigit()
            Text("%")
                .font(.system(size: 18, weight: .thin))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var tendenza: some View {
        if entry.haTrend {
            HStack(spacing: 2) {
                Image(systemName: entry.delta > 0 ? "arrow.up"
                    : entry.delta < 0 ? "arrow.down" : "arrow.right")
                Text("\(abs(entry.delta))")
                    .monospacedDigit()
            }
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(.secondary)
        }
    }

    private var marchio: some View {
        Text("Equinozio")
            .font(.system(size: 11, weight: .light))
            .foregroundStyle(.secondary)
    }

    // Riga: nome cerchio + % + barra proporzionale.
    private func rigaBarra(_ i: Int) -> some View {
        let quota = entry.quote[i]
        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(cerchiEquinozio[i].nome)
                    .font(.system(size: 12, weight: .light))
                Spacer()
                Text("\(quota)%")
                    .font(.system(size: 12, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(cerchiEquinozio[i].colore.opacity(0.18))
                    Capsule().fill(cerchiEquinozio[i].colore)
                        .frame(width: geo.size.width * CGFloat(min(100, max(0, quota))) / 100)
                }
            }
            .frame(height: 5)
        }
    }

    // Barra unica con 4 segmenti proporzionali (widget piccolo).
    private var barraSegmentata: some View {
        let somma = max(1, entry.quote.reduce(0, +))
        return GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(cerchiEquinozio.indices, id: \.self) { i in
                    Capsule()
                        .fill(cerchiEquinozio[i].colore)
                        .frame(width: max(2, geo.size.width * CGFloat(entry.quote[i]) / CGFloat(somma)))
                }
            }
        }
        .frame(height: 6)
    }

    // Stato senza riflessioni: invito ad agire.
    private var statoVuoto: some View {
        VStack(alignment: .leading, spacing: 8) {
            etichetta
            Text(famiglia == .systemSmall ? "Inizia la\ntua mappa" : "Fai la tua prima riflessione")
                .font(.system(size: famiglia == .systemSmall ? 16 : 20, weight: .light))
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
            HStack {
                HStack(spacing: 5) {
                    ForEach(cerchiEquinozio.indices, id: \.self) { i in
                        Circle().fill(cerchiEquinozio[i].colore).frame(width: 8, height: 8)
                    }
                }
                Spacer()
                marchio
            }
        }
    }
}

// MARK: - Widget

@main
struct EquinozioWidget: Widget {
    let kind = "EquinozioWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EquinozioProvider()) { entry in
            EquinozioWidgetView(entry: entry)
        }
        .configurationDisplayName("Equilibrio")
        .description("Il tuo equilibrio settimanale, sempre a colpo d'occhio.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    EquinozioWidget()
} timeline: {
    EquinozioEntry.esempio
    EquinozioEntry.vuoto
}

#Preview(as: .systemMedium) {
    EquinozioWidget()
} timeline: {
    EquinozioEntry.esempio
    EquinozioEntry.vuoto
}

#Preview(as: .systemLarge) {
    EquinozioWidget()
} timeline: {
    EquinozioEntry.esempio
}
