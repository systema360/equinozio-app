//
//  RiassuntoDiario.swift
//  Equinozio · Domain
//
//  Riassunto settimanale del diario: selezione pura delle pagine + sintesi AI on-device.
//

import Foundation
import OSLog

#if canImport(FoundationModels)
import FoundationModels
#endif

public nonisolated enum RiassuntoDiario {
    /// Le pagine non cancellate appartenenti alla settimana di `adesso`.
    public static func pagineSettimana(
        _ pagine: [Pagina], adesso: Date, calendario: Calendar = .current
    ) -> [Pagina] {
        let sid = Settimana.id(per: adesso, calendario: calendario)
        return pagine.filter {
            !$0.isCancellata && Settimana.id(per: $0.dataCreazione, calendario: calendario) == sid
        }
    }

    /// Testo da dare al modello: privilegia le pagine più recenti fino a
    /// `massimoCaratteri`, poi le rimette in ordine cronologico. Il modello
    /// on-device ha una finestra di contesto limitata (~4096 token): meglio
    /// tagliare a monte che ricevere un errore di contesto.
    public static func testoPerRiassunto(_ pagine: [Pagina], massimoCaratteri: Int = 6000) -> String {
        var scelte: [Pagina] = []
        var totale = 0
        for p in pagine.sorted(by: { $0.dataCreazione > $1.dataCreazione }) {
            let lunghezza = p.testo.count + 5
            if totale + lunghezza > massimoCaratteri, !scelte.isEmpty { break }
            scelte.append(p)
            totale += lunghezza
        }
        let testo = scelte
            .sorted { $0.dataCreazione < $1.dataCreazione }
            .map(\.testo)
            .joined(separator: "\n---\n")
        return String(testo.prefix(massimoCaratteri))
    }
}

@MainActor
public final class RiassuntoDiarioService {
    public static let shared = RiassuntoDiarioService()
    private let log = Logger(subsystem: "it.systema360.equinozio", category: "RiassuntoDiario")
    private init() {}

    /// Riassume le pagine in 1-2 frasi. nil se non disponibile o nessuna pagina.
    public func riassumi(_ pagine: [Pagina]) async -> String? {
        guard !pagine.isEmpty else { return nil }
        if #available(iOS 26.0, macOS 26.0, *) {
            return await viaFoundationModels(pagine)
        }
        return nil
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private func viaFoundationModels(_ pagine: [Pagina]) async -> String? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }
        let testo = RiassuntoDiario.testoPerRiassunto(pagine)
        let istruzioni = """
        Sei la voce di Equinozio, un'app italiana calma. Ti do alcune note di diario
        di questa settimana. Riassumile in 1-2 frasi italiane, sobrie e gentili, in
        seconda persona, cogliendo i temi ricorrenti. Niente elenchi, niente emoji.
        """
        do {
            let sessione = LanguageModelSession(instructions: istruzioni)
            // Temperatura bassa (sintesi fedele) e tetto di token: l'output
            // atteso è di una o due frasi.
            let risposta = try await sessione.respond(
                to: testo,
                options: GenerationOptions(temperature: 0.3, maximumResponseTokens: 200)
            )
            let pulito = risposta.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return pulito.isEmpty ? nil : pulito
        } catch {
            log.warning("Riassunto AI fallito: \(String(describing: error))")
            return nil
        }
    }
    #else
    @available(iOS 26.0, macOS 26.0, *)
    private func viaFoundationModels(_ pagine: [Pagina]) async -> String? { nil }
    #endif
}
