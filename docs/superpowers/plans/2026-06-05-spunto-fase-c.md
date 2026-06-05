# "Lo Spunto" — Fase C (Apple Intelligence & interazione) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Esporre Equinozio a Siri/Spotlight/Scorciatoie con App Intents (apri Riflessione, equilibrio corrente) e aggiungere un riassunto settimanale del diario scritto dall'AI on-device, con i Writing Tools attivi nei TextEditor.

**Architecture:** App Intents nel target app instradano via la stessa mappatura `Scheda` dei deep link; il riassunto diario usa una parte pura testabile (selezione pagine della settimana) + Foundation Models gated (iOS 26) col pattern già in uso. UI/Intents/FM verificati via build.

**Tech Stack:** SwiftUI, SwiftData, AppIntents, FoundationModels (iOS 26), Swift Testing. Lavorare su `main`.

**Spec:** `docs/superpowers/specs/2026-06-05-spunto-intelligenza-design.md` (Fase C).

**Descoped (follow-up separato):** widget interattivo con bottone AppIntent — richiede che il tipo Intent sia compilato anche nel target widget (membership cross-target / pbxproj). Il tap del widget fa già deep link (Fase A). Anche fuori scope: Live Activities, Lock Screen widget.

---

## Convenzioni
- **Test:** `xcodebuild test -scheme Equinozio -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:EquinozioTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`
- **Build:** `xcodebuild -scheme Equinozio -destination 'generic/platform=iOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -4` → `** BUILD SUCCEEDED **`
- Se un Edit fallisce per "file modificato" (edit paralleli): rileggere e riapplicare.

## File Structure
**Creati:**
- `Equinozio/EquinozioIntents.swift` — `ApriRiflessioneIntent`, `EquilibrioCorrenteIntent`, `EquinozioShortcuts`.
- `Equinozio/Domain/RiassuntoDiario.swift` — selezione pura + servizio FM.
- Test: `EquinozioTests/RiassuntoDiarioTests.swift`.
**Modificati:**
- `Equinozio/AppRouter.swift` — `Scheda.from(host:)` (e `fromDeepLink` la riusa).
- `Equinozio/EquinozioApp.swift` — consuma `pendingScheda` (onAppear + scenePhase active).
- `Equinozio/Features/Diario/DiarioView.swift` — bottone "Riassumi la settimana" + card.
- (verifica) Writing Tools nei TextEditor.

---

## Task 1: Scheda.from(host:) + ApriRiflessioneIntent + consumo pendingScheda

**Files:** Modify `Equinozio/AppRouter.swift`, `Equinozio/EquinozioApp.swift`; Create `Equinozio/EquinozioIntents.swift`; Test `EquinozioTests/DeepLinkTests.swift` (estende).

- [ ] **Step 1: Aggiungi il test per `from(host:)`** dentro lo `struct DeepLinkTests` esistente:
```swift
    @Test func fromHostMappaLeSchede() {
        #expect(Scheda.from(host: "riflessione") == .riflessione)
        #expect(Scheda.from(host: "mappa") == .mappa)
        #expect(Scheda.from(host: "ignota") == nil)
        #expect(Scheda.from(host: nil) == nil)
    }
```

- [ ] **Step 2: Run, verify FAIL** (`Scheda.from(host:)` undefined).

- [ ] **Step 3: Refactor in `Equinozio/AppRouter.swift`** — sostituisci l'extension `Scheda.fromDeepLink` con:
```swift
extension Scheda {
    /// Mappa un host (mappa/diario/riflessione/decisione) alla scheda.
    static func from(host: String?) -> Scheda? {
        switch host {
        case "mappa":       return .mappa
        case "diario":      return .diario
        case "riflessione": return .riflessione
        case "decisione":   return .decisione
        default:            return nil
        }
    }

    /// Mappa un URL `equinozio://<scheda>` alla scheda corrispondente.
    static func fromDeepLink(_ url: URL) -> Scheda? {
        guard url.scheme == "equinozio" else { return nil }
        return from(host: url.host)
    }
}
```

- [ ] **Step 4: Run, verify PASS** (nuovo test + i DeepLinkTests esistenti restano verdi).

- [ ] **Step 5: Crea `Equinozio/EquinozioIntents.swift`** con l'intent di apertura:
```swift
//
//  EquinozioIntents.swift
//  Equinozio
//
//  App Intents per Siri / Spotlight / Scorciatoie.
//

import AppIntents
import Foundation

/// Apre l'app sulla Riflessione. Scrive una "scheda in attesa" che l'app consuma all'avvio.
struct ApriRiflessioneIntent: AppIntent {
    static var title: LocalizedStringResource = "Apri la riflessione"
    static var description = IntentDescription("Apre Equinozio sulla riflessione settimanale.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set("riflessione", forKey: "pendingScheda")
        return .result()
    }
}
```

- [ ] **Step 6: Consuma `pendingScheda` in `Equinozio/EquinozioApp.swift`.** Leggi il file. Aggiungi un metodo privato nello struct:
```swift
    @MainActor
    private func consumaPendingScheda() {
        let difese = UserDefaults.standard
        if let pending = difese.string(forKey: "pendingScheda"),
           let scheda = Scheda.from(host: pending) {
            router.scheda = scheda
            difese.removeObject(forKey: "pendingScheda")
        }
    }
```
Poi chiamalo: nella `.onAppear` esistente (in fondo alla closure) aggiungi `consumaPendingScheda()`; e nell'`.onChange(of: scenePhase)` esistente, quando `nuovo == .active`, aggiungi `consumaPendingScheda()` (oltre alla chiamata esistente `gestisciCambioStato(nuovo)`).

- [ ] **Step 7: Build** → BUILD SUCCEEDED.

- [ ] **Step 8: Commit**
```bash
git add Equinozio/AppRouter.swift Equinozio/EquinozioIntents.swift Equinozio/EquinozioApp.swift EquinozioTests/DeepLinkTests.swift
git commit -m "feat: ApriRiflessioneIntent + Scheda.from(host:) + consumo pendingScheda"
```

---

## Task 2: EquilibrioCorrenteIntent + AppShortcutsProvider (build)

**Files:** Modify `Equinozio/EquinozioIntents.swift`.

- [ ] **Step 1: Aggiungi l'intent dell'equilibrio** in `EquinozioIntents.swift`:
```swift
/// Legge l'equilibrio corrente dallo snapshot App Group e lo riporta a voce.
struct EquilibrioCorrenteIntent: AppIntent {
    static var title: LocalizedStringResource = "Equilibrio corrente"
    static var description = IntentDescription("Dice il tuo equilibrio settimanale.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let equilibrio = UserDefaults(suiteName: WidgetSnapshot.suite)?
            .integer(forKey: WidgetSnapshot.chiaveEquilibrio) ?? 50
        return .result(dialog: "Il tuo equilibrio è \(equilibrio)%.")
    }
}
```

- [ ] **Step 2: Aggiungi l'AppShortcutsProvider** in fondo a `EquinozioIntents.swift`:
```swift
struct EquinozioShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ApriRiflessioneIntent(),
            phrases: [
                "Apri la riflessione di \(.applicationName)",
                "Rifletti con \(.applicationName)",
            ],
            shortTitle: "Riflessione",
            systemImageName: "moon.stars"
        )
        AppShortcut(
            intent: EquilibrioCorrenteIntent(),
            phrases: [
                "Com'è il mio equilibrio su \(.applicationName)",
                "Equilibrio di \(.applicationName)",
            ],
            shortTitle: "Equilibrio",
            systemImageName: "circle.grid.2x2"
        )
    }
}
```

- [ ] **Step 3: Build** → BUILD SUCCEEDED. (`WidgetSnapshot.suite` e `chiaveEquilibrio` sono `public static let` già esistenti.)

- [ ] **Step 4: Commit**
```bash
git add Equinozio/EquinozioIntents.swift
git commit -m "feat: EquilibrioCorrenteIntent + AppShortcutsProvider (Siri/Spotlight)"
```

---

## Task 3: RiassuntoDiario — selezione pura (TDD) + servizio FM

**Files:** Create `Equinozio/Domain/RiassuntoDiario.swift`; Test `EquinozioTests/RiassuntoDiarioTests.swift`.

- [ ] **Step 1: Test che fallisce** — create `EquinozioTests/RiassuntoDiarioTests.swift`:
```swift
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
        let oggi = c.date(from: DateComponents(year: 2026, month: 6, day: 3))!     // mercoledì
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
}
```

- [ ] **Step 2: Run, verify FAIL.**

- [ ] **Step 3: Create `Equinozio/Domain/RiassuntoDiario.swift`:**
```swift
//
//  RiassuntoDiario.swift
//  Equinozio · Domain
//
//  Riassunto settimanale del diario: selezione pura delle pagine + sintesi AI on-device.
//

import Foundation
import OSLog

#if canImport(FoundationModels)
import FoundationModels
#endif

public enum RiassuntoDiario {
    /// Le pagine non cancellate appartenenti alla settimana di `adesso`.
    public static func pagineSettimana(
        _ pagine: [Pagina], adesso: Date, calendario: Calendar = .current
    ) -> [Pagina] {
        let sid = Settimana.id(per: adesso, calendario: calendario)
        return pagine.filter {
            !$0.isCancellata && Settimana.id(per: $0.dataCreazione, calendario: calendario) == sid
        }
    }
}

@MainActor
public final class RiassuntoDiarioService {
    public static let shared = RiassuntoDiarioService()
    private let log = Logger(subsystem: "it.systema360.equinozio", category: "RiassuntoDiario")
    private init() {}

    /// Riassume le pagine in 1-2 frasi. nil se non disponibile o nessuna pagina.
    public func riassumi(_ pagine: [Pagina]) async -> String? {
        guard !pagine.isEmpty else { return nil }
        if #available(iOS 26.0, macOS 26.0, *) {
            return await viaFoundationModels(pagine)
        }
        return nil
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private func viaFoundationModels(_ pagine: [Pagina]) async -> String? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }
        let testo = pagine.map(\.testo).joined(separator: "\n---\n")
        let istruzioni = """
        Sei la voce di Equinozio, un'app italiana calma. Ti do alcune note di diario
        di questa settimana. Riassumile in 1-2 frasi italiane, sobrie e gentili, in
        seconda persona, cogliendo i temi ricorrenti. Niente elenchi, niente emoji.
        """
        do {
            let sessione = LanguageModelSession(instructions: istruzioni)
            let risposta = try await sessione.respond(to: testo)
            let pulito = risposta.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return pulito.isEmpty ? nil : pulito
        } catch {
            log.warning("Riassunto AI fallito: \(error.localizedDescription)")
            return nil
        }
    }
    #else
    @available(iOS 26.0, macOS 26.0, *)
    private func viaFoundationModels(_ pagine: [Pagina]) async -> String? { nil }
    #endif
}
```

- [ ] **Step 4: Run, verify PASS** (le due selezioni pure; il percorso FM solo compilato).

- [ ] **Step 5: Build** → BUILD SUCCEEDED.

- [ ] **Step 6: Commit**
```bash
git add Equinozio/Domain/RiassuntoDiario.swift EquinozioTests/RiassuntoDiarioTests.swift
git commit -m "feat: RiassuntoDiario — selezione pagine settimana (TDD) + sintesi AI gated"
```

---

## Task 4: DiarioView — "Riassumi la settimana" + Writing Tools (build)

**Files:** Modify `Equinozio/Features/Diario/DiarioView.swift`.

- [ ] **Step 1: Stato per il riassunto.** In `DiarioView`, dopo gli `@State` esistenti (es. dopo `@State private var mostraUndo`), aggiungi:
```swift
    @State private var riassunto: String?
    @State private var riassumendo = false
```

- [ ] **Step 2: Inserisci il blocco riassunto** nel `body`, dentro la `VStack(alignment: .leading, spacing: 0)`, subito dopo il blocco `ShareLink`/"ESPORTA" (e prima di `campoRicerca`):
```swift
                    if #available(iOS 26.0, *), !RiassuntoDiario.pagineSettimana(pagine, adesso: .now).isEmpty {
                        bloccoRiassunto
                            .padding(.bottom, S.x4)
                    }
```

- [ ] **Step 3: Aggiungi la view + l'azione** (dentro `DiarioView`, es. dopo `campoRicerca`):
```swift
    @available(iOS 26.0, *)
    private var bloccoRiassunto: some View {
        VStack(alignment: .leading, spacing: S.x2) {
            Button {
                Task { await generaRiassunto() }
            } label: {
                HStack(spacing: 6) {
                    if riassumendo {
                        ProgressView().scaleEffect(0.7).frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .medium))
                    }
                    Text("RIASSUMI LA SETTIMANA")
                        .font(.equinozio(.etichetta))
                        .tracking(1.6)
                }
                .foregroundStyle(Color.salvia)
            }
            .buttonStyle(.plain)
            .disabled(riassumendo)

            if let riassunto, !riassunto.isEmpty {
                Text(riassunto)
                    .font(.equinozio(.corpoMedio))
                    .foregroundStyle(Color.inchiostro)
                    .padding(S.x4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.superficie)
                    .clipShape(RoundedRectangle(cornerRadius: R.r2))
                    .overlay(
                        RoundedRectangle(cornerRadius: R.r2)
                            .stroke(Color.lineaSottile, lineWidth: 1)
                    )
            }
        }
    }

    @available(iOS 26.0, *)
    private func generaRiassunto() async {
        riassumendo = true
        defer { riassumendo = false }
        let pagineSettimana = RiassuntoDiario.pagineSettimana(pagine, adesso: .now)
        riassunto = await RiassuntoDiarioService.shared.riassumi(pagineSettimana)
    }
```
(`pagine` è la `@Query` esistente delle pagine non cancellate.)

- [ ] **Step 4: Writing Tools — verifica.** Esegui:
`grep -rn "writingToolsBehavior" Equinozio --include='*.swift'`
Atteso: **nessun output** (nessun TextEditor li disabilita → su iOS 18.2+ i Writing Tools sono attivi di default). Se comparisse `.writingToolsBehavior(.disabled)` su un TextEditor di Diario/Decisione/Riflessione, rimuoverlo. Nessun altro codice necessario.

- [ ] **Step 5: Build** → BUILD SUCCEEDED.

- [ ] **Step 6: Test** (no regressioni) → verde.

- [ ] **Step 7: Commit**
```bash
git add Equinozio/Features/Diario/DiarioView.swift
git commit -m "feat: Diario — riassunto settimanale AI su richiesta; Writing Tools attivi"
```

---

## Task 5: Verifica finale

- [ ] **Step 1: Suite unit** → `** TEST SUCCEEDED **`.
- [ ] **Step 2: Build** → `** BUILD SUCCEEDED **`.
- [ ] **Step 3: Controllo su device:** "Ehi Siri, com'è il mio equilibrio su Equinozio?" → risponde con la percentuale; "Apri la riflessione di Equinozio" → apre la scheda Riflessione; in Spotlight compaiono le scorciatoie. Nel Diario (iOS 26, con pagine della settimana) il bottone "Riassumi la settimana" genera un riassunto AI; selezionando testo in un TextEditor compaiono i Writing Tools.

---

## Self-Review
- **Copertura spec (Fase C):** App Intents + Siri/Spotlight → Task 1/2 ✓ · riassunto diario AI → Task 3/4 ✓ · Writing Tools → Task 4 (verifica) ✓ · widget interattivo → **descoped, documentato**.
- **Placeholder:** nessuno; codice completo + comandi.
- **Coerenza tipi:** `Scheda.from(host:)` riusata da `fromDeepLink` e dal consumo `pendingScheda`; `ApriRiflessioneIntent`/`EquilibrioCorrenteIntent`/`EquinozioShortcuts`; `WidgetSnapshot.suite`/`chiaveEquilibrio` (public esistenti); `RiassuntoDiario.pagineSettimana(_:adesso:calendario:)` + `RiassuntoDiarioService.shared.riassumi(_:)`; `Settimana.id` (Fase A); `Pagina` (testo/dataCreazione/isCancellata).
- **Gating AI:** riassunto dietro `#available(iOS 26)` + `#if canImport(FoundationModels)`, nil se non disponibile; il bottone appare solo su iOS 26. App Intents sono iOS 16+ → ok su iOS 18.
- **Onestà:** logica pura (host mapping, selezione pagine) coperta da unit test; App Intents/Siri/FM/UI verificati via build + prova su device.
