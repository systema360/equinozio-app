# "Lo Spunto" — Fase A — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Un unico motore on-device genera lo "Spunto della settimana" (regole sicure → frase scritta dai Foundation Models, fallback a regole), lo mette in cache una volta (`@Model Insight` + App Group) e lo mostra in Mappa e nel widget; il tap del widget apre la scheda giusta via deep link.

**Architecture:** Logica pura (regole, idempotenza, mappatura deep-link) in Domain con unit test Swift Testing; il percorso AI è dietro `#available(iOS 26)` con fallback; UI/widget verificati via build. Cache scritta in SwiftData (`Insight`) + snapshot App Group letto dal widget.

**Tech Stack:** SwiftUI, SwiftData (+CloudKit), FoundationModels (iOS 26), WidgetKit, Swift Testing. Lavorare su `main`.

**Spec:** `docs/superpowers/specs/2026-06-05-spunto-intelligenza-design.md` (Fase A).

---

## Convenzioni
- **Test:** `xcodebuild test -scheme Equinozio -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:EquinozioTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`
- **Build:** `xcodebuild -scheme Equinozio -destination 'generic/platform=iOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -4` → `** BUILD SUCCEEDED **`
- Token `S.*`/`R.*`/`Color.*`/`Font.equinozio`; mai bold. AI dietro `#available(iOS 26.0, *)` col pattern di `TagSuggestionService`.

## File Structure
**Creati:**
- `Equinozio/AppRouter.swift` — `@Observable` con `scheda: Scheda` + `Scheda.fromDeepLink`.
- `Equinozio/Domain/Settimana.swift` — id settimanale deterministico.
- `Equinozio/Domain/MotoreSpunti.swift` — selezione situazione principale (pura) + riscrittura AI (gated).
- `Equinozio/Domain/SpuntoStore.swift` — cache settimanale (Insight + snapshot) + trigger reload widget.
- Test: `EquinozioTests/DeepLinkTests.swift`, `SettimanaTests.swift`, `MotoreSpuntiTests.swift`, `SpuntoStoreTests.swift`.

**Modificati:**
- `Equinozio/Info.plist` — `CFBundleURLTypes` (schema `equinozio`).
- `Equinozio/EquinozioApp.swift` — `AppRouter` in environment + `.onOpenURL`.
- `Equinozio/ContenitoreView.swift` — selezione legata a `router.scheda`.
- `Equinozio/Domain/Modelli.swift` — `Insight.settimanaID`.
- `Equinozio/Domain/WidgetSnapshot.swift` — snapshot esteso (spunto).
- `Equinozio/Features/Riflessione/RiflessioneView.swift` — trigger `rigenera` al salvataggio.
- `Equinozio/Features/Mappa/MappaView.swift` — mostra lo Spunto in cache.
- `EquinozioWidget/EquinozioWidget.swift` — mostra lo Spunto + `widgetURL`.

> `GeneratoreInsight`/`InsightGenerato` restano invariati (e i loro test): `MotoreSpunti` li riusa.

---

## Task 1: Deep-link mapping (TDD)

**Files:** Create `Equinozio/AppRouter.swift`; Test `EquinozioTests/DeepLinkTests.swift`.

- [ ] **Step 1: Test che fallisce** — create `EquinozioTests/DeepLinkTests.swift`:

```swift
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
```

- [ ] **Step 2: Run, verify FAIL** (Scheda.fromDeepLink / AppRouter undefined).

- [ ] **Step 3: Create `Equinozio/AppRouter.swift`:**

```swift
//
//  AppRouter.swift
//  Equinozio
//
//  Routing globale fra le schede + mappatura dei deep link (equinozio://…).
//

import SwiftUI

@Observable
public final class AppRouter {
    public var scheda: Scheda = .mappa
    public init() {}
}

public extension Scheda {
    /// Mappa un URL `equinozio://<scheda>` alla scheda corrispondente.
    static func fromDeepLink(_ url: URL) -> Scheda? {
        guard url.scheme == "equinozio" else { return nil }
        switch url.host {
        case "mappa":       return .mappa
        case "diario":      return .diario
        case "riflessione": return .riflessione
        case "decisione":   return .decisione
        default:            return nil
        }
    }
}
```

(`Scheda` è già definita, top-level, in `ContenitoreView.swift`.)

- [ ] **Step 4: Run, verify PASS.**

- [ ] **Step 5: Commit**
```bash
git add Equinozio/AppRouter.swift EquinozioTests/DeepLinkTests.swift
git commit -m "feat: AppRouter + mappatura deep link equinozio:// (TDD)"
```

---

## Task 2: URL scheme + wiring router (build)

**Files:** Modify `Equinozio/Info.plist`, `Equinozio/EquinozioApp.swift`, `Equinozio/ContenitoreView.swift`.

- [ ] **Step 1: Registra lo schema URL** in `Equinozio/Info.plist`, dentro il `<dict>` radice, aggiungi:

```xml
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLName</key>
			<string>it.systema360.equinozio</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>equinozio</string>
			</array>
		</dict>
	</array>
```

- [ ] **Step 2: Inietta il router e gestisci onOpenURL** in `Equinozio/EquinozioApp.swift`:

(a) aggiungi lo stato dopo `@State private var richiedeSblocco: Bool = false`:
```swift
    @State private var router = AppRouter()
```
(b) sul contenuto del `WindowGroup` (dove c'è `ContenitoreView()`), aggiungi l'environment: cambia `ContenitoreView()` in:
```swift
                ContenitoreView()
                    .tint(.salvia)
                    .environment(router)
```
(c) accanto a `.onChange(of: scenePhase)` aggiungi:
```swift
            .onOpenURL { url in
                if let scheda = Scheda.fromDeepLink(url) {
                    router.scheda = scheda
                }
            }
```

- [ ] **Step 3: Lega la selezione al router** in `Equinozio/ContenitoreView.swift`:

(a) sostituisci `@State private var schedaAttiva: Scheda = .mappa` con:
```swift
    @Environment(AppRouter.self) private var router
```
(b) aggiungi una computed binding (dentro lo struct):
```swift
    private var selezione: Binding<Scheda> {
        Binding(get: { router.scheda }, set: { router.scheda = $0 })
    }
```
(c) nel `tabView`, cambia `TabView(selection: $schedaAttiva)` in `TabView(selection: selezione)`.
(d) nel `sidebarView`, cambia il `List(selection:)` in:
```swift
            List(selection: Binding(
                get: { selezione.wrappedValue as Scheda? },
                set: { if let s = $0 { selezione.wrappedValue = s } }
            )) {
```
e nel `detail:` cambia `switch schedaAttiva {` in `switch router.scheda {`.
(e) aggiorna il `#Preview` per iniettare il router:
```swift
#Preview {
    ContenitoreView()
        .environment(AppRouter())
        .modelContainer(for: [
            Profilo.self, Cerchio.self, Elemento.self,
            Pagina.self, Riflessione.self, Decisione.self, Insight.self,
        ], inMemory: true)
}
```

- [ ] **Step 4: Build** → BUILD SUCCEEDED.

- [ ] **Step 5: Commit**
```bash
git add Equinozio/Info.plist Equinozio/EquinozioApp.swift Equinozio/ContenitoreView.swift
git commit -m "feat: schema URL equinozio:// + AppRouter in environment, deep link apre la scheda"
```

---

## Task 3: Id settimanale deterministico (TDD)

**Files:** Create `Equinozio/Domain/Settimana.swift`; Test `EquinozioTests/SettimanaTests.swift`.

- [ ] **Step 1: Test che fallisce** — create `EquinozioTests/SettimanaTests.swift`:

```swift
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
        let lun = cal.date(from: DateComponents(year: 2026, month: 6, day: 1))!  // lunedì
        let dom = cal.date(from: DateComponents(year: 2026, month: 6, day: 7))!  // domenica stessa settimana ISO
        #expect(Settimana.id(per: lun, calendario: cal) == Settimana.id(per: dom, calendario: cal))
    }
    @Test func idCambiaTraSettimaneDiverse() {
        let cal = calUTC
        let a = cal.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let b = cal.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        #expect(Settimana.id(per: a, calendario: cal) != Settimana.id(per: b, calendario: cal))
    }
}
```

- [ ] **Step 2: Run, verify FAIL.**

- [ ] **Step 3: Create `Equinozio/Domain/Settimana.swift`:**

```swift
//
//  Settimana.swift
//  Equinozio · Domain
//
//  Identificatore deterministico della settimana (per la cache degli Spunti).
//

import Foundation

public enum Settimana {
    /// Es. "2026-W23". Indipendente dal locale: usa year-for-week-of-year + week-of-year.
    public static func id(per data: Date, calendario: Calendar = .current) -> String {
        let c = calendario.dateComponents([.yearForWeekOfYear, .weekOfYear], from: data)
        return "\(c.yearForWeekOfYear ?? 0)-W\(c.weekOfYear ?? 0)"
    }
}
```

- [ ] **Step 4: Run, verify PASS.**

- [ ] **Step 5: Commit**
```bash
git add Equinozio/Domain/Settimana.swift EquinozioTests/SettimanaTests.swift
git commit -m "feat: Settimana.id deterministico per la cache settimanale (TDD)"
```

---

## Task 4: MotoreSpunti — selezione pura + riscrittura AI

**Files:** Create `Equinozio/Domain/MotoreSpunti.swift`; Test `EquinozioTests/MotoreSpuntiTests.swift`.

- [ ] **Step 1: Test che fallisce** — create `EquinozioTests/MotoreSpuntiTests.swift`:

```swift
import Testing
import Foundation
@testable import Equinozio

struct MotoreSpuntiTests {
    private func rifl(_ p: Int, _ t: Int, _ m: Int, _ s: Int) -> Riflessione {
        Riflessione(data: .now, quotaPassione: p, quotaTalento: t, quotaMissione: m, quotaProfessione: s)
    }

    @Test func principaleEILaSituazioneTopDelleRegole() {
        let regole = GeneratoreInsight.genera(riflessioni: [rifl(70, 10, 10, 10)], decisioni: [], adesso: .now)
        let principale = MotoreSpunti.principale(riflessioni: [rifl(70, 10, 10, 10)], decisioni: [], adesso: .now)
        #expect(principale?.tipo == regole.first?.tipo)
    }

    @Test func principaleNilSenzaDati() {
        #expect(MotoreSpunti.principale(riflessioni: [], decisioni: [], adesso: .now) == nil)
    }

    @Test func spuntiMappaMettonoLaCacheInTesta() {
        let cache = InsightGenerato(tipo: .crescitaTrend, testo: "AI: stai migliorando")
        let regole = [
            InsightGenerato(tipo: .bilanciamentoBasso, testo: "r1"),
            InsightGenerato(tipo: .crescitaTrend, testo: "r2"),
            InsightGenerato(tipo: .dominanzaCerchio, testo: "r3"),
        ]
        let out = MotoreSpunti.spuntiMappa(principale: cache, regole: regole)
        #expect(out.first?.testo == "AI: stai migliorando")
        #expect(out.filter { $0.tipo == .crescitaTrend }.count == 1) // dedup per tipo
        #expect(out.count <= 3)
    }

    @Test func spuntiMappaSenzaCacheUsanoLeRegole() {
        let regole = [InsightGenerato(tipo: .bilanciamentoBasso, testo: "r1")]
        #expect(MotoreSpunti.spuntiMappa(principale: nil, regole: regole).count == 1)
    }
}
```

- [ ] **Step 2: Run, verify FAIL.**

- [ ] **Step 3: Create `Equinozio/Domain/MotoreSpunti.swift`:**

```swift
//
//  MotoreSpunti.swift
//  Equinozio · Domain
//
//  Sceglie la situazione principale (regole, pura) e ne produce il testo finale:
//  su iOS 26 i Foundation Models riscrivono la frase-regola in modo più caldo
//  (stessi fatti e numeri); altrimenti si usa la frase a regole.
//

import Foundation
import OSLog

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
public final class MotoreSpunti {

    public static let shared = MotoreSpunti()
    private let log = Logger(subsystem: "it.systema360.equinozio", category: "MotoreSpunti")
    private init() {}

    // MARK: - Parte pura (regole)

    /// La situazione prioritaria della settimana, secondo le regole esistenti.
    nonisolated public static func principale(
        riflessioni: [Riflessione], decisioni: [Decisione], adesso: Date
    ) -> InsightGenerato? {
        GeneratoreInsight.genera(riflessioni: riflessioni, decisioni: decisioni, adesso: adesso).first
    }

    /// Per la Mappa: lo Spunto in cache (AI) in testa, poi le altre situazioni a regole
    /// deduplicate per tipo, massimo 3.
    nonisolated public static func spuntiMappa(
        principale: InsightGenerato?, regole: [InsightGenerato]
    ) -> [InsightGenerato] {
        guard let principale else { return regole }
        let altre = regole.filter { $0.tipo != principale.tipo }
        return Array(([principale] + altre).prefix(3))
    }

    // MARK: - Testo finale (AI o regola)

    /// Lo Spunto principale col testo definitivo (riscritto dall'AI se disponibile).
    public func spuntoPrincipale(
        riflessioni: [Riflessione], decisioni: [Decisione], adesso: Date
    ) async -> InsightGenerato? {
        guard let base = Self.principale(riflessioni: riflessioni, decisioni: decisioni, adesso: adesso) else {
            return nil
        }
        let testo = await testoCaldo(per: base.testo)
        return InsightGenerato(tipo: base.tipo, testo: testo)
    }

    private func testoCaldo(per fraseRegola: String) async -> String {
        if #available(iOS 26.0, macOS 26.0, *) {
            if let riscritta = await riscrivi(fraseRegola), !riscritta.isEmpty {
                return riscritta
            }
        }
        return fraseRegola
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private func riscrivi(_ frase: String) async -> String? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }
        let istruzioni = """
        Sei la voce di Equinozio, un'app italiana calma sul metodo dei quattro cerchi.
        Ti do una frase già corretta nei fatti e nei numeri. Riscrivila in UNA frase
        italiana, sobria e gentile, in seconda persona. NON cambiare i numeri né i fatti,
        non aggiungerne di nuovi. Niente emoji, niente virgolette, una sola frase.
        """
        do {
            let sessione = LanguageModelSession(instructions: istruzioni)
            let risposta = try await sessione.respond(to: frase)
            return risposta.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            log.warning("Riscrittura AI fallita: \(error.localizedDescription)")
            return nil
        }
    }
    #else
    @available(iOS 26.0, macOS 26.0, *)
    private func riscrivi(_ frase: String) async -> String? { nil }
    #endif
}
```

- [ ] **Step 4: Run, verify PASS** (le funzioni pure; il percorso AI è solo compilato).

- [ ] **Step 5: Build** → BUILD SUCCEEDED.

- [ ] **Step 6: Commit**
```bash
git add Equinozio/Domain/MotoreSpunti.swift EquinozioTests/MotoreSpuntiTests.swift
git commit -m "feat: MotoreSpunti — situazione principale (pura) + riscrittura AI gated"
```

---

## Task 5: Insight.settimanaID + snapshot esteso (build)

**Files:** Modify `Equinozio/Domain/Modelli.swift`, `Equinozio/Domain/WidgetSnapshot.swift`.

- [ ] **Step 1: Aggiungi `settimanaID` al `@Model Insight`** in `Modelli.swift`. Nella classe `Insight`, dopo `public var dataGenerazione: Date = Date.distantPast`, aggiungi:
```swift
    public var settimanaID: String = ""
```
(CloudKit richiede un default: `""` va bene. L'`init` esistente resta; `settimanaID` si imposta dopo la creazione.)

- [ ] **Step 2: Estendi `WidgetSnapshot`** (`Domain/WidgetSnapshot.swift`). Aggiungi le chiavi e un nuovo metodo (mantieni quello esistente):
```swift
    public static let chiaveSpuntoTesto = "spuntoTesto"
    public static let chiaveSpuntoTipo = "spuntoTipo"
    public static let chiaveSettimana = "settimanaID"

    /// Snapshot completo: equilibrio + Spunto della settimana (per widget e notifica).
    public static func aggiorna(equilibrio: Int, spuntoTesto: String, spuntoTipo: String, settimanaID: String) {
        guard let difese = UserDefaults(suiteName: suite) else { return }
        difese.set(equilibrio, forKey: chiaveEquilibrio)
        difese.set(spuntoTesto, forKey: chiaveSpuntoTesto)
        difese.set(spuntoTipo, forKey: chiaveSpuntoTipo)
        difese.set(settimanaID, forKey: chiaveSettimana)
    }
```

- [ ] **Step 3: Build** → BUILD SUCCEEDED.

- [ ] **Step 4: Commit**
```bash
git add Equinozio/Domain/Modelli.swift Equinozio/Domain/WidgetSnapshot.swift
git commit -m "feat: Insight.settimanaID + snapshot widget esteso con lo Spunto"
```

---

## Task 6: SpuntoStore — cache settimanale (TDD idempotenza)

**Files:** Create `Equinozio/Domain/SpuntoStore.swift`; Test `EquinozioTests/SpuntoStoreTests.swift`.

- [ ] **Step 1: Test che fallisce** — create `EquinozioTests/SpuntoStoreTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import Equinozio

struct SpuntoStoreTests {
    @Test func esisteSpuntoRiconosceLaSettimana() {
        let i = Insight(tipo: .crescitaTrend, testo: "x")
        i.settimanaID = "2026-W23"
        #expect(SpuntoStore.esisteSpunto(per: "2026-W23", in: [i]))
        #expect(!SpuntoStore.esisteSpunto(per: "2026-W24", in: [i]))
        #expect(!SpuntoStore.esisteSpunto(per: "2026-W23", in: []))
    }

    @MainActor
    @Test func rigeneraScriveUnInsightDellaSettimana() async throws {
        let schema = Schema([Profilo.self, Cerchio.self, Elemento.self, Pagina.self, Riflessione.self, Decisione.self, Insight.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let ctx = container.mainContext
        ctx.insert(Riflessione(data: .now, quotaPassione: 70, quotaTalento: 10, quotaMissione: 10, quotaProfessione: 10))
        try ctx.save()

        await SpuntoStore.rigenera(contesto: ctx, adesso: .now)

        let insights = try ctx.fetch(FetchDescriptor<Insight>())
        #expect(insights.count == 1)
        #expect(!(insights.first?.testo.isEmpty ?? true))
        #expect(insights.first?.settimanaID == Settimana.id(per: .now))
    }
}
```

- [ ] **Step 2: Run, verify FAIL.**

- [ ] **Step 3: Create `Equinozio/Domain/SpuntoStore.swift`:**

```swift
//
//  SpuntoStore.swift
//  Equinozio · Domain
//
//  Genera lo Spunto della settimana UNA volta e lo mette in cache:
//  · @Model Insight (sincronizzato iCloud)
//  · snapshot App Group (per il widget)
//  e ricarica le timeline del widget.
//

import Foundation
import SwiftData
import WidgetKit

@MainActor
public enum SpuntoStore {

    /// Esiste già uno Spunto per quella settimana?
    nonisolated public static func esisteSpunto(per settimanaID: String, in insights: [Insight]) -> Bool {
        insights.contains { $0.settimanaID == settimanaID }
    }

    /// Forza la rigenerazione per la settimana corrente (usata al salvataggio di una Riflessione).
    public static func rigenera(contesto: ModelContext, adesso: Date = .now) async {
        let sid = Settimana.id(per: adesso)
        let esistenti = (try? contesto.fetch(FetchDescriptor<Insight>())) ?? []
        for vecchio in esistenti where vecchio.settimanaID == sid {
            contesto.delete(vecchio)
        }

        let riflessioni = (try? contesto.fetch(
            FetchDescriptor<Riflessione>(sortBy: [SortDescriptor(\.data, order: .reverse)])
        )) ?? []
        let decisioni = (try? contesto.fetch(FetchDescriptor<Decisione>())) ?? []

        guard let spunto = await MotoreSpunti.shared.spuntoPrincipale(
            riflessioni: riflessioni, decisioni: decisioni, adesso: adesso
        ) else {
            try? contesto.save()
            return
        }

        let modello = Insight(tipo: spunto.tipo, testo: spunto.testo)
        modello.settimanaID = sid
        contesto.insert(modello)
        try? contesto.save()

        let equilibrio = riflessioni.first?.equilibrio ?? 50
        WidgetSnapshot.aggiorna(
            equilibrio: equilibrio,
            spuntoTesto: spunto.testo,
            spuntoTipo: spunto.tipo.rawValue,
            settimanaID: sid
        )
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Rigenera solo se non c'è già uno Spunto per la settimana corrente (usata all'apertura app).
    public static func aggiornaSeNecessario(contesto: ModelContext, adesso: Date = .now) async {
        let sid = Settimana.id(per: adesso)
        let esistenti = (try? contesto.fetch(FetchDescriptor<Insight>())) ?? []
        if esisteSpunto(per: sid, in: esistenti) { return }
        await rigenera(contesto: contesto, adesso: adesso)
    }
}
```

- [ ] **Step 4: Run, verify PASS.**

- [ ] **Step 5: Build** → BUILD SUCCEEDED.

- [ ] **Step 6: Commit**
```bash
git add Equinozio/Domain/SpuntoStore.swift EquinozioTests/SpuntoStoreTests.swift
git commit -m "feat: SpuntoStore — cache settimanale idempotente (Insight + snapshot) (TDD)"
```

---

## Task 7: Trigger di rigenerazione (build)

**Files:** Modify `Equinozio/Features/Riflessione/RiflessioneView.swift`, `Equinozio/ContenitoreView.swift`.

- [ ] **Step 1: Al salvataggio di una Riflessione** — in `RiflessioneView.salva()`, sostituisci la riga esistente `WidgetSnapshot.aggiorna(equilibrio: equilibrioCorrente)` con:
```swift
            Task { await SpuntoStore.rigenera(contesto: contesto) }
```
(`contesto` è l'`@Environment(\.modelContext)` già presente. Lo Spunto viene rigenerato sui dati appena salvati, snapshot e widget aggiornati.)

- [ ] **Step 2: All'apertura app** — in `ContenitoreView.setupPrimoAvvio()`, in fondo alla funzione (dopo il blocco esplorazione), aggiungi:
```swift
        await SpuntoStore.aggiornaSeNecessario(contesto: contesto)
```

- [ ] **Step 3: Build** → BUILD SUCCEEDED.

- [ ] **Step 4: Test** (no regressioni) → verde.

- [ ] **Step 5: Commit**
```bash
git add Equinozio/Features/Riflessione/RiflessioneView.swift Equinozio/ContenitoreView.swift
git commit -m "feat: rigenera lo Spunto al salvataggio Riflessione e all'apertura app"
```

---

## Task 8: Mappa mostra lo Spunto in cache (build)

**Files:** Modify `Equinozio/Features/Mappa/MappaView.swift`.

- [ ] **Step 1: Query della cache + merge.** In `MappaView`:

(a) aggiungi una query dopo le altre `@Query`:
```swift
    @Query(sort: \Insight.dataGenerazione, order: .reverse) private var insightCache: [Insight]
```
(b) sostituisci la computed property `insight`:
```swift
    private var insight: [InsightGenerato] {
        GeneratoreInsight.genera(riflessioni: riflessioni, decisioni: decisioni, adesso: .now)
    }
```
con:
```swift
    private var insight: [InsightGenerato] {
        let regole = GeneratoreInsight.genera(riflessioni: riflessioni, decisioni: decisioni, adesso: .now)
        let sid = Settimana.id(per: .now)
        let cache = insightCache.first { $0.settimanaID == sid }
        let principale = cache.map { InsightGenerato(tipo: $0.tipo, testo: $0.testo) }
        return MotoreSpunti.spuntiMappa(principale: principale, regole: regole)
    }
```
(`BloccoInsight(insight: insight)` resta invariato.)

- [ ] **Step 2: Build** → BUILD SUCCEEDED.

- [ ] **Step 3: Commit**
```bash
git add Equinozio/Features/Mappa/MappaView.swift
git commit -m "feat: la Mappa mostra lo Spunto in cache (AI) in testa agli spunti"
```

---

## Task 9: Widget mostra lo Spunto + deep link (build)

**Files:** Modify `EquinozioWidget/EquinozioWidget.swift`.

- [ ] **Step 1: Leggi lo Spunto nello snapshot.** Aggiorna `EquinozioEntry` e `EquinozioProvider`:

(a) `EquinozioEntry` → aggiungi `let spunto: String`:
```swift
struct EquinozioEntry: TimelineEntry {
    let date: Date
    let equilibrio: Int
    let spunto: String
}
```
(b) nel provider, aggiorna i tre costruttori di `EquinozioEntry`:
- `placeholder`: `EquinozioEntry(date: .now, equilibrio: 72, spunto: "Settimana in equilibrio.")`
- `getSnapshot`/`getTimeline`: `EquinozioEntry(date: .now, equilibrio: leggiEquilibrio(), spunto: leggiSpunto())`
(c) aggiungi il lettore accanto a `leggiEquilibrio()`:
```swift
    private func leggiSpunto() -> String {
        UserDefaults(suiteName: gruppoCondiviso)?.string(forKey: "spuntoTesto") ?? ""
    }
```

- [ ] **Step 2: Mostra lo Spunto su medium/large + deep link.**
(a) Nella `EquinozioWidgetView`, nel ramo `medio`, sotto il blocco numero (dentro la `VStack` di sinistra, prima di `Spacer`/`marchio`) aggiungi, se presente:
```swift
                if !entry.spunto.isEmpty {
                    Text(entry.spunto)
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
```
(b) Nel ramo `grande`, dopo il `Divider()` (prima della legenda dei cerchi), aggiungi lo stesso blocco con `lineLimit(4)`.
(c) Aggiungi il deep link al contenitore: nel `body`, sul `Group { … }` (dopo `.containerBackground(...)`), aggiungi:
```swift
        .widgetURL(URL(string: "equinozio://riflessione"))
```

- [ ] **Step 3: Build** → BUILD SUCCEEDED (verifica anche che il widget compili/incorpori).

- [ ] **Step 4: Commit**
```bash
git add EquinozioWidget/EquinozioWidget.swift
git commit -m "feat: il widget mostra lo Spunto e apre la Riflessione al tap (deep link)"
```

---

## Task 10: Verifica finale

- [ ] **Step 1: Suite unit** → `** TEST SUCCEEDED **`.
- [ ] **Step 2: Build** → `** BUILD SUCCEEDED **`.
- [ ] **Step 3: Controllo su device** (il simulatore non avvia l'app per CloudKit): salva una Riflessione → in Mappa compare lo Spunto (su iOS 26 scritto dall'AI, altrimenti a regole); il widget mostra lo Spunto e al tap apre la Riflessione; aggiungi `equinozio://decisione` in Safari → apre la scheda Decisione.

---

## Self-Review
- **Copertura spec (Fase A):** MotoreSpunti ibrido → Task 4 ✓ · cache Insight + snapshot → Task 5+6 ✓ · trigger (salva + apertura) + WidgetCenter reload → Task 6/7 ✓ · BloccoInsight mostra lo Spunto → Task 8 ✓ · widget mostra Spunto + widgetURL → Task 9 ✓ · deep link (schema + AppRouter + onOpenURL + mappatura) → Task 1/2 ✓ · Settimana.id → Task 3 ✓.
- **Placeholder:** nessuno; codice completo + comandi.
- **Coerenza tipi:** `InsightGenerato(tipo:testo:)` (esistente) riusato; `MotoreSpunti.principale(riflessioni:decisioni:adesso:)`, `.spuntiMappa(principale:regole:)`, `.shared.spuntoPrincipale(...)`; `SpuntoStore.rigenera(contesto:adesso:)`/`.aggiornaSeNecessario(contesto:adesso:)`/`.esisteSpunto(per:in:)`; `Settimana.id(per:calendario:)`; `WidgetSnapshot.aggiorna(equilibrio:spuntoTesto:spuntoTipo:settimanaID:)`; `Scheda.fromDeepLink(_:)`; `AppRouter.scheda`. `Insight(tipo:testo:)` esiste; `settimanaID` impostato dopo init.
- **Gating AI:** dietro `#available(iOS 26)` + `#if canImport(FoundationModels)`, fallback alla frase-regola; nessuna regressione su iOS 18.
- **Onestà:** logica pura coperta da unit test; AI/UI/widget verificati via build + controllo su device.
```
