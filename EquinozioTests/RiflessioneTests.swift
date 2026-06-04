//
//  RiflessioneTests.swift
//  EquinozioTests
//

import Testing
import SwiftData
import Foundation
@testable import Equinozio

struct RiflessioneTests {

    @Test func equilibrioPerfetto() {
        #expect(Riflessione.equilibrio(passione: 25, talento: 25, missione: 25, professione: 25) == 100)
    }

    @Test func equilibrioSbilanciato() {
        // scarti [15,5,5,5] = 30, /4 = 7, 100 - 14 = 86
        #expect(Riflessione.equilibrio(passione: 40, talento: 20, missione: 20, professione: 20) == 86)
    }

    @Test func equilibrioEstremo() {
        // scarti [75,25,25,25] = 150, /4 = 37, 100 - 74 = 26
        #expect(Riflessione.equilibrio(passione: 100, talento: 0, missione: 0, professione: 0) == 26)
    }

    @Test func equilibrioNonNegativo() {
        #expect(Riflessione.equilibrio(passione: 100, talento: 0, missione: 0, professione: 0) >= 0)
    }

    @MainActor
    @Test func pensieroPersisteSuSwiftData() throws {
        let schema = Schema([Profilo.self, Cerchio.self, Elemento.self, Pagina.self, Riflessione.self, Decisione.self, Insight.self])
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        )
        let ctx = container.mainContext

        let r = Riflessione(data: .now, quotaPassione: 25, quotaTalento: 25, quotaMissione: 25, quotaProfessione: 25, pensiero: "Settimana intensa")
        ctx.insert(r)
        try ctx.save()

        let lette = try ctx.fetch(FetchDescriptor<Riflessione>())
        #expect(lette.count == 1)
        #expect(lette.first?.pensiero == "Settimana intensa")
    }

    @MainActor
    @Test func modificaQuotePersisteEAggiornaEquilibrio() throws {
        let schema = Schema([Profilo.self, Cerchio.self, Elemento.self, Pagina.self, Riflessione.self, Decisione.self, Insight.self])
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        )
        let ctx = container.mainContext

        let r = Riflessione(data: .now, quotaPassione: 70, quotaTalento: 10, quotaMissione: 10, quotaProfessione: 10)
        ctx.insert(r)
        try ctx.save()

        r.quotaPassione = 25; r.quotaTalento = 25; r.quotaMissione = 25; r.quotaProfessione = 25
        r.pensiero = "Riequilibrata"
        try ctx.save()

        let letta = try ctx.fetch(FetchDescriptor<Riflessione>()).first
        #expect(letta?.equilibrio == 100)
        #expect(letta?.pensiero == "Riequilibrata")
    }
}
