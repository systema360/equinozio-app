//
//  EquinozioIntents.swift
//  Equinozio
//
//  App Intents per Siri / Spotlight / Scorciatoie.
//

import AppIntents
import Foundation

/// Apre l'app sulla Riflessione. Scrive una "scheda in attesa" che l'app consuma all'avvio.
struct ApriRiflessioneIntent: AppIntent {
    static let title: LocalizedStringResource = "Apri la riflessione"
    static let description = IntentDescription("Apre Equinozio sulla riflessione settimanale.")
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set("riflessione", forKey: "pendingScheda")
        return .result()
    }
}

/// Legge l'equilibrio corrente dallo snapshot App Group e lo riporta a voce.
struct EquilibrioCorrenteIntent: AppIntent {
    static let title: LocalizedStringResource = "Equilibrio corrente"
    static let description = IntentDescription("Dice il tuo equilibrio settimanale.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let equilibrio = UserDefaults(suiteName: WidgetSnapshot.suite)?
            .integer(forKey: WidgetSnapshot.chiaveEquilibrio) ?? 50
        return .result(dialog: "Il tuo equilibrio è \(equilibrio)%.")
    }
}

struct EquinozioShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ApriRiflessioneIntent(),
            phrases: [
                "Apri la riflessione di \(.applicationName)",
                "Rifletti con \(.applicationName)",
            ],
            shortTitle: "Riflessione",
            systemImageName: "moon.stars"
        )
        AppShortcut(
            intent: EquilibrioCorrenteIntent(),
            phrases: [
                "Com'è il mio equilibrio su \(.applicationName)",
                "Equilibrio di \(.applicationName)",
            ],
            shortTitle: "Equilibrio",
            systemImageName: "circle.grid.2x2"
        )
    }
}
