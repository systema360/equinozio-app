import Testing
import Foundation
import SwiftData
@testable import Equinozio

struct CancellazioneDatiTests {

    @MainActor
    private func nuovoContesto() throws -> ModelContext {
        let schema = Schema([
            Profilo.self, Cerchio.self, Elemento.self,
            Pagina.self, Riflessione.self, Decisione.self, Insight.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @MainActor
    @Test func cancellaTuttoSvuotaTuttiIModelli() throws {
        let contesto = try nuovoContesto()

        let cerchio = Cerchio(tipo: .passione)
        contesto.insert(Profilo(nome: "Test"))
        contesto.insert(cerchio)
        contesto.insert(Elemento(testo: "Scrivere", cerchio: cerchio))
        contesto.insert(Pagina(testo: "Una pagina di diario"))
        contesto.insert(Riflessione(pensiero: "Equilibrio"))
        contesto.insert(Decisione(titolo: "Una decisione"))
        contesto.insert(Insight(tipo: .crescitaTrend, testo: "Un insight"))
        try contesto.save()

        try CancellazioneDati.cancellaTutto(in: contesto)

        #expect(try contesto.fetchCount(FetchDescriptor<Profilo>()) == 0)
        #expect(try contesto.fetchCount(FetchDescriptor<Cerchio>()) == 0)
        #expect(try contesto.fetchCount(FetchDescriptor<Elemento>()) == 0)
        #expect(try contesto.fetchCount(FetchDescriptor<Pagina>()) == 0)
        #expect(try contesto.fetchCount(FetchDescriptor<Riflessione>()) == 0)
        #expect(try contesto.fetchCount(FetchDescriptor<Decisione>()) == 0)
        #expect(try contesto.fetchCount(FetchDescriptor<Insight>()) == 0)
    }

    @MainActor
    @Test func cancellaTuttoSuContestoVuotoNonFallisce() throws {
        let contesto = try nuovoContesto()
        try CancellazioneDati.cancellaTutto(in: contesto)
        #expect(try contesto.fetchCount(FetchDescriptor<Pagina>()) == 0)
    }
}
