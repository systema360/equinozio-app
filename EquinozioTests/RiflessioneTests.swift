//
//  RiflessioneTests.swift
//  EquinozioTests
//

import Testing
import SwiftData
@testable import Equinozio

struct RiflessioneTests {

    @Test func equilibrioPerfetto() {
        #expect(Riflessione.equilibrio(passione: 25, talento: 25, missione: 25, professione: 25) == 100)
    }

    @Test func equilibrioSbilanciato() {
        // scarti [15,5,5,5] = 30, /4 = 7, 100 - 14 = 86
        #expect(Riflessione.equilibrio(passione: 40, talento: 20, missione: 20, professione: 20) == 86)
    }

    @Test func equilibrioEstremo() {
        // scarti [75,25,25,25] = 150, /4 = 37, 100 - 74 = 26
        #expect(Riflessione.equilibrio(passione: 100, talento: 0, missione: 0, professione: 0) == 26)
    }

    @Test func equilibrioNonNegativo() {
        #expect(Riflessione.equilibrio(passione: 100, talento: 0, missione: 0, professione: 0) >= 0)
    }
}
