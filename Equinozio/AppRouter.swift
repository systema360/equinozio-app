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
    /// Mappa un URL `equinozio://<scheda>` alla scheda corrispondente.
    static func fromDeepLink(_ url: URL) -> Scheda? {
        guard url.scheme == "equinozio" else { return nil }
        switch url.host {
        case "mappa":       return .mappa
        case "diario":      return .diario
        case "riflessione": return .riflessione
        case "decisione":   return .decisione
        default:            return nil
        }
    }
}
