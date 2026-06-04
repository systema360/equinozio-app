//
//  GeneratoreInsight.swift
//  Equinozio · Domain
//
//  Trasforma i dati dell'utente (riflessioni, decisioni) in insight discreti
//  mostrati nella Mappa. Logica pura e deterministica · testabile in isolamento.
//

import Foundation

public struct InsightGenerato: Identifiable, Equatable {
    public let id = UUID()
    public let tipo: TipoInsight
    public let testo: String

    public init(tipo: TipoInsight, testo: String) {
        self.tipo = tipo
        self.testo = testo
    }

    public static func == (lhs: InsightGenerato, rhs: InsightGenerato) -> Bool {
        lhs.tipo == rhs.tipo && lhs.testo == rhs.testo
    }
}

public enum GeneratoreInsight {

    /// Genera fino a 3 insight, in ordine di priorità.
    /// - riflessioni: ordinate dalla più recente alla più vecchia.
    public static func genera(
        riflessioni: [Riflessione],
        decisioni: [Decisione],
        adesso: Date
    ) -> [InsightGenerato] {
        var risultato: [InsightGenerato] = []

        if let i = bilanciamentoBasso(riflessioni) { risultato.append(i) }
        if let i = dominanzaCerchio(riflessioni) { risultato.append(i) }
        if let i = crescitaTrend(riflessioni) { risultato.append(i) }
        if let i = decisioneStorica(decisioni, adesso: adesso) { risultato.append(i) }

        return Array(risultato.prefix(3))
    }

    // MARK: - Regole

    static func bilanciamentoBasso(_ riflessioni: [Riflessione]) -> InsightGenerato? {
        guard let ultima = riflessioni.first, ultima.equilibrio < 60 else { return nil }
        return InsightGenerato(
            tipo: .bilanciamentoBasso,
            testo: "Questa settimana il tuo equilibrio è \(ultima.equilibrio)%. Prova a riportare un po' di tempo verso i cerchi più trascurati."
        )
    }

    static func dominanzaCerchio(_ riflessioni: [Riflessione]) -> InsightGenerato? {
        guard let ultima = riflessioni.first else { return nil }
        let quote: [(TipoCerchio, Int)] = [
            (.passione, ultima.quotaPassione),
            (.talento, ultima.quotaTalento),
            (.missione, ultima.quotaMissione),
            (.professione, ultima.quotaProfessione),
        ]
        guard let dominante = quote.max(by: { $0.1 < $1.1 }), dominante.1 >= 50 else { return nil }
        return InsightGenerato(
            tipo: .dominanzaCerchio,
            testo: "Stai dedicando molto a \(dominante.0.titolo) (\(dominante.1)%). Va bene, se è una scelta consapevole."
        )
    }

    static func crescitaTrend(_ riflessioni: [Riflessione]) -> InsightGenerato? {
        guard riflessioni.count >= 2 else { return nil }
        let delta = riflessioni[0].equilibrio - riflessioni[1].equilibrio
        guard delta > 0 else { return nil }
        return InsightGenerato(
            tipo: .crescitaTrend,
            testo: "Il tuo equilibrio è in crescita: +\(delta) rispetto alla settimana scorsa."
        )
    }

    static func decisioneStorica(_ decisioni: [Decisione], adesso: Date) -> InsightGenerato? {
        let aperte = decisioni.filter { ($0.decisione ?? "").isEmpty }
        guard !aperte.isEmpty else { return nil }

        let limite = adesso.addingTimeInterval(7 * 86_400)
        let inScadenza = aperte.filter { d in
            guard let scadenza = d.scadenza else { return false }
            return scadenza <= limite
        }

        if !inScadenza.isEmpty {
            let n = inScadenza.count
            return InsightGenerato(
                tipo: .decisioneStorica,
                testo: "Hai \(n) decision\(n == 1 ? "e" : "i") in scadenza. Forse è il momento di chiuderne una."
            )
        }
        if aperte.count >= 3 {
            return InsightGenerato(
                tipo: .decisioneStorica,
                testo: "Hai \(aperte.count) decisioni aperte: rischi di accumularle."
            )
        }
        return nil
    }
}
