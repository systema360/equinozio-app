//
//  Formattazione.swift
//  Equinozio · Domain
//
//  Formatter date italiani condivisi (cache statica · evita allocazioni ripetute).
//

import Foundation

public enum Formattazione {
    /// "lunedì 3 giugno" (giorno + mese esteso).
    public static let giornoMese: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "it_IT"); f.dateFormat = "EEEE d MMMM"; return f
    }()
    /// "lunedì 3 giugno · 14:30".
    public static let giornoMeseOra: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "it_IT"); f.dateFormat = "EEEE d MMMM · HH:mm"; return f
    }()
    /// "lun 3 giu" (abbreviato).
    public static let giornoMeseBreve: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "it_IT"); f.dateFormat = "EEEE d MMM"; return f
    }()
}
