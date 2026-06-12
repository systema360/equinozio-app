//
//  TagSuggestionService.swift
//  Equinozio · Domain
//
//  Suggerisce le etichette (cerchi) per una pagina del diario.
//  · Foundation Models on-device (iOS 26+) se Apple Intelligence è attiva.
//  · Fallback euristico keyword-based (sempre disponibile).
//

import Foundation
import OSLog

#if canImport(FoundationModels)
import FoundationModels

/// Tipi a generazione guidata: vincolano l'output del modello ai soli
/// valori validi, senza passare da JSON in testo libero.
@available(iOS 26.0, macOS 26.0, *)
@Generable
fileprivate enum CerchioGenerabile: String {
    case passione, talento, missione, professione
}

@available(iOS 26.0, macOS 26.0, *)
@Generable
fileprivate struct EtichetteGenerate {
    @Guide(description: "Da uno a tre cerchi pertinenti, il più rilevante per primo.")
    var cerchi: [CerchioGenerabile]
}
#endif

@MainActor
public final class TagSuggestionService {

    public static let shared = TagSuggestionService()
    private let log = Logger(subsystem: "it.systema360.equinozio", category: "TagSuggestion")

    private init() {}

    /// Suggerisce da 1 a 3 etichette per il testo dato.
    /// Garantisce sempre almeno 1 risultato per un testo non vuoto.
    public func suggerisci(per testo: String) async -> [TipoCerchio] {
        let testoPulito = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard testoPulito.count >= 3 else { return [] }

        // 1 · Foundation Models on-device
        if #available(iOS 26.0, macOS 26.0, *) {
            if let dalModello = await tramiteFoundationModels(testoPulito), !dalModello.isEmpty {
                log.info("Etichette da Foundation Models: \(dalModello.map(\.rawValue).joined(separator: ","))")
                return dalModello
            }
            log.info("Foundation Models non disponibile o nessun risultato · uso euristico")
        }

        // 2 · Fallback euristico (sempre)
        let dallaEuristica = euristica(testoPulito)
        log.info("Etichette euristiche: \(dallaEuristica.map(\.rawValue).joined(separator: ","))")
        return dallaEuristica
    }

    // MARK: - Foundation Models

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private func tramiteFoundationModels(_ testo: String) async -> [TipoCerchio]? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }

        let istruzioni = """
        Sei un assistente per Equinozio, un'app italiana sul metodo dei quattro cerchi.

        I quattro cerchi sono:
        - passione: ciò che la persona ama fare
        - talento: ciò in cui è naturalmente brava
        - missione: ciò che serve agli altri / al mondo
        - professione: ciò per cui è pagata oggi

        L'utente ti darà una riflessione di diario. Indica da 1 a 3 cerchi a cui
        appartiene, il più rilevante per primo.
        """

        do {
            let sessione = LanguageModelSession(instructions: istruzioni)
            // Generazione guidata: l'output può contenere SOLO i quattro valori
            // dell'enum, niente parsing di testo libero. Campionamento greedy
            // per risultati deterministici a parità di testo.
            let risposta = try await sessione.respond(
                to: testo,
                generating: EtichetteGenerate.self,
                options: GenerationOptions(sampling: .greedy)
            )
            var visti = Set<TipoCerchio>()
            let tipi = risposta.content.cerchi
                .compactMap { TipoCerchio(rawValue: $0.rawValue) }
                .filter { visti.insert($0).inserted }
            return Array(tipi.prefix(3))
        } catch {
            log.warning("Foundation Models error: \(String(describing: error))")
            return nil
        }
    }
    #else
    @available(iOS 26.0, macOS 26.0, *)
    private func tramiteFoundationModels(_ testo: String) async -> [TipoCerchio]? {
        return nil
    }
    #endif

    // MARK: - Fallback euristico

    private func euristica(_ testo: String) -> [TipoCerchio] {
        let t = testo.lowercased()
        var punteggi: [TipoCerchio: Int] = [:]

        for (tipo, parole) in Self.segnali {
            var n = 0
            for parola in parole {
                if t.range(of: parola, options: [.diacriticInsensitive, .regularExpression]) != nil {
                    n += 1
                }
            }
            if n > 0 {
                punteggi[tipo] = n
            }
        }

        // Ordina per punteggio decrescente, prendi max 3
        let ordinati = punteggi
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map(\.key)

        // Se niente ha matchato, suggerisco passione (default ragionevole per riflessione personale)
        return ordinati.isEmpty ? [.passione] : Array(ordinati)
    }

    /// Dizionario keyword per ciascun cerchio. Usa regex con `\b...\b` per match parola intera.
    private static let segnali: [TipoCerchio: [String]] = [
        .passione: [
            #"\bam[oa]\b"#, #"\bam(ato|are)\b"#,
            #"\bpiace\b"#, #"\bpiaciuto\b"#,
            #"\b(diverte|divertito|divertita)\b"#,
            #"\bfelic[ei]\b"#, #"\benergia\b"#,
            #"\bappassion(a|ato|ata|ano)\b"#,
            #"\bgioia\b"#, #"\bcarico\b"#, #"\bcarica\b"#,
            #"\bentusiasm[oi]\b"#, #"\bpassion[ei]\b"#,
            #"\b(volat[oa]|tempo è volato)\b"#,
            #"\bmi sento (bene|vivo|viva)\b"#,
            #"\bvoglio\b"#, #"\bdesider[oa]\b"#,
            #"\bcontento|contenta\b"#,
            #"\bhobby\b"#, #"\binteresse|interessa\b"#,
        ],
        .talento: [
            #"\bbrav[oa]\b"#, #"\b(bravo|brava) (a|in|nel|nella)\b"#,
            #"\briusc(ito|ita|ire|ito|ita|iva)\b"#,
            #"\b(mi riesce|mi viene)\b"#,
            #"\b(chiesto aiuto|chiesto consiglio)\b"#,
            #"\besperienza|esperto|esperta\b"#,
            #"\bcompetent[ei]|competenza\b"#,
            #"\btalent[oi]|talentuos[oa]\b"#,
            #"\babile|abilità\b"#,
            #"\bmaestria\b"#,
            #"\bsono (capace|in grado)\b"#,
            #"\binsegn(o|ato|are|ata|avo)\b"#,
            #"\bspiega(re|to|ta|vo)\b"#,
            #"\bcost(ruir[oe]|ruito|ruita)\b"#,
            #"\b(progett[oa]|progettato)\b"#,
        ],
        .missione: [
            #"\baiut(o|are|ato|ata|i)\b"#,
            #"\b(serve|servire|serv[oi]to)\b"#,
            #"\butile|utili\b"#,
            #"\bcomunit[àa]\b"#, #"\bfamiglia\b"#,
            #"\bmondo\b"#, #"\bpersone\b"#,
            #"\bvolontariato\b"#, #"\bvolontario\b"#,
            #"\bbisogn[oi]|bisognos[oa]\b"#,
            #"\bcontribu(ire|ito|ita|isco|isce)\b"#,
            #"\b(impegn[oa]|impegnato|impegnata)\b"#,
            #"\b(ragazz[ie]|bambin[ie]|anzian[ie])\b"#,
            #"\bsociale|sociali\b"#,
            #"\b(causa|missione)\b"#,
            #"\bdiritti\b"#, #"\bambiente\b"#,
            #"\b(scuola|scuole|studenti)\b"#,
        ],
        .professione: [
            #"\blavor(o|are|ato|ata|avo|i)\b"#,
            #"\b(client[ei]|capo|collega|collega)\b"#,
            #"\b(ufficio|riunione|riunioni)\b"#,
            #"\bstipendio|salario\b"#,
            #"\b(manager|direttore|dirigente)\b"#,
            #"\bincari(co|chi|cato|cata)\b"#,
            #"\bprofession(e|ale|ista)\b"#,
            #"\b(mestiere|carriera)\b"#,
            #"\b(deadline|consegna|consegnato)\b"#,
            #"\b(progett[oa] di lavoro|progetto aziendale)\b"#,
            #"\bbusiness\b"#, #"\bazienda\b"#,
            #"\b(impieg[oa]|impegnato lavorat)\b"#,
            #"\bmail|email\b"#,
            #"\bcommerciale\b"#,
        ],
    ]
}
