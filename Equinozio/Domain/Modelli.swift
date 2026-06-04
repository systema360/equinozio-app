//
//  Modelli.swift
//  Equinozio · Domain
//
//  Schema SwiftData. Sette entità tutte sincronizzate via CloudKit privato.
//
//  ⚠️  CloudKit richiede che ogni attributo abbia un default value
//      e che le relazioni siano opzionali. Tutti i model qui rispettano
//      questo vincolo.
//

import Foundation
import SwiftData

// MARK: - Profilo

@Model
public final class Profilo {
    public var nome: String = ""
    public var dataCreazione: Date = Date.distantPast
    public var lingua: String = "it"

    public init(nome: String = "", lingua: String = "it") {
        self.nome = nome
        self.dataCreazione = .now
        self.lingua = lingua
    }
}

// MARK: - Cerchio

@Model
public final class Cerchio {
    public var tipoRaw: String = TipoCerchio.passione.rawValue
    @Relationship(deleteRule: .cascade, inverse: \Elemento.cerchio)
    public var elementi: [Elemento]? = []

    public var tipo: TipoCerchio {
        get { TipoCerchio(rawValue: tipoRaw) ?? .passione }
        set { tipoRaw = newValue.rawValue }
    }

    public init(tipo: TipoCerchio) {
        self.tipoRaw = tipo.rawValue
    }
}

// MARK: - Elemento

@Model
public final class Elemento {
    public var testo: String = ""
    public var dataAggiunta: Date = Date.distantPast
    public var cerchio: Cerchio?

    public init(testo: String, cerchio: Cerchio? = nil) {
        self.testo = testo
        self.dataAggiunta = .now
        self.cerchio = cerchio
    }
}

// MARK: - Pagina (entry del diario)

@Model
public final class Pagina {
    public var testo: String = ""
    public var dataCreazione: Date = Date.distantPast
    public var etichetteRaw: [String] = []
    public var isCancellata: Bool = false

    public var etichette: Set<TipoCerchio> {
        get { Set(etichetteRaw.compactMap { TipoCerchio(rawValue: $0) }) }
        set { etichetteRaw = newValue.map(\.rawValue) }
    }

    public init(
        testo: String,
        etichette: Set<TipoCerchio> = [],
        dataCreazione: Date = .now
    ) {
        self.testo = testo
        self.dataCreazione = dataCreazione
        self.etichetteRaw = etichette.map(\.rawValue)
        self.isCancellata = false
    }
}

// MARK: - Riflessione (check-in settimanale)

@Model
public final class Riflessione {
    public var data: Date = Date.distantPast
    public var quotaPassione: Int = 25
    public var quotaTalento: Int = 25
    public var quotaMissione: Int = 25
    public var quotaProfessione: Int = 25
    public var pensiero: String = ""

    public init(
        data: Date = .now,
        quotaPassione: Int = 25,
        quotaTalento: Int = 25,
        quotaMissione: Int = 25,
        quotaProfessione: Int = 25,
        pensiero: String = ""
    ) {
        self.data = data
        self.quotaPassione = quotaPassione
        self.quotaTalento = quotaTalento
        self.quotaMissione = quotaMissione
        self.quotaProfessione = quotaProfessione
        self.pensiero = pensiero
    }

    public var equilibrio: Int {
        Riflessione.equilibrio(
            passione: quotaPassione,
            talento: quotaTalento,
            missione: quotaMissione,
            professione: quotaProfessione
        )
    }

    /// Formula dell'equilibrio: 100 meno il doppio dello scarto medio da 25/25/25/25.
    public static func equilibrio(passione: Int, talento: Int, missione: Int, professione: Int) -> Int {
        let scarti = [passione, talento, missione, professione].map { abs($0 - 25) }
        let scartoMedio = scarti.reduce(0, +) / 4
        return max(0, 100 - scartoMedio * 2)
    }
}

// MARK: - Decisione

@Model
public final class Decisione {
    public var titolo: String = ""
    public var dataAggiunta: Date = Date.distantPast
    public var scadenza: Date?
    public var punteggioPassione: Int = 3
    public var punteggioTalento: Int = 3
    public var punteggioMissione: Int = 3
    public var punteggioProfessione: Int = 3
    public var note: String = ""
    public var decisione: String?

    public init(
        titolo: String,
        scadenza: Date? = nil,
        punteggi: (p: Int, t: Int, m: Int, s: Int) = (3, 3, 3, 3),
        note: String = ""
    ) {
        self.titolo = titolo
        self.dataAggiunta = .now
        self.scadenza = scadenza
        self.punteggioPassione = punteggi.p
        self.punteggioTalento = punteggi.t
        self.punteggioMissione = punteggi.m
        self.punteggioProfessione = punteggi.s
        self.note = note
    }

    public var punteggioMedio: Double {
        Double(punteggioPassione + punteggioTalento + punteggioMissione + punteggioProfessione) / 4.0
    }

    public var punteggioFormattato: String {
        String(format: "%.2f", punteggioMedio).replacingOccurrences(of: ".", with: ",")
    }
}

// MARK: - Insight (cache locale dei pattern)

@Model
public final class Insight {
    public var tipoRaw: String = TipoInsight.bilanciamentoBasso.rawValue
    public var testo: String = ""
    public var dataGenerazione: Date = Date.distantPast

    public var tipo: TipoInsight {
        TipoInsight(rawValue: tipoRaw) ?? .bilanciamentoBasso
    }

    public init(tipo: TipoInsight, testo: String) {
        self.tipoRaw = tipo.rawValue
        self.testo = testo
        self.dataGenerazione = .now
    }
}

public enum TipoInsight: String, Codable, Sendable {
    case bilanciamentoBasso
    case dominanzaCerchio
    case crescitaTrend
    case decisioneStorica
}
