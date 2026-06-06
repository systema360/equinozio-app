//
//  Settimana.swift
//  Equinozio · Domain
//
//  Identificatore deterministico della settimana (per la cache degli Spunti).
//

import Foundation

public nonisolated enum Settimana {
    /// Es. "2026-W23". Indipendente dal locale: usa year-for-week-of-year + week-of-year.
    public static func id(per data: Date, calendario: Calendar = .current) -> String {
        let c = calendario.dateComponents([.yearForWeekOfYear, .weekOfYear], from: data)
        return "\(c.yearForWeekOfYear ?? 0)-W\(c.weekOfYear ?? 0)"
    }
}
