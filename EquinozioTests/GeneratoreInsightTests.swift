import Testing
import Foundation
@testable import Equinozio

struct GeneratoreInsightTests {

    private func rifl(_ p: Int, _ t: Int, _ m: Int, _ s: Int, _ data: Date = .now) -> Riflessione {
        Riflessione(data: data, quotaPassione: p, quotaTalento: t, quotaMissione: m, quotaProfessione: s)
    }

    @Test func bilanciamentoBassoQuandoEquilibrioSottoSoglia() {
        let insight = GeneratoreInsight.genera(riflessioni: [rifl(70, 10, 10, 10)], decisioni: [], adesso: .now)
        #expect(insight.contains { $0.tipo == .bilanciamentoBasso })
    }

    @Test func nessunBilanciamentoBassoQuandoEquilibrato() {
        let insight = GeneratoreInsight.genera(riflessioni: [rifl(25, 25, 25, 25)], decisioni: [], adesso: .now)
        #expect(!insight.contains { $0.tipo == .bilanciamentoBasso })
    }

    @Test func dominanzaCerchioQuandoUnaQuotaAlta() {
        let insight = GeneratoreInsight.genera(riflessioni: [rifl(60, 20, 10, 10)], decisioni: [], adesso: .now)
        let dom = insight.first { $0.tipo == .dominanzaCerchio }
        #expect(dom != nil)
        #expect(dom?.testo.contains("Passione") == true)
    }

    @Test func nessunInsightSenzaRiflessioni() {
        let insight = GeneratoreInsight.genera(riflessioni: [], decisioni: [], adesso: .now)
        #expect(insight.isEmpty)
    }
}
