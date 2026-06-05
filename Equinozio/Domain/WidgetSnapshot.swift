//
//  WidgetSnapshot.swift
//  Equinozio · Domain
//
//  Scrive un piccolo snapshot (equilibrio corrente) in UserDefaults condivisi,
//  così un futuro Widget Home Screen può leggerlo. Se l'App Group non è ancora
//  configurato, `UserDefaults(suiteName:)` ritorna nil e l'operazione è no-op.
//

import Foundation

public enum WidgetSnapshot {
    public static let suite = "group.it.systema360.equinozio"
    public static let chiaveEquilibrio = "equilibrioCorrente"

    public static let chiaveSpuntoTesto = "spuntoTesto"
    public static let chiaveSpuntoTipo = "spuntoTipo"
    public static let chiaveSettimana = "settimanaID"

    public static func aggiorna(equilibrio: Int) {
        guard let difese = UserDefaults(suiteName: suite) else { return }
        difese.set(equilibrio, forKey: chiaveEquilibrio)
    }

    /// Snapshot completo: equilibrio + Spunto della settimana (per widget e notifica).
    public static func aggiorna(equilibrio: Int, spuntoTesto: String, spuntoTipo: String, settimanaID: String) {
        guard let difese = UserDefaults(suiteName: suite) else { return }
        difese.set(equilibrio, forKey: chiaveEquilibrio)
        difese.set(spuntoTesto, forKey: chiaveSpuntoTesto)
        difese.set(spuntoTipo, forKey: chiaveSpuntoTipo)
        difese.set(settimanaID, forKey: chiaveSettimana)
    }
}
