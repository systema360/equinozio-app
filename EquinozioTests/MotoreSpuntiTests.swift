import Testing
import Foundation
@testable import Equinozio

struct MotoreSpuntiTests {
    private func rifl(_ p: Int, _ t: Int, _ m: Int, _ s: Int) -> Riflessione {
        Riflessione(data: .now, quotaPassione: p, quotaTalento: t, quotaMissione: m, quotaProfessione: s)
    }

    @Test func principaleEILaSituazioneTopDelleRegole() {
        let regole = GeneratoreInsight.genera(riflessioni: [rifl(70, 10, 10, 10)], decisioni: [], adesso: .now)
        let principale = MotoreSpunti.principale(riflessioni: [rifl(70, 10, 10, 10)], decisioni: [], adesso: .now)
        #expect(principale?.tipo == regole.first?.tipo)
    }

    @Test func principaleNilSenzaDati() {
        #expect(MotoreSpunti.principale(riflessioni: [], decisioni: [], adesso: .now) == nil)
    }

    @Test func spuntiMappaMettonoLaCacheInTesta() {
        let cache = InsightGenerato(tipo: .crescitaTrend, testo: "AI: stai migliorando")
        let regole = [
            InsightGenerato(tipo: .bilanciamentoBasso, testo: "r1"),
            InsightGenerato(tipo: .crescitaTrend, testo: "r2"),
            InsightGenerato(tipo: .dominanzaCerchio, testo: "r3"),
        ]
        let out = MotoreSpunti.spuntiMappa(principale: cache, regole: regole)
        #expect(out.first?.testo == "AI: stai migliorando")
        #expect(out.filter { $0.tipo == .crescitaTrend }.count == 1)
        #expect(out.count <= 3)
    }

    @Test func spuntiMappaSenzaCacheUsanoLeRegole() {
        let regole = [InsightGenerato(tipo: .bilanciamentoBasso, testo: "r1")]
        #expect(MotoreSpunti.spuntiMappa(principale: nil, regole: regole).count == 1)
    }
}
