import Testing
@testable import Equinozio

@Suite(.serialized)
struct WidgetSnapshotTests {

    @Test func roundTripMisure() {
        let m = MisureWidget(
            equilibrio: 75, passione: 40, talento: 30, missione: 20,
            professione: 10, delta: 15, haTrend: true, haRiflessioni: true
        )
        WidgetSnapshot.aggiornaMisure(m)
        #expect(WidgetSnapshot.leggiMisure() == m)
    }

    @Test func aggiornaCompletoScriveMisureESpunto() {
        let m = MisureWidget(
            equilibrio: 60, passione: 25, talento: 25, missione: 25,
            professione: 25, delta: 0, haTrend: false, haRiflessioni: true
        )
        WidgetSnapshot.aggiorna(misure: m, spuntoTesto: "Ciao", spuntoTipo: "test", settimanaID: "2026-W23")
        let letto = WidgetSnapshot.leggiMisure()
        #expect(letto.equilibrio == 60)
        #expect(letto.haRiflessioni == true)
        #expect(WidgetSnapshot.leggiSpunto() == "Ciao")
    }
}
