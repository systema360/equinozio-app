import Testing
import Foundation
@testable import Equinozio

struct PromemoriaTests {

    private var calendarioUTC: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    @Test func prossimaDataRispettaGiornoEOra() throws {
        let cal = calendarioUTC
        let da = cal.date(from: DateComponents(year: 2026, month: 6, day: 4, hour: 12))!
        let prossima = try #require(PromemoriaService.prossimaData(giorno: 1, ora: 19, minuto: 0, da: da, calendario: cal))
        #expect(prossima > da)
        #expect(cal.component(.weekday, from: prossima) == 1)
        #expect(cal.component(.hour, from: prossima) == 19)
        #expect(cal.component(.minute, from: prossima) == 0)
    }

    @Test func prossimaDataSempreFutura() throws {
        let cal = calendarioUTC
        let da = cal.date(from: DateComponents(year: 2026, month: 6, day: 7, hour: 20))!
        let prossima = try #require(PromemoriaService.prossimaData(giorno: 1, ora: 19, minuto: 0, da: da, calendario: cal))
        #expect(prossima > da)
    }

    @Test func corpoUsaLoSpuntoSePresente() {
        #expect(PromemoriaService.corpo(spunto: "Stai migliorando", personalizzato: "fallback") == "Stai migliorando")
    }
    @Test func corpoFallbackSeSpuntoVuotoONil() {
        #expect(PromemoriaService.corpo(spunto: nil, personalizzato: "fallback") == "fallback")
        #expect(PromemoriaService.corpo(spunto: "", personalizzato: "fallback") == "fallback")
        #expect(PromemoriaService.corpo(spunto: "   ", personalizzato: "fallback") == "fallback")
    }
}
