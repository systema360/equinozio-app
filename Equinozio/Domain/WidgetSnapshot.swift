//
//  WidgetSnapshot.swift
//  Equinozio · Domain
//
//  Scrive uno snapshot (misure + Spunto) in UserDefaults condivisi (App Group),
//  così il Widget Home Screen / Lock Screen può leggerlo. Se l'App Group non è
//  configurato, `UserDefaults(suiteName:)` ritorna nil e l'operazione è no-op.
//

import Foundation

public nonisolated enum WidgetSnapshot {
    public static let suite = "group.it.systema360.equinozio"

    public static let chiaveEquilibrio = "equilibrioCorrente"
    public static let chiavePassione = "quotaPassione"
    public static let chiaveTalento = "quotaTalento"
    public static let chiaveMissione = "quotaMissione"
    public static let chiaveProfessione = "quotaProfessione"
    public static let chiaveTrend = "trendDelta"
    public static let chiaveHaTrend = "haTrend"
    public static let chiaveHaRiflessioni = "haRiflessioni"

    public static let chiaveSpuntoTesto = "spuntoTesto"
    public static let chiaveSpuntoTipo = "spuntoTipo"
    public static let chiaveSettimana = "settimanaID"

    /// Lo Spunto corrente dallo snapshot App Group (nil se assente/vuoto).
    public static func leggiSpunto() -> String? {
        guard let difese = UserDefaults(suiteName: suite) else { return nil }
        let t = (difese.string(forKey: chiaveSpuntoTesto) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    /// Aggiorna solo le misure (equilibrio + quote + tendenza), senza toccare lo Spunto.
    public static func aggiornaMisure(_ m: MisureWidget) {
        guard let difese = UserDefaults(suiteName: suite) else { return }
        scriviMisure(m, in: difese)
    }

    /// Snapshot completo: misure + Spunto della settimana (per widget e notifica).
    public static func aggiorna(misure: MisureWidget, spuntoTesto: String, spuntoTipo: String, settimanaID: String) {
        guard let difese = UserDefaults(suiteName: suite) else { return }
        scriviMisure(misure, in: difese)
        difese.set(spuntoTesto, forKey: chiaveSpuntoTesto)
        difese.set(spuntoTipo, forKey: chiaveSpuntoTipo)
        difese.set(settimanaID, forKey: chiaveSettimana)
    }

    /// Rilegge le misure (default `.vuoto` se non scritte).
    public static func leggiMisure() -> MisureWidget {
        guard let d = UserDefaults(suiteName: suite),
              d.object(forKey: chiaveHaRiflessioni) != nil
        else { return .vuoto }
        return MisureWidget(
            equilibrio: d.integer(forKey: chiaveEquilibrio),
            passione: d.integer(forKey: chiavePassione),
            talento: d.integer(forKey: chiaveTalento),
            missione: d.integer(forKey: chiaveMissione),
            professione: d.integer(forKey: chiaveProfessione),
            delta: d.integer(forKey: chiaveTrend),
            haTrend: d.bool(forKey: chiaveHaTrend),
            haRiflessioni: d.bool(forKey: chiaveHaRiflessioni)
        )
    }

    /// Rimuove l'intero snapshot dall'App Group (usato dalla cancellazione totale dei dati).
    public static func azzera() {
        guard let difese = UserDefaults(suiteName: suite) else { return }
        [chiaveEquilibrio, chiavePassione, chiaveTalento, chiaveMissione,
         chiaveProfessione, chiaveTrend, chiaveHaTrend, chiaveHaRiflessioni,
         chiaveSpuntoTesto, chiaveSpuntoTipo, chiaveSettimana]
            .forEach { difese.removeObject(forKey: $0) }
    }

    private static func scriviMisure(_ m: MisureWidget, in d: UserDefaults) {
        d.set(m.equilibrio, forKey: chiaveEquilibrio)
        d.set(m.passione, forKey: chiavePassione)
        d.set(m.talento, forKey: chiaveTalento)
        d.set(m.missione, forKey: chiaveMissione)
        d.set(m.professione, forKey: chiaveProfessione)
        d.set(m.delta, forKey: chiaveTrend)
        d.set(m.haTrend, forKey: chiaveHaTrend)
        d.set(m.haRiflessioni, forKey: chiaveHaRiflessioni)
    }
}
