//
//  AppRouter.swift
//  Equinozio
//
//  Routing globale fra le schede + mappatura dei deep link (equinozio://…).
//

import SwiftUI

@Observable
final class AppRouter {
    var scheda: Scheda = .mappa
    init() {}
}

extension Scheda {
    /// Mappa un host (mappa/diario/riflessione/decisione) alla scheda.
    nonisolated static func from(host: String?) -> Scheda? {
        switch host {
        case "mappa":       return .mappa
        case "diario":      return .diario
        case "riflessione": return .riflessione
        case "decisione":   return .decisione
        default:            return nil
        }
    }

    /// Mappa un URL `equinozio://<scheda>` alla scheda corrispondente.
    nonisolated static func fromDeepLink(_ url: URL) -> Scheda? {
        guard url.scheme == "equinozio" else { return nil }
        return from(host: url.host)
    }

    /// Scheda pertinente al tipo di Spunto (per il tap sulle card "Spunti").
    nonisolated static func perInsight(_ tipo: TipoInsight) -> Scheda {
        switch tipo {
        case .bilanciamentoBasso, .dominanzaCerchio, .crescitaTrend: return .riflessione
        case .decisioneStorica: return .decisione
        }
    }
}
