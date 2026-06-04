import Testing
import Foundation
import SwiftData
@testable import Equinozio

struct RicercaDiarioTests {

    private func pagina(_ testo: String, _ etichette: Set<TipoCerchio> = []) -> Pagina {
        Pagina(testo: testo, etichette: etichette)
    }

    @Test func ricercaVuotaRestituisceTutto() {
        let pagine = [pagina("alfa"), pagina("beta")]
        #expect(RicercaDiario.filtra(pagine, cerchio: nil, ricerca: "").count == 2)
    }

    @Test func ricercaPerParolaChiaveCaseInsensitive() {
        let pagine = [pagina("Ho corso al parco"), pagina("Letto un libro")]
        let r = RicercaDiario.filtra(pagine, cerchio: nil, ricerca: "CORSO")
        #expect(r.count == 1)
        #expect(r.first?.testo == "Ho corso al parco")
    }

    @Test func ricercaCombinataConCerchio() {
        let a = pagina("corsa mattutina", [.passione])
        let b = pagina("corsa in ufficio", [.professione])
        let r = RicercaDiario.filtra([a, b], cerchio: .passione, ricerca: "corsa")
        #expect(r.count == 1)
        #expect(r.first?.testo == "corsa mattutina")
    }

    @Test func soloCerchioSenzaParola() {
        let a = pagina("x", [.passione])
        let b = pagina("y", [.talento])
        #expect(RicercaDiario.filtra([a, b], cerchio: .talento, ricerca: "").count == 1)
    }

    @MainActor
    @Test func ripristinoEscludeERiportaLaPagina() throws {
        let schema = Schema([Profilo.self, Cerchio.self, Elemento.self, Pagina.self, Riflessione.self, Decisione.self, Insight.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let ctx = container.mainContext
        let p = Pagina(testo: "da cancellare")
        ctx.insert(p); try ctx.save()

        p.isCancellata = true; try ctx.save()
        let attive1 = try ctx.fetch(FetchDescriptor<Pagina>(predicate: #Predicate { !$0.isCancellata }))
        #expect(attive1.isEmpty)

        p.isCancellata = false; try ctx.save()
        let attive2 = try ctx.fetch(FetchDescriptor<Pagina>(predicate: #Predicate { !$0.isCancellata }))
        #expect(attive2.count == 1)
    }
}
