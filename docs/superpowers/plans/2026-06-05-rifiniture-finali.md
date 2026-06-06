# Rifiniture finali (chip + cose rimaste) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Chiudere i due chip in sospeso (rifiniture interazioni + rifiniture Fase A Spunto) e i follow-up rimasti dell'app: conferme prima delle cancellazioni irrecuperabili, accessibilità, query Insight efficienti, freschezza widget, dedup DateFormatter, test del fallback AI.

**Architecture:** Per lo più rifiniture mirate verificate via build; due pezzi con unit test (pruning/freschezza pura, fallback AI iniettabile).

**Tech Stack:** SwiftUI, SwiftData, FoundationModels, Swift Testing. Lavorare su `main`.

**Fuori scope (motivato):** widget interattivo con bottone AppIntent — richiede condividere il tipo Intent col target widget (chirurgia pbxproj cross-target, rischiosa); il tap del widget fa già deep link. Resta un follow-up separato.

## Convenzioni
- **Test:** `xcodebuild test -scheme Equinozio -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:EquinozioTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`
- **Build:** `xcodebuild -scheme Equinozio -destination 'generic/platform=iOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -4` → `** BUILD SUCCEEDED **`
- Rileggere i file prima di editare (edit paralleli) e adattare. Token di design; niente bold.

---

## Task 1: Conferma prima di cancellare nello Storico (dati irrecuperabili)

**Files:** `Equinozio/Features/Riflessione/StoricoRiflessioniView.swift`.

Lo swipe "Cancella" fa hard-delete di una riflessione (irrecuperabile) senza conferma.

- [ ] **Step 1:** aggiungi stato `@State private var daCancellare: Riflessione?` in `StoricoRiflessioniView`.
- [ ] **Step 2:** nello swipe trailing, invece di chiamare `cancella(r)` direttamente, imposta `daCancellare = r`:
```swift
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { daCancellare = r } label: {
                                    Label("Cancella", systemImage: "trash")
                                }
                            }
```
- [ ] **Step 3:** aggiungi il dialog di conferma sul `List` (accanto a `.sheet(item: $inModifica)`):
```swift
            .confirmationDialog(
                "Cancellare questa riflessione?",
                isPresented: Binding(get: { daCancellare != nil }, set: { if !$0 { daCancellare = nil } }),
                presenting: daCancellare,
                titleVisibility: .visible
            ) { r in
                Button("Cancella", role: .destructive) { cancella(r); daCancellare = nil }
                Button("Annulla", role: .cancel) { daCancellare = nil }
            } message: { _ in
                Text("L'azione non è reversibile.")
            }
```
- [ ] **Step 4:** Build → BUILD SUCCEEDED. Test → verde.
- [ ] **Step 5:** Commit
```bash
git add Equinozio/Features/Riflessione/StoricoRiflessioniView.swift
git commit -m "feat: conferma prima di cancellare una riflessione (dato irrecuperabile)"
```

---

## Task 2: Conferma prima di cancellare in Decisione + leading swipe pulito

**Files:** `Equinozio/Features/Decisione/DecisioneView.swift`.

- [ ] **Step 1:** aggiungi `@State private var decisioneDaCancellare: Decisione?`.
- [ ] **Step 2:** swipe trailing imposta lo stato invece di cancellare subito:
```swift
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) { decisioneDaCancellare = d } label: {
                                        Label("Cancella", systemImage: "trash")
                                    }
                                }
```
- [ ] **Step 3:** dialog di conferma sul `List`:
```swift
                    .confirmationDialog(
                        "Cancellare questa decisione?",
                        isPresented: Binding(get: { decisioneDaCancellare != nil }, set: { if !$0 { decisioneDaCancellare = nil } }),
                        presenting: decisioneDaCancellare,
                        titleVisibility: .visible
                    ) { d in
                        Button("Cancella", role: .destructive) { cancella(d); decisioneDaCancellare = nil }
                        Button("Annulla", role: .cancel) { decisioneDaCancellare = nil }
                    }
```
- [ ] **Step 4:** Build + Test → verdi.
- [ ] **Step 5:** Commit
```bash
git add Equinozio/Features/Decisione/DecisioneView.swift
git commit -m "feat: conferma prima di cancellare una decisione"
```

---

## Task 3: Accessibilità tap in Mappa

**Files:** `Equinozio/Features/Mappa/MappaView.swift`, `Equinozio/Features/Mappa/BloccoInsight.swift`.

- [ ] **Step 1:** sui tre Button delle righe "Attività recente" aggiungi `.accessibilityLabel(...)`:
   - Diario → `.accessibilityLabel("Apri il Diario")`
   - Riflessioni → `.accessibilityLabel("Apri la Riflessione")`
   - Decisioni → `.accessibilityLabel("Apri le Decisioni")`
- [ ] **Step 2:** in `BloccoInsight`, sul Button della card aggiungi `.accessibilityHint("Apri la scheda relativa")` (il testo dello spunto è già la label).
- [ ] **Step 3:** Build → BUILD SUCCEEDED. Test → verde.
- [ ] **Step 4:** Commit
```bash
git add Equinozio/Features/Mappa/MappaView.swift Equinozio/Features/Mappa/BloccoInsight.swift
git commit -m "a11y: label/hint sui tap di attività e spunti in Mappa"
```

---

## Task 4: Insight — query con predicate + pruning

**Files:** `Equinozio/Features/Mappa/MappaView.swift`, `Equinozio/Domain/SpuntoStore.swift`.

Oggi MappaView `@Query` tutti gli `Insight` e filtra in Swift; SpuntoStore non pota i vecchi.

- [ ] **Step 1:** in `SpuntoStore.rigenera(...)`, dopo aver inserito il nuovo Insight e salvato, pota gli Insight più vecchi tenendone pochi (es. ultimi 8 per data). Subito dopo `try? contesto.save()` (quello dopo l'insert):
```swift
        // Pota gli Insight vecchi: tieni i 8 più recenti.
        let tutti = (try? contesto.fetch(
            FetchDescriptor<Insight>(sortBy: [SortDescriptor(\.dataGenerazione, order: .reverse)])
        )) ?? []
        for vecchio in tutti.dropFirst(8) { contesto.delete(vecchio) }
        try? contesto.save()
```
- [ ] **Step 2:** in `MappaView`, la `@Query(sort: \Insight.dataGenerazione, order: .reverse) private var insightCache: [Insight]` resta (con il pruning la tabella è piccola; un predicate per settimana non è banale perché `settimanaID` è una String calcolata a runtime → il filtro in Swift su pochi elementi va bene). Aggiungi solo un commento che documenta la scelta sopra la `@Query`:
```swift
    // Pochi Insight (potati a 8 in SpuntoStore): filtro la settimana corrente in Swift.
```
- [ ] **Step 3:** Build + Test → verdi.
- [ ] **Step 4:** Commit
```bash
git add Equinozio/Domain/SpuntoStore.swift Equinozio/Features/Mappa/MappaView.swift
git commit -m "perf: pota gli Insight vecchi (tieni 8); documenta il filtro Mappa"
```

---

## Task 5: Widget — freschezza al cambio settimana

**Files:** `EquinozioWidget/EquinozioWidget.swift`.

Se l'app non si apre al cambio settimana, il widget mostra lo Spunto vecchio. Mostra lo Spunto solo se è della settimana corrente.

- [ ] **Step 1:** nel provider del widget, leggi anche `settimanaID` dallo snapshot e confrontalo con la settimana corrente; se diverso, non passare lo spunto. Aggiungi un helper locale al widget (il widget NON importa il modulo app, quindi duplica la formula settimana):
```swift
private func settimanaCorrenteID() -> String {
    let c = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)
    return "\(c.yearForWeekOfYear ?? 0)-W\(c.weekOfYear ?? 0)"
}
```
e in `leggiSpunto()`:
```swift
    private func leggiSpunto() -> String {
        let d = UserDefaults(suiteName: gruppoCondiviso)
        let sid = d?.string(forKey: "settimanaID") ?? ""
        guard sid == settimanaCorrenteID() else { return "" }
        return d?.string(forKey: "spuntoTesto") ?? ""
    }
```
(`settimanaCorrenteID()` usa `Calendar.current` con la stessa formula di `Settimana.id`; va bene per il confronto di freschezza.)
- [ ] **Step 2:** Build → BUILD SUCCEEDED (build dell'app costruisce anche il widget).
- [ ] **Step 3:** Commit
```bash
git add EquinozioWidget/EquinozioWidget.swift
git commit -m "fix: il widget mostra lo Spunto solo se è della settimana corrente"
```

---

## Task 6: Rimuovi l'overload morto di WidgetSnapshot

**Files:** `Equinozio/Domain/WidgetSnapshot.swift`.

- [ ] **Step 1:** verifica che `WidgetSnapshot.aggiorna(equilibrio:)` (1 argomento) non sia più usato:
`grep -rn "WidgetSnapshot.aggiorna(equilibrio:" Equinozio` — deve mostrare solo l'overload completo (con spuntoTesto…). Se l'overload a 1 argomento non ha più chiamanti, rimuovilo.
- [ ] **Step 2:** Build + Test → verdi.
- [ ] **Step 3:** Commit
```bash
git add Equinozio/Domain/WidgetSnapshot.swift
git commit -m "chore: rimuovi l'overload WidgetSnapshot.aggiorna(equilibrio:) inutilizzato"
```
(Se invece ha ancora chiamanti, NON rimuoverlo: riporta come DONE_WITH_CONCERNS spiegando.)

---

## Task 7: DateFormatter italiano condiviso (dedup)

**Files:** Create `Equinozio/Domain/Formattazione.swift`; Modify le view che creano DateFormatter inline.

Più view creano `DateFormatter` it_IT inline (e per-chiamata). Centralizza.

- [ ] **Step 1:** Create `Equinozio/Domain/Formattazione.swift`:
```swift
//
//  Formattazione.swift
//  Equinozio · Domain
//
//  Formatter date italiani condivisi (cache statica · evita allocazioni ripetute).
//

import Foundation

public enum Formattazione {
    /// "lunedì 3 giugno" (giorno + mese esteso).
    public static let giornoMese: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "it_IT"); f.dateFormat = "EEEE d MMMM"; return f
    }()
    /// "lunedì 3 giugno · 14:30".
    public static let giornoMeseOra: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "it_IT"); f.dateFormat = "EEEE d MMMM · HH:mm"; return f
    }()
    /// "lun 3 giu" (abbreviato).
    public static let giornoMeseBreve: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "it_IT"); f.dateFormat = "EEEE d MMM"; return f
    }()
}
```
- [ ] **Step 2:** sostituisci i `DateFormatter` inline con `Formattazione.*` nelle view che li creano. Cerca i punti:
`grep -rn "DateFormatter()" Equinozio/Features` — per ciascuno, sostituisci la creazione+config inline con il formatter condiviso corrispondente al `dateFormat` usato (giornoMese / giornoMeseOra / giornoMeseBreve). Mantieni invariato l'output (stesso pattern). NON toccare formatter con pattern diversi (es. promemoria "EEEE 'alle' HH:mm" o export "EEEE d MMMM yyyy · HH:mm") a meno di aggiungere un caso a `Formattazione`; se un pattern è unico e usato una volta sola, lascialo inline.
- [ ] **Step 3:** Build + Test → verdi.
- [ ] **Step 4:** Commit
```bash
git add -A
git commit -m "refactor: DateFormatter italiani condivisi (Formattazione), niente duplicati"
```

---

## Task 8: MotoreSpunti — riscrittura AI iniettabile + test del fallback (TDD)

**Files:** `Equinozio/Domain/MotoreSpunti.swift`; Test `EquinozioTests/MotoreSpuntiTests.swift`.

Rendi iniettabile la dipendenza di riscrittura per testare il contratto "fallback alla frase-regola".

- [ ] **Step 1:** in `MotoreSpunti`, estrai la riscrittura dietro una closure sostituibile. Aggiungi una proprietà:
```swift
    /// Riscrittura del testo (default: Foundation Models). Sostituibile nei test.
    var riscrittore: (String) async -> String? = { frase in
        await MotoreSpunti.riscritturaPredefinita(frase)
    }
```
e sposta il corpo attuale di `testoCaldo`/`riscrivi` in una `static func riscritturaPredefinita(_:) async -> String?` (lo stesso codice gated `#available(iOS 26)` + FM, fallback nil). `testoCaldo(per:)` diventa:
```swift
    private func testoCaldo(per fraseRegola: String) async -> String {
        if let riscritta = await riscrittore(fraseRegola), !riscritta.isEmpty {
            return riscritta
        }
        return fraseRegola
    }
```
(`spuntoPrincipale` resta uguale.) Nota: `MotoreSpunti.shared` resta il singleton di produzione; per i test si crea un'istanza con `riscrittore` finto — quindi rendi `init()` accessibile ai test (può restare `private` se aggiungi un init di test, oppure usa un metodo statico di fabbrica `static func perTest(riscrittore:)`). Scelta semplice: aggiungi
```swift
    static func perTest(riscrittore: @escaping (String) async -> String?) -> MotoreSpunti {
        let m = MotoreSpunti(); m.riscrittore = riscrittore; return m
    }
```
(`init` resta private; `perTest` è interno al modulo → visibile ai test via @testable.)

- [ ] **Step 2:** Test in `EquinozioTests/MotoreSpuntiTests.swift`:
```swift
    @MainActor
    @Test func spuntoUsaLaRiscritturaQuandoDisponibile() async {
        let m = MotoreSpunti.perTest(riscrittore: { _ in "AI: riscritto" })
        let r = await m.spuntoPrincipale(riflessioni: [rifl(70,10,10,10)], decisioni: [], adesso: .now)
        #expect(r?.testo == "AI: riscritto")
    }
    @MainActor
    @Test func spuntoFallbackAllaRegolaSeRiscritturaNil() async {
        let regola = GeneratoreInsight.genera(riflessioni: [rifl(70,10,10,10)], decisioni: [], adesso: .now).first
        let m = MotoreSpunti.perTest(riscrittore: { _ in nil })
        let r = await m.spuntoPrincipale(riflessioni: [rifl(70,10,10,10)], decisioni: [], adesso: .now)
        #expect(r?.testo == regola?.testo)
    }
```
(`rifl(...)` helper già presente nel file di test.)

- [ ] **Step 3:** Run → FAIL prima (perTest/riscrittore inesistenti), PASS dopo l'implementazione.
- [ ] **Step 4:** Build → BUILD SUCCEEDED.
- [ ] **Step 5:** Commit
```bash
git add Equinozio/Domain/MotoreSpunti.swift EquinozioTests/MotoreSpuntiTests.swift
git commit -m "test: MotoreSpunti — riscrittura iniettabile + test fallback alla regola"
```

---

## Task 9: Verifica finale

- [ ] **Step 1:** Suite unit → `** TEST SUCCEEDED **`.
- [ ] **Step 2:** Build → `** BUILD SUCCEEDED **`.
- [ ] **Step 3:** Controllo su device: swipe-cancella in Storico/Decisione chiede conferma; VoiceOver annuncia i tap in Mappa; il widget non mostra spunti vecchi al cambio settimana.

---

## Self-Review
- **Copertura chip interazioni (task_13130a76):** conferma cancellazione Storico/Decisione → Task 1/2 ✓ · a11y Mappa → Task 3 ✓ · (leading swipe vuoto: è già innocuo — `if` interno alla closure non mostra handle; non richiede codice). · densità righe: rinviata (cosmetica, da valutare su device).
- **Copertura chip Fase A (task_439fc074):** Insight predicate/pruning → Task 4 ✓ · freschezza widget → Task 5 ✓ · overload morto → Task 6 ✓ · test fallback AI → Task 8 ✓.
- **Cose rimaste:** DateFormatter dedup → Task 7 ✓. Widget interattivo → fuori scope (motivato).
- **Placeholder:** nessuno; codice completo o intent+grep dove la struttura varia.
- **Onestà:** logica (pruning/freschezza/fallback) testata o build-verificata; conferme/a11y verificate via build + device.
