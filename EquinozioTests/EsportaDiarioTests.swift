import Testing
import Foundation
@testable import Equinozio

struct EsportaDiarioTests {

    @Test func esportaVuoto() {
        #expect(EsportaDiario.testo(da: []) == "")
    }

    @Test func esportaIncludeTestoEtichette() {
        let p = Pagina(testo: "Giornata piena", etichette: [.passione], dataCreazione: Date(timeIntervalSince1970: 0))
        let out = EsportaDiario.testo(da: [p])
        #expect(out.contains("Giornata piena"))
        #expect(out.contains("Passione"))
    }

    @Test func esportaSeparaLePagine() {
        let p1 = Pagina(testo: "Uno", dataCreazione: Date(timeIntervalSince1970: 0))
        let p2 = Pagina(testo: "Due", dataCreazione: Date(timeIntervalSince1970: 100))
        let out = EsportaDiario.testo(da: [p1, p2])
        #expect(out.contains("Uno"))
        #expect(out.contains("Due"))
        #expect(out.contains("———"))
    }
}
