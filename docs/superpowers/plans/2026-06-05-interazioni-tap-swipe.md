# Interazioni — tap + swipe ovunque utile — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Rendere navigabili al tap le righe della Mappa e abilitare azioni swipe reali (cancella/condividi/riapri) nelle liste di Diario, Decisione e Storico, più la rimozione delle voci custom in Esplorazione.

**Architecture:** Le liste che oggi sono `LazyVStack` dentro `ScrollView` vengono convertite in `List` stilizzata (`.plain`, righe senza separatori, sfondo trasparente, insets custom) — gli `.swipeActions` funzionano **solo** dentro `List`. Il tap usa `AppRouter` (già in environment). Un solo pezzo di logica pura (`Scheda.perInsight`) è coperto da test; il resto è UI verificata via build.

**Tech Stack:** SwiftUI, SwiftData, Swift Testing. Lavorare su `main`.

---

## Convenzioni
- **Test:** `xcodebuild test -scheme Equinozio -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:EquinozioTests CODE_SIGNING_ALLOWED=NO 2>&1 | tail -20`
- **Build:** `xcodebuild -scheme Equinozio -destination 'generic/platform=iOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO 2>&1 | tail -4` → `** BUILD SUCCEEDED **`
- Token `S.*`/`R.*`/`Color.*`/`Font.equinozio`; mai bold. **Rileggere** i file prima di editare (l'utente edita in parallelo) e adattare alla struttura corrente, preservando l'aspetto a card.

## File Structure
- `Equinozio/AppRouter.swift` — `Scheda.perInsight(_:)`.
- `Equinozio/Features/Mappa/MappaView.swift` + `Mappa/BloccoInsight.swift` — tap navigazione.
- `Equinozio/Features/Diario/DiarioView.swift` — List + swipe.
- `Equinozio/Features/Decisione/DecisioneView.swift` — List + swipe.
- `Equinozio/Features/Riflessione/StoricoRiflessioniView.swift` — List + swipe.
- `Equinozio/Features/Esplorazione/EsplorazioneView.swift` — rimozione voci custom.
- Test: `EquinozioTests/DeepLinkTests.swift` (estende).

---

## Task 1: Mappa — tap navigazione (TDD per la mappatura)

**Files:** Modify `Equinozio/AppRouter.swift`, `Equinozio/Features/Mappa/BloccoInsight.swift`, `Equinozio/Features/Mappa/MappaView.swift`; Test `EquinozioTests/DeepLinkTests.swift`.

- [ ] **Step 1: Test che fallisce** — aggiungi dentro `struct DeepLinkTests`:
```swift
    @Test func insightInstradaAllaScheda() {
        #expect(Scheda.perInsight(.bilanciamentoBasso) == .riflessione)
        #expect(Scheda.perInsight(.dominanzaCerchio) == .riflessione)
        #expect(Scheda.perInsight(.crescitaTrend) == .riflessione)
        #expect(Scheda.perInsight(.decisioneStorica) == .decisione)
    }
```

- [ ] **Step 2: Run, verify FAIL** (`Scheda.perInsight` undefined).

- [ ] **Step 3: Implementa** in `Equinozio/AppRouter.swift` (dentro l'extension `Scheda`):
```swift
    /// Scheda pertinente al tipo di Spunto (per il tap sulle card "Spunti").
    static func perInsight(_ tipo: TipoInsight) -> Scheda {
        switch tipo {
        case .bilanciamentoBasso, .dominanzaCerchio, .crescitaTrend: return .riflessione
        case .decisioneStorica: return .decisione
        }
    }
```

- [ ] **Step 4: Run, verify PASS.**

- [ ] **Step 5: BloccoInsight toccabile.** In `Equinozio/Features/Mappa/BloccoInsight.swift`:
(a) aggiungi una closure opzionale alla struct:
```swift
    var onTap: ((TipoInsight) -> Void)? = nil
```
(b) avvolgi ogni card (il contenuto dentro il `ForEach(insight)`) in un `Button`. Sostituisci l'`HStack { ... }` della card con:
```swift
                        Button {
                            onTap?(spunto.tipo)
                        } label: {
                            HStack(alignment: .top, spacing: S.x3) {
                                // ... contenuto card invariato (icona + testo) ...
                            }
                            .padding(S.x4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.superficie)
                            .clipShape(RoundedRectangle(cornerRadius: R.r2))
                            .overlay(
                                RoundedRectangle(cornerRadius: R.r2)
                                    .stroke(Color.lineaSottile, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
```
(Mantieni icona/testo esistenti dentro l'HStack; cambia solo l'involucro in Button.)

- [ ] **Step 6: MappaView — router + righe toccabili.** In `Equinozio/Features/Mappa/MappaView.swift`:
(a) aggiungi `@Environment(AppRouter.self) private var router` con le altre proprietà.
(b) passa la closure a BloccoInsight: `BloccoInsight(insight: insight) { tipo in router.scheda = Scheda.perInsight(tipo) }`.
(c) rendi le righe "Attività recente" toccabili: avvolgi ciascuna `rigaAttività(...)` in un `Button` che imposta la scheda. Esempio per le tre righe:
```swift
                Button { router.scheda = .diario } label: {
                    rigaAttività(titolo: "Diario", valore: ..., sottoTitolo: ..., icona: "book.closed")
                }
                .buttonStyle(.plain)

                Button { router.scheda = .riflessione } label: {
                    rigaAttività(titolo: "Riflessioni", ...)
                }
                .buttonStyle(.plain)

                Button { router.scheda = .decisione } label: {
                    rigaAttività(titolo: "Decisioni aperte", ...)
                }
                .buttonStyle(.plain)
```
(mantieni gli argomenti esistenti di `rigaAttività`).
(d) aggiorna il `#Preview` di MappaView aggiungendo `.environment(AppRouter())` prima di `.modelContainer(...)`.

- [ ] **Step 7: Build** → BUILD SUCCEEDED.

- [ ] **Step 8: Commit**
```bash
git add Equinozio/AppRouter.swift Equinozio/Features/Mappa/BloccoInsight.swift Equinozio/Features/Mappa/MappaView.swift EquinozioTests/DeepLinkTests.swift
git commit -m "feat: Mappa — tap su attività e spunti apre la scheda (Scheda.perInsight, TDD)"
```

---

## Task 2: Diario — List + swipe (cancella reale + condividi)

**Files:** Modify `Equinozio/Features/Diario/DiarioView.swift`.

Leggi il file. Oggi: `ScrollView { VStack { titolo; (ESPORTA); campoRicerca; filtroChips; LazyVStack { ForEach(pagineFiltrate){ Button{...} label:{PaginaCella} .swipeActions(...) .contextMenu(...) } } } }` dentro un `ZStack` con il FAB e la banner undo.

- [ ] **Step 1: Converti a header + List.** Sostituisci la struttura `ScrollView { VStack { header... ; LazyVStack {...} } }` con:
```swift
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // titolo + (ESPORTA ShareLink) + campoRicerca + filtroChips — invariati
                }
                .padding(.horizontal, S.x5)
                .padding(.top, S.x7)
                .padding(.bottom, S.x3)

                if pagineFiltrate.isEmpty {
                    ScrollView { statoVuoto.padding(.horizontal, S.x5) }
                } else {
                    List {
                        ForEach(pagineFiltrate) { pagina in
                            Button {
                                paginaSelezionata = pagina
                            } label: {
                                PaginaCella(pagina: pagina)
                            }
                            .buttonStyle(.plain)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: S.x5, bottom: 0, trailing: S.x5))
                            .listRowBackground(Color.sfondo)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { cancella(pagina) } label: {
                                    Label("Cancella", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                ShareLink(item: pagina.testo) {
                                    Label("Condividi", systemImage: "square.and.arrow.up")
                                }
                                .tint(.salvia)
                            }
                            .contextMenu {
                                Button(role: .destructive) { cancella(pagina) } label: {
                                    Label("Cancella pagina", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.sfondo)
```
Mantieni il `ZStack(alignment: .bottomTrailing)` esterno con il FAB e la banner undo, e gli `.sheet(...)` (composer + dettaglio) invariati. Rimuovi la vecchia `LazyVStack` e i suoi `Divider`.

- [ ] **Step 2: Build** → BUILD SUCCEEDED.

- [ ] **Step 3: Test** (no regressioni) → verde.

- [ ] **Step 4: Commit**
```bash
git add Equinozio/Features/Diario/DiarioView.swift
git commit -m "feat: Diario in List — swipe cancella (reale, con undo) + swipe condividi"
```

---

## Task 3: Decisione — List + swipe (cancella / riapri)

**Files:** Modify `Equinozio/Features/Decisione/DecisioneView.swift`.

Leggi il file. Oggi: `ScrollView { VStack { intestazione; selettoreModalita; LazyVStack { ForEach(elencoCorrente){ DecisioneCella(decisione:d).onTapGesture { decisioneSelezionata = d } } } } }` in un `ZStack` col FAB.

- [ ] **Step 1: Aggiungi le azioni** in `DecisioneView` (servono `@Environment(\.modelContext) private var contesto` — già presente):
```swift
    private func cancella(_ d: Decisione) {
        withAnimation { contesto.delete(d); try? contesto.save() }
    }
    private func riapri(_ d: Decisione) {
        withAnimation { d.decisione = nil; try? contesto.save() }
    }
```

- [ ] **Step 2: Converti a header + List.** Sostituisci `ScrollView { VStack { intestazione; selettoreModalita; (statoVuoto | LazyVStack{...}) } }` con:
```swift
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    intestazione
                    selettoreModalita.padding(.top, S.x4)
                }
                .padding(.horizontal, S.x5)
                .padding(.top, S.x7)
                .padding(.bottom, S.x3)

                if elencoCorrente.isEmpty {
                    ScrollView { statoVuoto.padding(.horizontal, S.x5) }
                } else {
                    List {
                        ForEach(elencoCorrente) { d in
                            DecisioneCella(decisione: d)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: S.x2, leading: S.x5, bottom: S.x2, trailing: S.x5))
                                .listRowBackground(Color.sfondo)
                                .contentShape(Rectangle())
                                .onTapGesture { decisioneSelezionata = d }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) { cancella(d) } label: {
                                        Label("Cancella", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    if modalità == .archivio {
                                        Button { riapri(d) } label: {
                                            Label("Riapri", systemImage: "arrow.uturn.backward")
                                        }
                                        .tint(.salvia)
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.sfondo)
```
Mantieni il `ZStack` col FAB (mostrato in `.aperte`) e gli `.sheet(...)` invariati.

- [ ] **Step 3: Build** → BUILD SUCCEEDED.

- [ ] **Step 4: Test** (no regressioni) → verde.

- [ ] **Step 5: Commit**
```bash
git add Equinozio/Features/Decisione/DecisioneView.swift
git commit -m "feat: Decisione in List — swipe cancella + swipe riapri (in Archivio)"
```

---

## Task 4: Storico Riflessioni — List + swipe cancella

**Files:** Modify `Equinozio/Features/Riflessione/StoricoRiflessioniView.swift`.

Leggi il file. Oggi: `NavigationStack { ScrollView { VStack { (bannerIntro); sintesi; notaEquilibrio; grafico; lista(LazyVStack di rigaRiflessione, ognuna Button → inModifica) } } .toolbar{...} .sheet(item:$inModifica){...} }`.

- [ ] **Step 1: Aggiungi modelContext + cancella.** In `StoricoRiflessioniView`, aggiungi `@Environment(\.modelContext) private var contesto` e:
```swift
    private func cancella(_ r: Riflessione) {
        withAnimation { contesto.delete(r); try? contesto.save() }
    }
```

- [ ] **Step 2: Converti il corpo in `List`** mantenendo intestazioni come righe. Sostituisci lo `ScrollView { VStack {...} }` con una `List` in cui sintesi/nota/grafico/banner sono righe senza separatore e le riflessioni hanno lo swipe:
```swift
            List {
                if !introLetta && !riflessioni.isEmpty {
                    bannerIntro.listRowSeparator(.hidden).listRowInsets(EdgeInsets(top: S.x4, leading: S.x5, bottom: 0, trailing: S.x5)).listRowBackground(Color.sfondo)
                }
                sintesi.listRowSeparator(.hidden).listRowInsets(EdgeInsets(top: S.x4, leading: S.x5, bottom: 0, trailing: S.x5)).listRowBackground(Color.sfondo)
                notaEquilibrio.listRowSeparator(.hidden).listRowInsets(EdgeInsets(top: S.x2, leading: S.x5, bottom: 0, trailing: S.x5)).listRowBackground(Color.sfondo)
                if riflessioni.count >= 2 {
                    grafico.listRowSeparator(.hidden).listRowInsets(EdgeInsets(top: S.x4, leading: S.x5, bottom: 0, trailing: S.x5)).listRowBackground(Color.sfondo)
                }

                Text("TUTTE LE RIFLESSIONI")
                    .font(.equinozio(.etichetta)).tracking(2.0).foregroundStyle(Color.attenuato)
                    .listRowSeparator(.hidden).listRowInsets(EdgeInsets(top: S.x5, leading: S.x5, bottom: S.x2, trailing: S.x5)).listRowBackground(Color.sfondo)

                if riflessioni.isEmpty {
                    Text("Niente ancora. Le riflessioni che salvi appariranno qui.")
                        .font(.equinozio(.corpoMedio)).foregroundStyle(Color.attenuato)
                        .listRowSeparator(.hidden).listRowInsets(EdgeInsets(top: 0, leading: S.x5, bottom: S.x4, trailing: S.x5)).listRowBackground(Color.sfondo)
                } else {
                    ForEach(riflessioni) { r in
                        Button { inModifica = r } label: { rigaRiflessione(r) }
                            .buttonStyle(.plain)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: S.x1, leading: S.x5, bottom: S.x1, trailing: S.x5))
                            .listRowBackground(Color.sfondo)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { cancella(r) } label: {
                                    Label("Cancella", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.sfondo)
```
Rimuovi la vecchia `lista` (LazyVStack) e il suo titolo duplicato (ora è una riga della List). Mantieni `.toolbar { ... }` e `.sheet(item: $inModifica) { ... }` sul `List`/`NavigationStack`. La computed `grafico`/`sintesi`/`notaEquilibrio`/`bannerIntro` restano invariate (sono `some View`, usabili come righe).

- [ ] **Step 3: Build** → BUILD SUCCEEDED.

- [ ] **Step 4: Test** (no regressioni) → verde.

- [ ] **Step 5: Commit**
```bash
git add Equinozio/Features/Riflessione/StoricoRiflessioniView.swift
git commit -m "feat: Storico in List — swipe cancella una riflessione passata"
```

---

## Task 5: Esplorazione — rimuovi voci custom

**Files:** Modify `Equinozio/Features/Esplorazione/EsplorazioneView.swift`.

Leggi il file. Le voci custom sono nel secondo `ForEach(scelteCustom, id: \.self) { opzione in Scelta(opzione, attiva: bindingFor(opzione)) }` dentro la `FlowLayout`.

- [ ] **Step 1: Aggiungi il metodo di rimozione** in `EsplorazioneView`:
```swift
    private func rimuoviCustom(_ opzione: String) {
        var s = sceltePerCerchio[tipoCorrente] ?? []
        s.remove(opzione)
        sceltePerCerchio[tipoCorrente] = s
    }
```

- [ ] **Step 2: contextMenu sui chip custom.** Modifica SOLO il `ForEach(scelteCustom, ...)` aggiungendo un context menu (i chip sono in FlowLayout, non List → niente swipe):
```swift
                    ForEach(scelteCustom, id: \.self) { opzione in
                        Scelta(opzione, attiva: bindingFor(opzione))
                            .contextMenu {
                                Button(role: .destructive) { rimuoviCustom(opzione) } label: {
                                    Label("Rimuovi", systemImage: "trash")
                                }
                            }
                    }
```
(Il primo `ForEach(opzioniCorrenti, ...)` — i suggerimenti predefiniti — resta invariato.)

- [ ] **Step 3: Build** → BUILD SUCCEEDED.

- [ ] **Step 4: Commit**
```bash
git add Equinozio/Features/Esplorazione/EsplorazioneView.swift
git commit -m "feat: Esplorazione — rimuovi le voci custom (context menu)"
```

---

## Task 6: Verifica finale

- [ ] **Step 1: Suite unit** → `** TEST SUCCEEDED **`.
- [ ] **Step 2: Build** → `** BUILD SUCCEEDED **`.
- [ ] **Step 3: Controllo su device:** in Mappa, tap su attività/spunti apre la scheda giusta; nel Diario swipe→Cancella (con Annulla) e swipe←Condividi; in Decisione swipe→Cancella (e Riapri in Archivio); nello Storico swipe→Cancella; in Esplorazione, tieni premuto un chip custom → Rimuovi.

---

## Self-Review
- **Copertura design:** Mappa tap (righe + spunti) → Task 1 ✓ · Diario swipe → Task 2 ✓ · Decisione swipe → Task 3 ✓ · Storico swipe → Task 4 ✓ · Esplorazione rimozione custom → Task 5 ✓.
- **Placeholder:** nessuno; codice completo per helper/swipe/tap/contextMenu; le conversioni a List danno la struttura target e indicano di adattare il contenuto esistente (titoli/celle invariati).
- **Coerenza tipi:** `Scheda.perInsight(_:)`, `AppRouter` (env), `BloccoInsight(insight:onTap:)`, `cancella(_:)`/`riapri(_:)`/`rimuoviCustom(_:)`; `EsportaDiario`/`pagina.testo` per la condivisione; `inModifica`/`ModificaRiflessioneView` (Tema 1) invariati.
- **Nota tecnica:** gli `.swipeActions` ora sono in `List` (prima in `LazyVStack` = non funzionanti) → oltre alle nuove azioni, è un fix dello swipe del Diario.
- **Onestà:** solo `Scheda.perInsight` è unit-testato; le conversioni List/swipe/tap/contextMenu si verificano via build + prova su device.
