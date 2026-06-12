//
//  StatoIntelligenza.swift
//  Equinozio · Domain
//
//  Stato di Apple Intelligence per le funzioni "intelligenti" dell'app,
//  esposto alle viste senza dipendere da FoundationModels.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

public enum StatoIntelligenza: Equatable {
    case attiva
    case dispositivoNonIdoneo
    case appleIntelligenceDisattivata
    case modelloInArrivo
    case sistemaNonSupportato

    /// Stato corrente del modello di sistema.
    public static var corrente: StatoIntelligenza {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .attiva
            case .unavailable(let motivo):
                switch motivo {
                case .deviceNotEligible:           return .dispositivoNonIdoneo
                case .appleIntelligenceNotEnabled: return .appleIntelligenceDisattivata
                case .modelNotReady:               return .modelloInArrivo
                @unknown default:                  return .modelloInArrivo
                }
            @unknown default:
                return .modelloInArrivo
            }
        }
        #endif
        return .sistemaNonSupportato
    }

    /// Spiegazione breve da mostrare nelle Impostazioni.
    public var descrizione: String {
        switch self {
        case .attiva:
            return "Lo Spunto settimanale e il riassunto del diario sono generati sul dispositivo con Apple Intelligence. Nessun contenuto lascia il tuo iPhone o iPad."
        case .dispositivoNonIdoneo:
            return "Questo dispositivo non supporta Apple Intelligence: l'app usa le frasi essenziali, con gli stessi fatti e numeri."
        case .appleIntelligenceDisattivata:
            return "Apple Intelligence è disattivata. Puoi attivarla dalle Impostazioni iOS per spunti e riassunti più caldi; senza, l'app usa le frasi essenziali."
        case .modelloInArrivo:
            return "Il modello di Apple Intelligence non è ancora pronto su questo dispositivo (ad esempio è in download). Nel frattempo l'app usa le frasi essenziali."
        case .sistemaNonSupportato:
            return "Le funzioni intelligenti richiedono iOS 26. L'app funziona comunque, con le frasi essenziali."
        }
    }
}
