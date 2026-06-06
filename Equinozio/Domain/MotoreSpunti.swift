//
//  MotoreSpunti.swift
//  Equinozio · Domain
//
//  Sceglie la situazione principale (regole, pura) e ne produce il testo finale:
//  su iOS 26 i Foundation Models riscrivono la frase-regola in modo più caldo
//  (stessi fatti e numeri); altrimenti si usa la frase a regole.
//

import Foundation
import OSLog

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
public final class MotoreSpunti {

    public static let shared = MotoreSpunti()
    private let log = Logger(subsystem: "it.systema360.equinozio", category: "MotoreSpunti")
    private init() {}

    /// Riscrittura del testo (default: Foundation Models). Sostituibile nei test.
    var riscrittore: (String) async -> String? = { frase in
        await MotoreSpunti.riscritturaPredefinita(frase)
    }

    /// Factory per i test: crea un'istanza con un riscrittore finto.
    static func perTest(riscrittore: @escaping (String) async -> String?) -> MotoreSpunti {
        let m = MotoreSpunti()
        m.riscrittore = riscrittore
        return m
    }

    // MARK: - Parte pura (regole)

    nonisolated public static func principale(
        riflessioni: [Riflessione], decisioni: [Decisione], adesso: Date
    ) -> InsightGenerato? {
        GeneratoreInsight.genera(riflessioni: riflessioni, decisioni: decisioni, adesso: adesso).first
    }

    nonisolated public static func spuntiMappa(
        principale: InsightGenerato?, regole: [InsightGenerato]
    ) -> [InsightGenerato] {
        guard let principale else { return regole }
        let altre = regole.filter { $0.tipo != principale.tipo }
        return Array(([principale] + altre).prefix(3))
    }

    // MARK: - Testo finale (AI o regola)

    public func spuntoPrincipale(
        riflessioni: [Riflessione], decisioni: [Decisione], adesso: Date
    ) async -> InsightGenerato? {
        guard let base = Self.principale(riflessioni: riflessioni, decisioni: decisioni, adesso: adesso) else {
            return nil
        }
        let testo = await testoCaldo(per: base.testo)
        return InsightGenerato(tipo: base.tipo, testo: testo)
    }

    private func testoCaldo(per fraseRegola: String) async -> String {
        if let riscritta = await riscrittore(fraseRegola), !riscritta.isEmpty {
            return riscritta
        }
        return fraseRegola
    }

    // MARK: - Riscrittura predefinita (Foundation Models)

    nonisolated static func riscritturaPredefinita(_ frase: String) async -> String? {
        if #available(iOS 26.0, macOS 26.0, *) {
            return await _riscritturaPredefinitaDisponibile(frase)
        }
        return nil
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private nonisolated static func _riscritturaPredefinitaDisponibile(_ frase: String) async -> String? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }
        let log = Logger(subsystem: "it.systema360.equinozio", category: "MotoreSpunti")
        let istruzioni = """
        Sei la voce di Equinozio, un'app italiana calma sul metodo dei quattro cerchi.
        Ti do una frase già corretta nei fatti e nei numeri. Riscrivila in UNA frase
        italiana, sobria e gentile, in seconda persona. NON cambiare i numeri né i fatti,
        non aggiungerne di nuovi. Niente emoji, niente virgolette, una sola frase.
        """
        do {
            let sessione = LanguageModelSession(instructions: istruzioni)
            let risposta = try await sessione.respond(to: frase)
            return risposta.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            log.warning("Riscrittura AI fallita: \(error.localizedDescription)")
            return nil
        }
    }
    #else
    @available(iOS 26.0, macOS 26.0, *)
    private nonisolated static func _riscritturaPredefinitaDisponibile(_ frase: String) async -> String? { nil }
    #endif
}
