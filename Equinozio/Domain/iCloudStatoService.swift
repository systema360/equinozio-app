//
//  iCloudStatoService.swift
//  Equinozio · Domain
//
//  Verifica lo stato dell'account iCloud e del container CloudKit privato.
//

import Foundation
import CloudKit
import OSLog

@MainActor
@Observable
public final class iCloudStatoService {

    public enum Stato {
        case sconosciuto
        case disponibile
        case nonLoggato
        case limitato
        case erroreTemporaneo(String)

        public var titolo: String {
            switch self {
            case .sconosciuto:           return "Sto controllando…"
            case .disponibile:           return "Sincronizzato"
            case .nonLoggato:            return "iCloud non attivo"
            case .limitato:              return "iCloud limitato"
            case .erroreTemporaneo(let m): return "Errore: \(m)"
            }
        }

        public var simbolo: String {
            switch self {
            case .sconosciuto:           return "icloud"
            case .disponibile:           return "checkmark.icloud"
            case .nonLoggato:            return "icloud.slash"
            case .limitato:              return "exclamationmark.icloud"
            case .erroreTemporaneo:      return "exclamationmark.icloud"
            }
        }

        public var descrizione: String {
            switch self {
            case .sconosciuto:
                return "Verifica in corso del tuo account iCloud."
            case .disponibile:
                return "Il tuo diario viene salvato nel container privato iCloud. Sincronizzato tra iPhone e Mac."
            case .nonLoggato:
                return "Non sei collegato a iCloud · i dati restano solo su questo dispositivo. Attiva iCloud da Impostazioni di sistema per la sincronizzazione."
            case .limitato:
                return "Il tuo account iCloud ha restrizioni. La sincronizzazione potrebbe non funzionare."
            case .erroreTemporaneo(let m):
                return "Si è verificato un problema temporaneo: \(m). Riprova più tardi."
            }
        }

        public var disponibile: Bool {
            if case .disponibile = self { return true } else { return false }
        }
    }

    public static let shared = iCloudStatoService()

    public private(set) var stato: Stato = .sconosciuto

    private let log = Logger(subsystem: "it.systema360.equinozio", category: "iCloud")
    private let container = CKContainer(identifier: "iCloud.it.systema360.equinozio")

    private init() {}

    public func verifica() async {
        do {
            let statusAccount = try await container.accountStatus()
            switch statusAccount {
            case .available:
                stato = .disponibile
            case .noAccount:
                stato = .nonLoggato
            case .restricted:
                stato = .limitato
            case .couldNotDetermine, .temporarilyUnavailable:
                stato = .erroreTemporaneo("stato non determinabile")
            @unknown default:
                stato = .erroreTemporaneo("stato sconosciuto")
            }
        } catch {
            log.warning("Errore CloudKit account status: \(error.localizedDescription)")
            stato = .erroreTemporaneo(error.localizedDescription)
        }
    }
}
