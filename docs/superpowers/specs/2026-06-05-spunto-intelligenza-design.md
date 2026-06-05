# Equinozio — "Lo Spunto": intelligenza on-device, widget e notifiche — Design

**Data:** 2026-06-05
**Autore:** Giuseppe (Systema360) + Claude
**Stato:** in attesa di revisione

---

## 1. Contesto e obiettivo

Equinozio è l'app iOS (SwiftUI + SwiftData + CloudKit, offline-first, gratis) di Systema360, vetrina dello studio. Esiste già: il widget Home Screen (`EquinozioWidget`, small/medium/large che mostra l'equilibrio + i quattro cerchi, legge un App Group), il generatore di insight a regole (`GeneratoreInsight` in Domain), il `@Model Insight` (definito ma **inutilizzato**), `WidgetSnapshot` (scrive l'equilibrio nell'App Group), `PromemoriaService` (notifica settimanale), e l'uso dei **Foundation Models on-device** in `TagSuggestionService` (iOS 26, con fallback a regole).

**Obiettivo:** legare widget, notifiche e Apple Intelligence in un unico filo — **"lo Spunto"** — invece di tre funzioni scollegate. Un'unica intelligenza on-device genera un'osservazione personale settimanale, riusata in app, nel widget e nella notifica.

Deployment target app: **iOS 18**. I Foundation Models richiedono **iOS 26** + device compatibile → l'AI è **miglioria progressiva** (gating + fallback), tutto il resto funziona da iOS 18.

---

## 2. Concetto: un'intelligenza, tre superfici

Un solo motore genera **lo Spunto della settimana**: una frase breve, gentile, personale, ricavata dai dati (andamento equilibrio, cerchio dominante, trend, decisioni in scadenza, temi del diario). Lo stesso Spunto, generato una volta e messo in cache, compare in tre punti:

1. **In-app (Mappa)** — il blocco `BloccoInsight` mostra lo Spunto.
2. **Widget** — equilibrio + testo dello Spunto; tap → apre la scheda pertinente (deep link).
3. **Notifica** — il promemoria settimanale porta lo Spunto + azione "Rifletti ora".

**Motore ibrido (deciso):** le **regole** rilevano la situazione (deterministiche, sicure, con i numeri esatti) → i **Foundation Models** riformulano la frase in modo caldo e vario, ricevendo i numeri come fatti immutabili (niente invenzioni). Se l'AI non è disponibile → si usa il testo a regole odierno. Nessuna regressione.

**Tutto on-device, nessun server** — coerente con la privacy dell'app e forte segnale-vetrina.

---

## 3. Architettura e componenti

### 3.1 `MotoreSpunti` (Domain) — evoluzione di `GeneratoreInsight`
- API: `static func situazioni(riflessioni:, decisioni:, pagine:, adesso:) -> [SpuntoSituazione]` (puro, a regole) e `func genera(...) async -> [SpuntoGenerato]` che, per ogni situazione prioritaria, produce il testo (AI se disponibile, altrimenti la frase a regole).
- `SpuntoSituazione`: enum/struct con `tipo: TipoInsight`, i fatti numerici (es. equilibrio, quota/nome cerchio, delta, n. decisioni) e una **frase-regola di fallback**.
- `SpuntoGenerato`: `{ id, tipo: TipoInsight, testo: String }` (come l'attuale `InsightGenerato`, che viene assorbito/rinominato).
- Le regole sono quelle già esistenti e testate in `GeneratoreInsight` (bilanciamentoBasso, dominanzaCerchio, crescitaTrend, decisioneStorica) + una nuova opzionale su temi del diario.
- L'AI vive dietro `if #available(iOS 26)` riusando il pattern di `TagSuggestionService` (`LanguageModelSession`).

### 3.2 `SpuntoStore` — generazione una volta, cache condivisa
- Salva lo Spunto principale della settimana nel **`@Model Insight`** (campo `testo`, `tipoRaw`, `dataGenerazione`) — finalmente usato; sincronizzato via CloudKit.
- Scrive anche nello **snapshot App Group** (`WidgetSnapshot` esteso): `equilibrio: Int`, `spuntoTesto: String`, `spuntoTipo: String`, `settimanaID: String`.
- Idempotente per settimana: se esiste già uno Spunto per la settimana corrente, non rigenera (a meno di cambi dati rilevanti).

### 3.3 Trigger di (ri)generazione
- Alla `salva()` di una Riflessione (i dati chiave sono cambiati).
- All'apertura dell'app (foreground) se lo Spunto in cache è di una settimana precedente.
- Dopo la scrittura: `WidgetCenter.shared.reloadAllTimelines()`.
- **Niente** BGTaskScheduler (il widget legge dalla cache; semplicità).

### 3.4 Deep link & routing
- Schema URL **`equinozio://`** registrato in `Info.plist` (`CFBundleURLTypes`).
- Nuovo `AppRouter` (`@Observable`, in Domain o App) con `scheda: Scheda`; iniettato in environment.
- `ContenitoreView` lega la selezione del `TabView`/sidebar a `router.scheda`.
- `EquinozioApp` gestisce `.onOpenURL` mappando host → `Scheda` (`equinozio://riflessione` → `.riflessione`, ecc.).

### 3.5 Widget (`EquinozioWidget`)
- Legge lo snapshot esteso (equilibrio + spuntoTesto) dall'App Group.
- Mostra equilibrio + (su medium/large) il testo dello Spunto.
- `.widgetURL(URL("equinozio://riflessione"))` (o la scheda pertinente al tipo di spunto) per il tap.
- **Fase C:** bottone interattivo via App Intent (`openAppWhenRun`) "Rifletti".

### 3.6 Notifica (`PromemoriaService`)
- Il corpo del promemoria settimanale = testo dello Spunto corrente (fallback al testo generico se assente).
- `UNNotificationCategory` con azione **"Rifletti ora"** → deep link `equinozio://riflessione`.
- Gestione tap/azioni via `UNUserNotificationCenterDelegate`.

### 3.7 App Intents & Siri (Fase C)
- `ApriRiflessioneIntent` (apre l'app alla Riflessione), `EquilibrioCorrenteIntent` (restituisce l'equilibrio corrente, da snapshot), `AppShortcutsProvider` per frasi Siri ("Com'è il mio equilibrio?", "Apri la riflessione di Equinozio") e presenza in Spotlight/Scorciatoie.
- Il widget interattivo riusa `ApriRiflessioneIntent`.

### 3.8 Writing Tools (Fase C)
- Su iOS 18.2+ i `TextEditor` (Diario, Decisione, Riflessione pensiero) ottengono i Writing Tools di sistema automaticamente; verificare che non siano disabilitati e che il flusso di salvataggio legga il testo aggiornato. Sforzo minimo.

---

## 4. Flusso dati (riassunto)

```
Dati (riflessioni, decisioni, pagine)
   │  (salva riflessione / foreground se stale)
   ▼
MotoreSpunti.situazioni() ──regole──▶ situazione + numeri + frase-fallback
   │
   ├─ iOS 26: Foundation Models riformulano → testo caldo
   └─ else:   testo a regole
   ▼
SpuntoStore  ──▶  @Model Insight (cache settimanale, iCloud)
             └─▶  App Group snapshot (equilibrio + spuntoTesto + …)
   │
   ├─▶ Mappa · BloccoInsight (legge dal modello/snapshot)
   ├─▶ WidgetCenter.reload → Widget (legge snapshot) → tap deep-link
   └─▶ PromemoriaService → notifica con Spunto + azione
```

---

## 5. Apple Intelligence (Foundation Models)

- **Solo on-device**, riusando il pattern di `TagSuggestionService` (`LanguageModelSession`, `if #available(iOS 26)`, disponibilità modello verificata a runtime).
- **Prompt vincolato (ibrido):** input = la situazione rilevata + i numeri esatti; output = **una frase** italiana, calma, in seconda persona, senza emoji, senza inventare numeri. I numeri sono passati come fatti e ripetuti dall'app, non "calcolati" dal modello.
- **Fallback:** se modello non disponibile/non pronto/errore → frase a regole. L'esperienza non degrada mai.
- (Opz., Fase C) **Riassunto settimanale del diario:** dato l'insieme delle pagine della settimana, una sintesi breve mostrata nello Storico/Mappa. Stesso gating e fallback (se assente, semplicemente non si mostra).

---

## 6. Fasi di implementazione (ogni fase = un piano separato)

- **Fase A — Motore + in-app + widget (MVP):** `MotoreSpunti` ibrido (regole testabili + frase AI gated), `SpuntoStore` (usa `Insight` + estende `WidgetSnapshot`), trigger di rigenerazione + `WidgetCenter` reload, `BloccoInsight` mostra lo Spunto, widget mostra lo Spunto, **deep link** (`equinozio://` + `AppRouter` + `.onOpenURL`) col tap del widget.
- **Fase B — Notifica che parla:** corpo del promemoria = Spunto; categoria + azione "Rifletti ora"; delegate per gestire l'azione (deep link).
- **Fase C — Apple Intelligence & interazione:** App Intents + `AppShortcutsProvider` (Siri/Spotlight/Scorciatoie), widget interattivo (bottone → intent), riassunto settimanale del diario AI, Writing Tools verificati.

---

## 7. iOS / compatibilità
- **iOS 18 (base):** widget arricchito, deep link, notifiche con azioni, spunti a regole, App Intents (gli App Intents sono iOS 16+). Tutto funziona.
- **iOS 26 (progressivo):** spunti scritti dall'AI, riassunto diario AI, Writing Tools (18.2+).
- Gating con `if #available`; nessuna feature AI è un requisito.

## 8. Privacy
- Tutta la generazione è **on-device**; nessun dato lascia il dispositivo. La cache `Insight` vive nell'iCloud privato dell'utente; lo snapshot widget nell'App Group locale. Coerente con il Manifesto e con la pagina privacy.

## 9. Testing
- **Unit (Swift Testing):** regole di `MotoreSpunti` (come gli attuali test di `GeneratoreInsight`), logica di cache/idempotenza settimanale (round-trip SwiftData in-memory), mappatura deep-link URL → `Scheda`.
- **Build-verified:** wiring SwiftUI (BloccoInsight, widget, Impostazioni), App Intents, notifiche, Writing Tools.
- La frase AI non è unit-testabile (modello); si verifica che il **fallback** a regole sia sempre valido e che il percorso AI sia dietro gating.
- Test eseguiti su simulatore **iPhone 17** (test target iOS 26.5), store in-memory sotto test runner (già in essere).

## 10. Fuori scope (per ora)
- **Live Activities / Dynamic Island** (un'app calma non ha un evento continuo → forzatura).
- **Widget Lock Screen (accessory*)** e **sparkline del trend** — add-on possibili più avanti.
- Qualsiasi generazione **server-side**.

## 11. Criteri di successo
- Un unico `MotoreSpunti` produce lo Spunto settimanale; in-app, widget e notifica mostrano **lo stesso** testo, generato una sola volta.
- Su iOS 26 lo Spunto è scritto dall'AI on-device con numeri corretti; su iOS 18 è a regole — senza differenze di affidabilità.
- Tap su widget e azione di notifica aprono la scheda giusta (deep link).
- Siri/Spotlight espongono almeno "apri riflessione" ed "equilibrio corrente".
- Nessuna regressione: build + suite unit verdi.
