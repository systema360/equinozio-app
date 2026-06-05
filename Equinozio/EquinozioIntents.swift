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
    static var title: LocalizedStringResource = "Apri la riflessione"
    static var description = IntentDescription("Apre Equinozio sulla riflessione settimanale.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set("riflessione", forKey: "pendingScheda")
        return .result()
    }
}
