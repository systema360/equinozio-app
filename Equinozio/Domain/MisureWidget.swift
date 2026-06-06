//
//  MisureWidget.swift
//  Equinozio · Domain
//
//  Stato numerico mostrato dal widget (equilibrio, quote dei cerchi, tendenza).
//  Tipo valore puro: costruito dall'app, serializzato in App Group, testato.
//

import Foundation

public nonisolated struct MisureWidget: Equatable, Sendable {
    public var equilibrio: Int
    public var passione: Int
    public var talento: Int
    public var missione: Int
    public var professione: Int
    public var delta: Int
    public var haTrend: Bool
    public var haRiflessioni: Bool

    public init(equilibrio: Int, passione: Int, talento: Int, missione: Int,
                professione: Int, delta: Int, haTrend: Bool, haRiflessioni: Bool) {
        self.equilibrio = equilibrio
        self.passione = passione
        self.talento = talento
        self.missione = missione
        self.professione = professione
        self.delta = delta
        self.haTrend = haTrend
        self.haRiflessioni = haRiflessioni
    }

    /// Stato di default quando non c'è ancora alcuna riflessione.
    public static let vuoto = MisureWidget(
        equilibrio: 50, passione: 0, talento: 0, missione: 0,
        professione: 0, delta: 0, haTrend: false, haRiflessioni: false
    )

    /// Deriva le misure dalle riflessioni ordinate dalla più recente.
    /// - equilibri: valori di equilibrio, indice 0 = più recente.
    /// - quotePrimo: quote della riflessione più recente (nil se nessuna).
    public static func deriva(
        equilibri: [Int],
        quotePrimo: (passione: Int, talento: Int, missione: Int, professione: Int)?
    ) -> MisureWidget {
        let q = quotePrimo ?? (0, 0, 0, 0)
        return MisureWidget(
            equilibrio: equilibri.first ?? 50,
            passione: q.passione,
            talento: q.talento,
            missione: q.missione,
            professione: q.professione,
            delta: equilibri.count >= 2 ? equilibri[0] - equilibri[1] : 0,
            haTrend: equilibri.count >= 2,
            haRiflessioni: !equilibri.isEmpty
        )
    }

    /// Frazioni (somma 1.0) delle quattro quote, per dimensionare le barre.
    /// Normalizza difensivamente; ritorna zeri se la somma è 0.
    public static func frazioni(passione: Int, talento: Int, missione: Int, professione: Int) -> [Double] {
        let v = [passione, talento, missione, professione].map { max(0, $0) }
        let somma = v.reduce(0, +)
        guard somma > 0 else { return [0, 0, 0, 0] }
        return v.map { Double($0) / Double(somma) }
    }
}
