//
//  Tipografia.swift
//  Equinozio · DesignSystem
//
//  Una sola famiglia (Helvetica Neue di sistema), quattro pesi:
//  Thin (200), Light (300), Regular (400), Medium (500).
//  Mai Bold.
//

import SwiftUI

public enum StileTesto {
    case titoloGrande
    case titoloMedio
    case titoloPiccolo
    case corpoGrande
    case corpo
    case corpoMedio
    case occhiello
    case etichetta
    case cifraGrande
}

public extension Font {

    static func equinozio(_ stile: StileTesto) -> Font {
        switch stile {
        case .titoloGrande:
            return .system(size: 56, weight: .thin)
        case .titoloMedio:
            return .system(size: 34, weight: .thin)
        case .titoloPiccolo:
            return .system(size: 28, weight: .thin)
        case .corpoGrande:
            return .system(size: 17, weight: .light)
        case .corpo:
            return .system(size: 15, weight: .light)
        case .corpoMedio:
            return .system(size: 14, weight: .light)
        case .occhiello:
            return .system(size: 11, weight: .medium)
        case .etichetta:
            return .system(size: 10, weight: .medium)
        case .cifraGrande:
            return .system(size: 48, weight: .thin)
        }
    }
}
