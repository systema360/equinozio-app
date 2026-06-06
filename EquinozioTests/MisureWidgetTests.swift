import Testing
@testable import Equinozio

struct MisureWidgetTests {

    @Test func nessunaRiflessione() {
        let m = MisureWidget.deriva(equilibri: [], quotePrimo: nil)
        #expect(m.haRiflessioni == false)
        #expect(m.equilibrio == 50)
        #expect(m.haTrend == false)
        #expect(m.delta == 0)
    }

    @Test func unaRiflessioneNessunaTendenza() {
        let m = MisureWidget.deriva(
            equilibri: [70],
            quotePrimo: (passione: 40, talento: 30, missione: 20, professione: 10)
        )
        #expect(m.haRiflessioni == true)
        #expect(m.equilibrio == 70)
        #expect(m.haTrend == false)
        #expect(m.delta == 0)
        #expect(m.passione == 40)
        #expect(m.professione == 10)
    }

    @Test func dueRiflessioniDeltaPositivo() {
        let m = MisureWidget.deriva(
            equilibri: [75, 60],
            quotePrimo: (passione: 25, talento: 25, missione: 25, professione: 25)
        )
        #expect(m.haTrend == true)
        #expect(m.delta == 15)
        #expect(m.equilibrio == 75)
    }

    @Test func dueRiflessioniDeltaNegativo() {
        let m = MisureWidget.deriva(equilibri: [40, 55], quotePrimo: (10, 10, 10, 70))
        #expect(m.delta == -15)
    }

    @Test func frazioniSommanoCorrettamente() {
        let f = MisureWidget.frazioni(passione: 40, talento: 30, missione: 20, professione: 10)
        #expect(abs(f[0] - 0.4) < 0.0001)
        #expect(abs(f[1] - 0.3) < 0.0001)
        #expect(abs(f[2] - 0.2) < 0.0001)
        #expect(abs(f[3] - 0.1) < 0.0001)
    }

    @Test func frazioniTutteZeroNonDividePerZero() {
        let f = MisureWidget.frazioni(passione: 0, talento: 0, missione: 0, professione: 0)
        #expect(f == [0, 0, 0, 0])
    }

    @Test func frazioniNormalizzaSommaDiversaDa100() {
        let f = MisureWidget.frazioni(passione: 1, talento: 1, missione: 0, professione: 0)
        #expect(abs(f[0] - 0.5) < 0.0001)
        #expect(abs(f[1] - 0.5) < 0.0001)
    }
}
