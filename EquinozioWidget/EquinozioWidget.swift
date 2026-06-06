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
private let chiaveEquilibrio = "equilibrioCorrente"

// MARK: - Timeline

struct EquinozioEntry: TimelineEntry {
    let date: Date
    let equilibrio: Int
    let spunto: String
}

struct EquinozioProvider: TimelineProvider {
    func placeholder(in context: Context) -> EquinozioEntry {
        EquinozioEntry(date: .now, equilibrio: 72, spunto: "Settimana in equilibrio.")
    }

    func getSnapshot(in context: Context, completion: @escaping (EquinozioEntry) -> Void) {
        completion(EquinozioEntry(date: .now, equilibrio: leggiEquilibrio(), spunto: leggiSpunto()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EquinozioEntry>) -> Void) {
        let entry = EquinozioEntry(date: .now, equilibrio: leggiEquilibrio(), spunto: leggiSpunto())
        // Aggiornamento di cortesia ogni ora (l'app aggiorna lo snapshot al salvataggio).
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600))))
    }

    private func leggiEquilibrio() -> Int {
        guard let difese = UserDefaults(suiteName: gruppoCondiviso),
              let valore = difese.object(forKey: chiaveEquilibrio) as? Int
        else { return 50 }
        return valore
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
        Group {
            switch famiglia {
            case .systemLarge: grande
            case .systemMedium: medio
            default: piccolo
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(famiglia == .systemSmall ? 16 : 20)
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: "equinozio://riflessione"))
    }

    // systemSmall: numero + pallini dei cerchi
    private var piccolo: some View {
        VStack(alignment: .leading, spacing: 6) {
            etichetta
            numero
            Spacer(minLength: 0)
            HStack(spacing: 5) {
                ForEach(cerchiEquinozio.indices, id: \.self) { i in
                    Circle().fill(cerchiEquinozio[i].colore).frame(width: 8, height: 8)
                }
                Spacer()
                marchio
            }
        }
    }

    // systemMedium: numero a sinistra + legenda dei quattro cerchi a destra
    private var medio: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                etichetta
                numero
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
            VStack(alignment: .leading, spacing: 9) {
                ForEach(cerchiEquinozio.indices, id: \.self) { i in
                    HStack(spacing: 8) {
                        Circle().fill(cerchiEquinozio[i].colore).frame(width: 8, height: 8)
                        Text(cerchiEquinozio[i].nome)
                            .font(.system(size: 13, weight: .light))
                    }
                }
            }
        }
    }

    // systemLarge: numero grande + i quattro cerchi con nome e descrizione breve
    private var grande: some View {
        VStack(alignment: .leading, spacing: 16) {
            etichetta
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(entry.equilibrio)")
                    .font(.system(size: 68, weight: .thin))
                    .monospacedDigit()
                Text("%")
                    .font(.system(size: 24, weight: .thin))
                    .foregroundStyle(.secondary)
            }

            Divider()

            if !entry.spunto.isEmpty {
                Text(entry.spunto)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }

            VStack(alignment: .leading, spacing: 13) {
                ForEach(cerchiEquinozio.indices, id: \.self) { i in
                    HStack(spacing: 10) {
                        Circle().fill(cerchiEquinozio[i].colore).frame(width: 10, height: 10)
                        Text(cerchiEquinozio[i].nome)
                            .font(.system(size: 16, weight: .light))
                    }
                }
            }

            Spacer(minLength: 0)
            marchio
        }
    }

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

    private var marchio: some View {
        Text("Equinozio")
            .font(.system(size: 11, weight: .light))
            .foregroundStyle(.secondary)
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
    EquinozioEntry(date: .now, equilibrio: 72, spunto: "")
    EquinozioEntry(date: .now, equilibrio: 38, spunto: "")
}

#Preview(as: .systemMedium) {
    EquinozioWidget()
} timeline: {
    EquinozioEntry(date: .now, equilibrio: 72, spunto: "Settimana in equilibrio.")
}

#Preview(as: .systemLarge) {
    EquinozioWidget()
} timeline: {
    EquinozioEntry(date: .now, equilibrio: 72, spunto: "Settimana in equilibrio.")
}
