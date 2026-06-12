import Testing
import Foundation
@testable import Equinozio

struct RiassuntoDiarioTests {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        c.firstWeekday = 2
        return c
    }

    @Test func soloPagineDellaSettimanaNonCancellate() {
        let c = cal
        let oggi = c.date(from: DateComponents(year: 2026, month: 6, day: 3))!
        let inSettimana = c.date(from: DateComponents(year: 2026, month: 6, day: 2))!
        let settimanaScorsa = c.date(from: DateComponents(year: 2026, month: 5, day: 20))!

        let p1 = Pagina(testo: "questa settimana", dataCreazione: inSettimana)
        let p2 = Pagina(testo: "vecchia", dataCreazione: settimanaScorsa)
        let p3 = Pagina(testo: "cancellata", dataCreazione: oggi)
        p3.isCancellata = true

        let out = RiassuntoDiario.pagineSettimana([p1, p2, p3], adesso: oggi, calendario: c)
        #expect(out.count == 1)
        #expect(out.first?.testo == "questa settimana")
    }

    @Test func vuotoSeNessunaPaginaInSettimana() {
        let c = cal
        let oggi = c.date(from: DateComponents(year: 2026, month: 6, day: 3))!
        let vecchia = Pagina(testo: "x", dataCreazione: c.date(from: DateComponents(year: 2026, month: 1, day: 1))!)
        #expect(RiassuntoDiario.pagineSettimana([vecchia], adesso: oggi, calendario: c).isEmpty)
    }

    @Test func testoPerRiassuntoRispettaIlLimiteEPreferisceLeRecenti() {
        let c = cal
        let vecchia = Pagina(testo: String(repeating: "v", count: 4000), dataCreazione: c.date(from: DateComponents(year: 2026, month: 6, day: 1))!)
        let recente = Pagina(testo: String(repeating: "r", count: 4000), dataCreazione: c.date(from: DateComponents(year: 2026, month: 6, day: 3))!)

        let out = RiassuntoDiario.testoPerRiassunto([vecchia, recente], massimoCaratteri: 4100)
        #expect(out.contains("r"))
        #expect(!out.contains("v"))
        #expect(out.count <= 4100)
    }

    @Test func testoPerRiassuntoInOrdineCronologico() {
        let c = cal
        let p1 = Pagina(testo: "prima", dataCreazione: c.date(from: DateComponents(year: 2026, month: 6, day: 1))!)
        let p2 = Pagina(testo: "dopo", dataCreazione: c.date(from: DateComponents(year: 2026, month: 6, day: 3))!)
        #expect(RiassuntoDiario.testoPerRiassunto([p2, p1]) == "prima\n---\ndopo")
    }
}
