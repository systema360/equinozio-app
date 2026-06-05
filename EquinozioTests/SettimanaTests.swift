import Testing
import Foundation
@testable import Equinozio

struct SettimanaTests {
    private var calUTC: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    @Test func idStabilePerLaStessaSettimana() {
        let cal = calUTC
        let lun = cal.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let dom = cal.date(from: DateComponents(year: 2026, month: 6, day: 7))!
        #expect(Settimana.id(per: lun, calendario: cal) == Settimana.id(per: dom, calendario: cal))
    }
    @Test func idCambiaTraSettimaneDiverse() {
        let cal = calUTC
        let a = cal.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let b = cal.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        #expect(Settimana.id(per: a, calendario: cal) != Settimana.id(per: b, calendario: cal))
    }
}
