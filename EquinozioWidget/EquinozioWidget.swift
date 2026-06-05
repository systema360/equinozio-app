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
}

struct EquinozioProvider: TimelineProvider {
    func placeholder(in context: Context) -> EquinozioEntry {
        EquinozioEntry(date: .now, equilibrio: 72)
    }

    func getSnapshot(in context: Context, completion: @escaping (EquinozioEntry) -> Void) {
        completion(EquinozioEntry(date: .now, equilibrio: leggiEquilibrio()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EquinozioEntry>) -> Void) {
        let entry = EquinozioEntry(date: .now, equilibrio: leggiEquilibrio())
        // Aggiornamento di cortesia ogni ora (l'app aggiorna lo snapshot al salvataggio).
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600))))
    }

    private func leggiEquilibrio() -> Int {
        guard let difese = UserDefaults(suiteName: gruppoCondiviso),
              let valore = difese.object(forKey: chiaveEquilibrio) as? Int
        else { return 50 }
        return valore
    }
}

// MARK: - Vista

struct EquinozioWidgetView: View {
    var entry: EquinozioEntry

    // Palette dei quattro cerchi (fissa: il widget non condivide l'asset catalog).
    private let cerchi: [Color] = [
        Color(red: 0.827, green: 0.557, blue: 0.549),  // Passione
        Color(red: 0.761, green: 0.745, blue: 0.494),  // Talento
        Color(red: 0.533, green: 0.737, blue: 0.592),  // Missione
        Color(red: 0.510, green: 0.686, blue: 0.776),  // Professione
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EQUILIBRIO")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.6)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(entry.equilibrio)")
                    .font(.system(size: 46, weight: .thin))
                    .monospacedDigit()
                Text("%")
                    .font(.system(size: 18, weight: .thin))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            HStack(spacing: 5) {
                ForEach(0..<4, id: \.self) { i in
                    Circle().fill(cerchi[i]).frame(width: 8, height: 8)
                }
                Spacer()
                Text("Equinozio")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(16)
        .containerBackground(.background, for: .widget)
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
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    EquinozioWidget()
} timeline: {
    EquinozioEntry(date: .now, equilibrio: 72)
    EquinozioEntry(date: .now, equilibrio: 38)
}
