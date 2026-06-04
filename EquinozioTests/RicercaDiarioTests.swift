import Testing
import Foundation
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
}
