# "Lo Spunto" — Fase B (Notifica che parla) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Il promemoria settimanale "parla": porta lo Spunto della settimana come corpo e offre un'azione "Rifletti ora" che apre la Riflessione (deep link).

**Architecture:** Logica pura (risoluzione del corpo) in `PromemoriaService` con unit test; categoria/azione di notifica + delegate + wiring verificati via build. Il corpo resta in sync con lo Spunto perché `SpuntoStore.rigenera` riprogramma la notifica quando lo Spunto cambia.

**Tech Stack:** SwiftUI, SwiftData, UserNotifications, Swift Testing. Lavorare su `main`.

**Spec:** `docs/superpowers/specs/2026-06-05-spunto-intelligenza-design.md` (Fase B).

---

## Convenzioni
- **Test:** `xcodebuild test -scheme Equinozio -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:EquinozioTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`
- **Build:** `xcodebuild -scheme Equinozio -destination 'generic/platform=iOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -4` → `** BUILD SUCCEEDED **`
- Se un Edit fallisce per "file modificato" (l'utente edita in parallelo): rileggere e riapplicare.

## File Structure
**Creati:**
- `Equinozio/Domain/NotificationeDelegate.swift` — delegate che instrada azione/tap → Riflessione.
**Modificati:**
- `Equinozio/Domain/PromemoriaService.swift` — `corpo(spunto:personalizzato:)`, categoria+azione, `registraCategorie()`, `categoryIdentifier` in `schedulaRiflessione`.
- `Equinozio/Domain/WidgetSnapshot.swift` — reader `leggiSpunto()`.
- `Equinozio/EquinozioApp.swift` — delegate + categorie + `onApri` collegato al router, all'avvio.
- `Equinozio/Features/Impostazioni/ImpostazioniView.swift` — corpo = Spunto (fallback personalizzato).
- `Equinozio/Domain/SpuntoStore.swift` — riprogramma la notifica quando lo Spunto cambia.

---

## Task 1: `corpo(spunto:personalizzato:)` puro + `leggiSpunto()` (TDD)

**Files:** Modify `Equinozio/Domain/PromemoriaService.swift`, `Equinozio/Domain/WidgetSnapshot.swift`; Test `EquinozioTests/PromemoriaTests.swift` (esiste già — estendi).

- [ ] **Step 1: Aggiungi i test** dentro lo `struct PromemoriaTests` esistente in `EquinozioTests/PromemoriaTests.swift`:

```swift
    @Test func corpoUsaLoSpuntoSePresente() {
        #expect(PromemoriaService.corpo(spunto: "Stai migliorando", personalizzato: "fallback") == "Stai migliorando")
    }
    @Test func corpoFallbackSeSpuntoVuotoONil() {
        #expect(PromemoriaService.corpo(spunto: nil, personalizzato: "fallback") == "fallback")
        #expect(PromemoriaService.corpo(spunto: "", personalizzato: "fallback") == "fallback")
        #expect(PromemoriaService.corpo(spunto: "   ", personalizzato: "fallback") == "fallback")
    }
```

- [ ] **Step 2: Run, verify FAIL** (`PromemoriaService.corpo` undefined).

- [ ] **Step 3: Implementa `corpo` in `PromemoriaService`** — aggiungi dentro la classe:

```swift
    /// Corpo della notifica: lo Spunto se presente, altrimenti il messaggio personalizzato.
    nonisolated public static func corpo(spunto: String?, personalizzato: String) -> String {
        let s = (spunto ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty ? personalizzato : s
    }
```

- [ ] **Step 4: Aggiungi `leggiSpunto()` a `WidgetSnapshot`** — dentro l'enum:

```swift
    /// Lo Spunto corrente dallo snapshot App Group (nil se assente/vuoto).
    public static func leggiSpunto() -> String? {
        guard let difese = UserDefaults(suiteName: suite) else { return nil }
        let t = (difese.string(forKey: chiaveSpuntoTesto) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
```

- [ ] **Step 5: Run, verify PASS.**

- [ ] **Step 6: Commit**
```bash
git add Equinozio/Domain/PromemoriaService.swift Equinozio/Domain/WidgetSnapshot.swift EquinozioTests/PromemoriaTests.swift
git commit -m "feat: PromemoriaService.corpo (TDD) + WidgetSnapshot.leggiSpunto"
```

---

## Task 2: Categoria + azione "Rifletti ora" (build)

**Files:** Modify `Equinozio/Domain/PromemoriaService.swift`.

- [ ] **Step 1: Costanti + registrazione categoria.** In `PromemoriaService`, accanto a `identificatoreRiflessione`, aggiungi:
```swift
    public static let categoriaRiflessione = "RIFLESSIONE_SETTIMANALE"
    public static let azioneRifletti = "RIFLETTI_ORA"

    /// Registra la categoria con l'azione "Rifletti ora". Chiamare una volta all'avvio.
    public func registraCategorie() {
        let azione = UNNotificationAction(
            identifier: Self.azioneRifletti,
            title: "Rifletti ora",
            options: [.foreground]
        )
        let categoria = UNNotificationCategory(
            identifier: Self.categoriaRiflessione,
            actions: [azione],
            intentIdentifiers: [],
            options: []
        )
        centro.setNotificationCategories([categoria])
    }
```

- [ ] **Step 2: Assegna la categoria al contenuto** in `schedulaRiflessione(...)`, dopo le righe che impostano `contenuto.title/body/sound/threadIdentifier`, aggiungi:
```swift
        contenuto.categoryIdentifier = Self.categoriaRiflessione
```

- [ ] **Step 3: Build** → BUILD SUCCEEDED.

- [ ] **Step 4: Commit**
```bash
git add Equinozio/Domain/PromemoriaService.swift
git commit -m "feat: categoria notifica + azione 'Rifletti ora'"
```

---

## Task 3: NotificationeDelegate + wiring (build)

**Files:** Create `Equinozio/Domain/NotificationeDelegate.swift`; Modify `Equinozio/EquinozioApp.swift`.

- [ ] **Step 1: Crea il delegate** `Equinozio/Domain/NotificationeDelegate.swift`:

```swift
//
//  NotificationeDelegate.swift
//  Equinozio · Domain
//
//  Instrada il tap sulla notifica (o l'azione "Rifletti ora") verso la Riflessione.
//

import Foundation
import UserNotifications

public final class NotificationeDelegate: NSObject, UNUserNotificationCenterDelegate {

    public static let shared = NotificationeDelegate()

    /// Collegata dall'app al router (es. { scheda in router.scheda = scheda }).
    public var onApri: ((Scheda) -> Void)?

    private override init() { super.init() }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.actionIdentifier
        if id == PromemoriaService.azioneRifletti || id == UNNotificationDefaultActionIdentifier {
            DispatchQueue.main.async { [weak self] in
                self?.onApri?(.riflessione)
            }
        }
        completionHandler()
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
```

- [ ] **Step 2: Wiring in `EquinozioApp`.** Leggi il file. Nella `.onAppear` esistente sullo ZStack del `WindowGroup` (quella che gestisce lo sblocco), aggiungi in fondo alla closure:
```swift
                NotificationeDelegate.shared.onApri = { scheda in router.scheda = scheda }
                UNUserNotificationCenter.current().delegate = NotificationeDelegate.shared
                PromemoriaService.shared.registraCategorie()
```
Assicurati che `import UserNotifications` sia presente in EquinozioApp.swift (aggiungilo in cima se manca).

- [ ] **Step 3: Build** → BUILD SUCCEEDED. (Se la strict concurrency segnala il capture in `DispatchQueue.main.async`, è in Swift 5 mode → di norma compila; se emergesse un errore, marca il delegate `@MainActor` e usa le varianti `async` dei metodi delegate.)

- [ ] **Step 4: Test** (no regressioni) → verde.

- [ ] **Step 5: Commit**
```bash
git add Equinozio/Domain/NotificationeDelegate.swift Equinozio/EquinozioApp.swift
git commit -m "feat: delegate notifiche — tap/azione aprono la Riflessione"
```

---

## Task 4: Corpo = Spunto, in sync (build)

**Files:** Modify `Equinozio/Features/Impostazioni/ImpostazioniView.swift`, `Equinozio/Domain/SpuntoStore.swift`.

- [ ] **Step 1: ImpostazioniView usa lo Spunto come corpo.** Leggi il file. In `riprogramma()`, nella chiamata `await PromemoriaService.shared.schedulaRiflessione(...)`, cambia l'argomento `corpo:` da `promemoriaTesto` a:
```swift
            corpo: PromemoriaService.corpo(spunto: WidgetSnapshot.leggiSpunto(), personalizzato: promemoriaTesto)
```
(Gli altri argomenti — giorno/ora/minuto/titolo — restano invariati.)

- [ ] **Step 2: SpuntoStore riprogramma la notifica quando lo Spunto cambia.** In `SpuntoStore.rigenera(...)`, dopo `WidgetCenter.shared.reloadAllTimelines()`, aggiungi:
```swift
        // Se il promemoria è attivo, aggiorna la notifica col nuovo Spunto.
        let difese = UserDefaults.standard
        if difese.bool(forKey: "promemoriaRiflessione") {
            let stato = await PromemoriaService.shared.statoAutorizzazione()
            if stato == .authorized || stato == .provisional {
                let giorno = difese.object(forKey: "promemoriaGiorno") as? Int ?? 1
                let ora = difese.object(forKey: "promemoriaOra") as? Int ?? 19
                let minuto = difese.object(forKey: "promemoriaMinuto") as? Int ?? 0
                let personalizzato = difese.string(forKey: "promemoriaTesto")
                    ?? "Cinque minuti per la tua riflessione settimanale."
                await PromemoriaService.shared.schedulaRiflessione(
                    giorno: giorno, ora: ora, minuto: minuto,
                    titolo: "Riflessione settimanale",
                    corpo: PromemoriaService.corpo(spunto: spunto.testo, personalizzato: personalizzato)
                )
            }
        }
```
(`spunto` è l'`InsightGenerato` appena generato, in scope nella funzione. `import UserNotifications` non serve in SpuntoStore — `statoAutorizzazione`/`schedulaRiflessione` sono su `PromemoriaService`.)

- [ ] **Step 3: Build** → BUILD SUCCEEDED.

- [ ] **Step 4: Test** (no regressioni) → verde.

- [ ] **Step 5: Commit**
```bash
git add Equinozio/Features/Impostazioni/ImpostazioniView.swift Equinozio/Domain/SpuntoStore.swift
git commit -m "feat: corpo della notifica = Spunto (fallback personalizzato), in sync"
```

---

## Task 5: Verifica finale

- [ ] **Step 1: Suite unit** → `** TEST SUCCEEDED **`.
- [ ] **Step 2: Build** → `** BUILD SUCCEEDED **`.
- [ ] **Step 3: Controllo su device:** attiva il promemoria in Impostazioni → arriva la notifica settimanale; il corpo riporta lo Spunto della settimana (su iOS 26 scritto dall'AI); l'azione "Rifletti ora" e il tap aprono la scheda Riflessione.

---

## Self-Review
- **Copertura spec (Fase B):** corpo = Spunto + fallback → Task 1/4 ✓ · azione "Rifletti ora" + categoria → Task 2 ✓ · delegate instrada a Riflessione (deep link) → Task 3 ✓ · sync del corpo quando lo Spunto cambia → Task 4 ✓.
- **Placeholder:** nessuno; codice completo + comandi.
- **Coerenza tipi:** `PromemoriaService.corpo(spunto:personalizzato:)`, `.categoriaRiflessione`/`.azioneRifletti`, `.registraCategorie()`, `schedulaRiflessione(giorno:ora:minuto:titolo:corpo:)` (esistente, Fase 2); `WidgetSnapshot.leggiSpunto()` usa `suite`/`chiaveSpuntoTesto` (esistenti); `NotificationeDelegate.shared.onApri`; `Scheda.riflessione`; chiavi AppStorage `promemoriaRiflessione/Giorno/Ora/Minuto/Testo` (Fase 2).
- **Onestà:** logica del corpo coperta da unit test; categoria/azione/delegate/sync verificati via build + prova su device (UNUserNotificationCenter non è unit-testabile).
