//
//  BlocoAppService.swift
//  Equinozio · Domain
//
//  Sblocco dell'applicazione tramite Face ID / Touch ID / passcode.
//  L'utente abilita la protezione dalle Impostazioni · all'apertura dell'app
//  (o quando torna dal background) chiediamo la biometrica.
//

import Foundation
import LocalAuthentication
import OSLog

@MainActor
@Observable
public final class BlocoAppService {

    public static let shared = BlocoAppService()
    private let log = Logger(subsystem: "it.systema360.equinozio", category: "Bloco")

    /// L'app è sbloccata in questo momento?
    public private(set) var sbloccata: Bool = false

    /// Tipo di biometria disponibile sul dispositivo, se attiva.
    public var tipoBiometria: TipoBiometria {
        let contesto = LAContext()
        var errore: NSError?
        guard contesto.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &errore) else {
            return .nessuna
        }
        switch contesto.biometryType {
        case .faceID:  return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        default:       return .nessuna
        }
    }

    private init() {}

    /// Tenta lo sblocco con biometria/passcode. Aggiorna `sbloccata`.
    @discardableResult
    public func sblocca(motivo: String = "Sblocca Equinozio") async -> Bool {
        let contesto = LAContext()
        contesto.localizedFallbackTitle = "Usa il codice"
        contesto.localizedCancelTitle = "Annulla"

        var errore: NSError?
        guard contesto.canEvaluatePolicy(.deviceOwnerAuthentication, error: &errore) else {
            log.warning("Biometria non disponibile · \(errore?.localizedDescription ?? "?")")
            // Se non c'è biometria/passcode, sblocchiamo (l'utente non può proteggersi)
            sbloccata = true
            return true
        }

        do {
            let ok = try await contesto.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: motivo
            )
            sbloccata = ok
            return ok
        } catch {
            log.info("Sblocco fallito o annullato · \(error.localizedDescription)")
            sbloccata = false
            return false
        }
    }

    /// Forza il blocco dell'app (es. quando va in background).
    public func blocca() {
        sbloccata = false
    }
}

public enum TipoBiometria {
    case nessuna, faceID, touchID, opticID

    public var nome: String {
        switch self {
        case .nessuna: return "Codice"
        case .faceID:  return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        }
    }

    public var simbolo: String {
        switch self {
        case .nessuna: return "lock"
        case .faceID:  return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        }
    }
}
