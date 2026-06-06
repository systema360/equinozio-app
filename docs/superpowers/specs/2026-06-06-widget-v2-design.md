# Widget Equinozio v2 — Design

**Data:** 2026-06-06
**Stato:** approvato (in attesa di review utente sullo spec)

## Obiettivo

Trasformare il widget da semplice numero + pallini decorativi a una vista ricca e on-brand dell'equilibrio settimanale: proporzioni reali dei quattro cerchi, tendenza vs settimana precedente, stato "prima riflessione", e nuove famiglie per la schermata di blocco / StandBy.

## Contesto attuale

- `EquinozioWidget/EquinozioWidget.swift` — `StaticConfiguration`, famiglie `.systemSmall/.systemMedium/.systemLarge`. Mostra: numero equilibrio %, Spunto (medium/large), **nomi** dei quattro cerchi (pallini decorativi, nessun valore), marchio "Equinozio". Tap → `equinozio://riflessione`.
- Palette duplicata nel target widget (`cerchiEquinozio`): il widget NON importa il DesignSystem dell'app.
- `Equinozio/Domain/WidgetSnapshot.swift` — writer/reader App Group (suite `group.it.systema360.equinozio`). Chiavi attuali: `equilibrioCorrente`, `spuntoTesto`, `spuntoTipo`, `settimanaID`. Metodi: `aggiornaEquilibrio(_:)`, `aggiorna(equilibrio:spuntoTesto:spuntoTipo:settimanaID:)`, `leggiSpunto()`.
- `Equinozio/Domain/SpuntoStore.swift` — `rigenera(...)` e `aggiornaSeNecessario(...)` aggiornano lo snapshot e fanno `WidgetCenter.shared.reloadAllTimelines()`. Già leggono le riflessioni ordinate per data desc.
- `Riflessione` (in `Equinozio/Domain/Modelli.swift`) ha `quotaPassione/quotaTalento/quotaMissione/quotaProfessione: Int` e `equilibrio: Int` (computed).
- Entitlement App Group presente su entrambi i target.

## Decisioni di design

1. **Proporzioni cerchi:** barre per cerchio (nome + barra colorata riempita alla %). Nel widget piccolo, dove non c'è spazio per le etichette, una barra unica segmentata (4 segmenti colorati proporzionali).
2. **Tendenza:** delta `riflessioni[0].equilibrio − riflessioni[1].equilibrio` (mirror di MappaView), mostrato come freccia ↑/↓/→ + valore assoluto.
3. **Stato vuoto:** nessuna riflessione → invito ad agire al posto del numero (niente 50% di default).
4. **Lock Screen:** `accessoryCircular`, `accessoryRectangular`, `accessoryInline`.

## Architettura

### A. Dati condivisi (`WidgetSnapshot`)

Nuove chiavi nell'App Group:
- `quotaPassione`, `quotaTalento`, `quotaMissione`, `quotaProfessione` (Int)
- `trendDelta` (Int, signed; 0 se assente)
- `haTrend` (Bool)
- `haRiflessioni` (Bool)

Chiavi esistenti invariate (`equilibrioCorrente`, `spuntoTesto`, `spuntoTipo`, `settimanaID`).

Refactor dei writer per evitare duplicazione. Introdurre un tipo valore condiviso che modella lo stato numerico:

```swift
public struct MisureWidget: Equatable {
    public var equilibrio: Int
    public var passione, talento, missione, professione: Int
    public var delta: Int
    public var haTrend: Bool
    public var haRiflessioni: Bool
}
```

`MisureWidget` deve stare in un file compilato in **entrambi** i target (app + widget), così sia il writer (app) sia il reader (widget) usano lo stesso tipo e le stesse chiavi. Opzioni: (a) aggiungere il file `MisureWidget.swift` al membership del target widget; (b) tenere le chiavi come costanti condivise. **Scelta:** un file `Equinozio/Domain/MisureWidget.swift` con il `struct` + le costanti delle chiavi + funzioni pure di derivazione (vedi sotto), aggiunto anche al target `EquinozioWidget` via membership (NB: i file sotto `Equinozio/` sono auto-inclusi solo nel target app — questo file va aggiunto esplicitamente al target widget nel pbxproj, oppure duplicato; preferire l'aggiunta al membership per evitare drift).

Metodi `WidgetSnapshot`:
- `aggiornaMisure(_ m: MisureWidget)` — scrive equilibrio + quote + trend + haRiflessioni (tutto tranne lo Spunto).
- `aggiorna(misure:spuntoTesto:spuntoTipo:settimanaID:)` — scrive misure + Spunto (sostituisce l'attuale `aggiorna(equilibrio:...)`).
- `leggiMisure() -> MisureWidget` — lettura (default: `haRiflessioni=false`, equilibrio fallback 50).
- `leggiSpunto()` invariato (già con guard di freschezza settimana lato widget).
- `aggiornaEquilibrio(_:)` rimosso/sostituito da `aggiornaMisure`.

### B. Calcolo in `SpuntoStore`

In `rigenera` e nel ramo "Spunto già presente" di `aggiornaSeNecessario`, costruire `MisureWidget` dalle riflessioni:
- `equilibrio = riflessioni.first?.equilibrio ?? 50`
- quote da `riflessioni.first` (0 se assente)
- `delta = riflessioni.count >= 2 ? riflessioni[0].equilibrio - riflessioni[1].equilibrio : 0`
- `haTrend = riflessioni.count >= 2`
- `haRiflessioni = !riflessioni.isEmpty`

Funzione pura condivisa (in `MisureWidget.swift`, testabile):
```swift
public static func da(riflessioniEquilibri: [Int], quote: (Int,Int,Int,Int)?) -> MisureWidget
```
o equivalente che prende i valori già estratti — la firma esatta la fissa il piano, ma la logica delta/haTrend/haRiflessioni deve essere pura e unit-testata.

Punti di scrittura (invariati come momenti, aggiornati come payload):
- `rigenera` con Spunto valido → `aggiorna(misure:spuntoTesto:...)` + reload.
- `rigenera` con Spunto nil → `aggiornaMisure(...)` + reload.
- `aggiornaSeNecessario` con Spunto già presente → `aggiornaMisure(...)` + reload.
- Modifica riflessione → già chiama `rigenera` (fix precedente).

### C. Widget — Entry & Provider

`EquinozioEntry` estesa:
```swift
struct EquinozioEntry: TimelineEntry {
    let date: Date
    let misure: MisureWidget
    let spunto: String
}
```
Provider: `leggiMisure()` + `leggiSpunto()` (quest'ultimo con guard di freschezza già presente). Placeholder e #Preview aggiornati.

### D. Widget — Layout Home Screen

Derivazione larghezze barre: funzione pura `larghezzaBarra(quota:max:larghezzaPiena:)` o normalizzazione 0…100; segmenti della barra unica = quote normalizzate a somma 100 (le quote sommano già 100 per costruzione, ma normalizzare difensivamente). Testare la normalizzazione.

- **systemSmall:** EQUILIBRIO + numero + freccia tendenza; in basso barra unica segmentata (4 segmenti colorati proporzionali, no etichette). Se `!haRiflessioni`: stato vuoto.
- **systemMedium:** sinistra EQUILIBRIO + numero + tendenza + Spunto (lineLimit 2–3); destra 4 righe `nome + barra proporzionale colorata + %`. Marchio in basso a sinistra.
- **systemLarge:** EQUILIBRIO + numero grande + tendenza; `Divider`; Spunto (lineLimit 4); 4 barre etichettate con %; marchio.

Tendenza (Home): freccia `arrow.up`/`arrow.down`/`arrow.right` + `abs(delta)`; colore tenue (`.secondary`), nessun semaforo aggressivo.

### E. Stato "prima riflessione"

Quando `misure.haRiflessioni == false`, ogni famiglia mostra al posto del numero un invito (es. "Fai la tua prima riflessione", small più corto tipo "Inizia"). Resta il `widgetURL` → `equinozio://riflessione`.

### F. Lock Screen / StandBy

`supportedFamilies` aggiunge `.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline`. Ramo dedicato nella view (monocromatico, niente colori cerchi):
- **accessoryCircular:** `Gauge(value: Double(equilibrio), in: 0...100)` stile `.accessoryCircularCapacity` con il numero al centro.
- **accessoryRectangular:** "EQUILIBRIO" + "75% ↑3" + 1 riga di Spunto (se presente).
- **accessoryInline:** `Text("Equilibrio \(equilibrio)% \(frecciaInline)")`.
- Stato vuoto: circular gauge a 0 / testo "—"; rectangular "Fai una riflessione"; inline "Equinozio".

Le famiglie accessory richiedono che il widget sia compilato per iOS 16+ (già il caso).

## Componenti / file

- **Nuovo:** `Equinozio/Domain/MisureWidget.swift` — `struct MisureWidget`, costanti chiavi, funzioni pure (derivazione misure + normalizzazione barre). Membership: app + widget.
- **Modificato:** `Equinozio/Domain/WidgetSnapshot.swift` — nuovi writer/reader basati su `MisureWidget`.
- **Modificato:** `Equinozio/Domain/SpuntoStore.swift` — costruzione `MisureWidget` nei 3 punti di scrittura.
- **Modificato:** `EquinozioWidget/EquinozioWidget.swift` — Entry estesa, provider, layout barre per size, stato vuoto, famiglie accessory, preview.
- **Test:** `EquinozioTests/` — derivazione misure (delta/haTrend/haRiflessioni), normalizzazione barre, round-trip `WidgetSnapshot`.

## Flusso dati

Riflessione (nuova/modificata) o apertura app → `SpuntoStore` costruisce `MisureWidget` dalle riflessioni → `WidgetSnapshot` scrive nell'App Group → `reloadAllTimelines()` → Provider legge `MisureWidget` + Spunto (freschezza settimana) → view renderizza barre/tendenza/stato per famiglia.

## Gestione errori / edge case

- App Group non disponibile → reader ritorna default con `haRiflessioni=false` (stato vuoto), nessun crash.
- 0 riflessioni → stato vuoto in tutte le famiglie.
- 1 riflessione → `haTrend=false`, nessuna freccia.
- Quote che non sommano 100 → normalizzazione difensiva nella derivazione delle barre.
- Spunto di settimana vecchia → già filtrato dal guard di freschezza esistente.
- Lock screen monocromatico → nessuna dipendenza dai colori per leggibilità (gauge + testo).

## Testing

- **Unit (puro):** `MisureWidget.da(...)` per delta/haTrend/haRiflessioni su 0/1/2+ riflessioni; normalizzazione larghezze barre (quote che sommano 100 e non-100).
- **Round-trip:** scrivere `MisureWidget` via `WidgetSnapshot.aggiornaMisure` e rileggere con `leggiMisure` → uguaglianza (richiede suite App Group disponibile in test; se non lo è, testare la logica pura e documentare).
- **Visivo:** #Preview per ogni famiglia inclusi stato vuoto e accessory; verifica finale sul dispositivo dell'utente (il widget non è ispezionabile in simulatore con CloudKit).

## Fuori scope

- Bottone interattivo (AppIntent dentro al widget) — richiede condividere il tipo Intent col target widget (chirurgia pbxproj cross-target). Passo separato.
- Incorporare Hanken Grotesk nel target widget — il widget resta sul font di sistema (pesi thin/light), coerente con l'attuale.

## Sequenza di build suggerita

1. `MisureWidget.swift` (tipo + funzioni pure) + test puri.
2. `WidgetSnapshot` writer/reader + round-trip.
3. `SpuntoStore` costruzione misure nei 3 punti.
4. Widget: Entry/provider + layout Home (barre, tendenza, stato vuoto) + preview.
5. Widget: famiglie Lock Screen + preview.
6. Verifica finale build + test.
