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
}
