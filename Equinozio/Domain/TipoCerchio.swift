//
//  TipoCerchio.swift
//  Equinozio · Domain
//
//  I quattro cerchi del metodo, con colore e titoli associati.
//

import SwiftUI

public enum TipoCerchio: String, Codable, CaseIterable, Identifiable, Hashable {
    case passione
    case talento
    case missione
    case professione

    public var id: String { rawValue }

    public nonisolated var titolo: String {
        switch self {
        case .passione:    return "Passione"
        case .talento:     return "Talento"
        case .missione:    return "Missione"
        case .professione: return "Professione"
        }
    }

    public var titoloEsplorazione: String {
        switch self {
        case .passione:    return "Cosa ami fare?"
        case .talento:     return "In cosa sei bravo?"
        case .missione:    return "Di cosa c'è bisogno?"
        case .professione: return "Per cosa ti pagano?"
        }
    }

    public var titoloRiflessione: String {
        switch self {
        case .passione:    return "Cose che amo"
        case .talento:     return "Cose in cui sono bravo"
        case .missione:    return "Cose di cui c'è bisogno"
        case .professione: return "Cose per cui mi pagano"
        }
    }

    public var colore: Color {
        switch self {
        case .passione:    return Color.passione
        case .talento:     return Color.talento
        case .missione:    return Color.missione
        case .professione: return Color.professione
        }
    }
}
