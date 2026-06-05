import Testing
import Foundation
@testable import Equinozio

struct DeepLinkTests {
    @Test func mappaTutteLeSchede() {
        #expect(Scheda.fromDeepLink(URL(string: "equinozio://mappa")!) == .mappa)
        #expect(Scheda.fromDeepLink(URL(string: "equinozio://diario")!) == .diario)
        #expect(Scheda.fromDeepLink(URL(string: "equinozio://riflessione")!) == .riflessione)
        #expect(Scheda.fromDeepLink(URL(string: "equinozio://decisione")!) == .decisione)
    }
    @Test func schemaSbagliatoONulla() {
        #expect(Scheda.fromDeepLink(URL(string: "https://systema360.it")!) == nil)
        #expect(Scheda.fromDeepLink(URL(string: "equinozio://ignota")!) == nil)
    }
    @Test func fromHostMappaLeSchede() {
        #expect(Scheda.from(host: "riflessione") == .riflessione)
        #expect(Scheda.from(host: "mappa") == .mappa)
        #expect(Scheda.from(host: "ignota") == nil)
        #expect(Scheda.from(host: nil) == nil)
    }
    @Test func insightInstradaAllaScheda() {
        #expect(Scheda.perInsight(.bilanciamentoBasso) == .riflessione)
        #expect(Scheda.perInsight(.dominanzaCerchio) == .riflessione)
        #expect(Scheda.perInsight(.crescitaTrend) == .riflessione)
        #expect(Scheda.perInsight(.decisioneStorica) == .decisione)
    }
}
