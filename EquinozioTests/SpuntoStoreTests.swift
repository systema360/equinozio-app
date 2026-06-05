import Testing
import Foundation
import SwiftData
@testable import Equinozio

struct SpuntoStoreTests {
    @Test func esisteSpuntoRiconosceLaSettimana() {
        let i = Insight(tipo: .crescitaTrend, testo: "x")
        i.settimanaID = "2026-W23"
        #expect(SpuntoStore.esisteSpunto(per: "2026-W23", in: [i]))
        #expect(!SpuntoStore.esisteSpunto(per: "2026-W24", in: [i]))
        #expect(!SpuntoStore.esisteSpunto(per: "2026-W23", in: []))
    }

    @MainActor
    @Test func rigeneraScriveUnInsightDellaSettimana() async throws {
        let schema = Schema([Profilo.self, Cerchio.self, Elemento.self, Pagina.self, Riflessione.self, Decisione.self, Insight.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let ctx = container.mainContext
        ctx.insert(Riflessione(data: .now, quotaPassione: 70, quotaTalento: 10, quotaMissione: 10, quotaProfessione: 10))
        try ctx.save()

        await SpuntoStore.rigenera(contesto: ctx, adesso: .now)

        let insights = try ctx.fetch(FetchDescriptor<Insight>())
        #expect(insights.count == 1)
        #expect(!(insights.first?.testo.isEmpty ?? true))
        #expect(insights.first?.settimanaID == Settimana.id(per: .now))
    }
}
