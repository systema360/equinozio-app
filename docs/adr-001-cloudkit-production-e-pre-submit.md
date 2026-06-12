# ADR-001: Deploy schema CloudKit in Production e runbook pre-submit

**Stato:** Accettato
**Data:** 12 giugno 2026
**Decisori:** Giuseppe (Systema360)

## Contesto

Equinozio sincronizza SwiftData con CloudKit (database privato, container `iCloud.it.systema360.equinozio`, 7 modelli: Profilo, Cerchio, Elemento, Pagina, Riflessione, Decisione, Insight). L'ambiente **Development** crea lo schema "just in time" quando l'app esporta record; l'ambiente **Production** è bloccato: i record type devono esistere *prima* che gli utenti App Store li scrivano, altrimenti la sync fallisce silenziosamente. Le build TestFlight e App Store usano **Production**; le build Xcode usano Development.

Rischio chiave: i campi opzionali mai valorizzati in sviluppo **non compaiono** nello schema Development e quindi non arrivano in Production col deploy.

## Decisione

Inizializzare lo schema con `NSPersistentCloudKitContainer.initializeCloudKitSchema()` tramite helper solo-DEBUG (`SchemaCloudKitDebug.swift`, già aggiunto), che genera il managed object model dai tipi SwiftData con `NSManagedObjectModel.makeManagedObjectModel(for:)`. Si attiva con l'argomento di lancio `-inizializza-schema-cloudkit`.

## Opzioni considerate

### Opzione A — Helper DEBUG con `initializeCloudKitSchema()` ✅ scelta

| Dimensione | Valutazione |
|---|---|
| Complessità | Bassa (~70 righe, solo DEBUG, inerte in Release) |
| Completezza schema | Totale: tutti i record type e tutti i campi, anche opzionali |
| Ripetibilità | Alta: si rilancia a ogni modifica dei modelli |

**Pro:** elimina il rischio dei campi mancanti; procedura documentata e ripetibile.
**Contro:** drop-down a Core Data; operazione di rete costosa (va usata solo su richiesta).

### Opzione B — Esercizio manuale dell'app in Development

| Dimensione | Valutazione |
|---|---|
| Complessità | Nessun codice |
| Completezza schema | A rischio: ogni campo opzionale va valorizzato a mano |
| Ripetibilità | Bassa, error-prone |

**Pro:** zero codice. **Contro:** un campo dimenticato = sync rotta in produzione, scoperta solo dagli utenti.

## Trade-off

L'opzione A costa un file di debug ma rende lo schema deterministico. Con 7 modelli ricchi di campi opzionali, B non è affidabile.

## Conseguenze

- Diventa facile: rigenerare lo schema a ogni evoluzione dei modelli (lanciare con l'argomento, poi ri-deployare).
- Diventa vincolante: dopo il primo deploy, lo schema Production è **solo additivo** (niente rename/delete di campi o record type). Le modifiche ai modelli vanno pensate come additive.
- Da rivisitare: se in futuro si aggiunge un nuovo `@Model` alla Schema, aggiornarlo anche nell'array di `SchemaCloudKitDebug`.

## Runbook — dal deploy dello schema al submit

### 1. Schema CloudKit in Production (blocco critico)

1. In Xcode: Edit Scheme → Run → Arguments → aggiungi `-inizializza-schema-cloudkit`.
2. Avvia l'app (build DEBUG) su simulatore o device **con account iCloud attivo**; attendi nei log `✅ Schema CloudKit inizializzato`.
3. Rimuovi l'argomento dallo scheme.
4. [CloudKit Console](https://icloud.developer.apple.com) → container `iCloud.it.systema360.equinozio` → ambiente **Development** → Schema: verifica i record type `CD_Profilo`, `CD_Cerchio`, `CD_Elemento`, `CD_Pagina`, `CD_Riflessione`, `CD_Decisione`, `CD_Insight`.
5. **Deploy Schema Changes…** → rivedi il diff → conferma il deploy in **Production**.
6. ⚠️ Da ripetere (init + deploy) a ogni modifica dei modelli, **prima** di rilasciare l'aggiornamento.

### 2. Archive e verifica entitlements

1. Product → Archive (Any iOS Device, Release).
2. Organizer → archivio → ispeziona gli entitlements: `aps-environment = production` (col signing automatico lo imposta l'archive; in repo resta `development`, è normale).
3. **Validate App** prima dell'upload.

### 3. Verifica sync in Production (TestFlight)

1. Distribute App → App Store Connect → TestFlight interno.
2. Installa via TestFlight (usa Production), crea dati di ogni tipo (profilo, cerchi, elementi, pagina di diario, riflessione, decisione, spunto).
3. Secondo dispositivo con lo **stesso** Apple ID: verifica che i dati arrivino. In assenza di secondo dispositivo: reinstalla da TestFlight dopo una cancellazione e verifica il ripristino da iCloud.
4. Test con un Apple ID **diverso**: la sync deve partire da zero senza errori (Console → Logs per eventuali errori di schema).

### 4. App Store Connect (in parallelo)

- Scheda app: nome Equinozio, lingua italiano, bundle `it.systema360.equinozio`, SKU, categoria Stile di vita, prezzo gratis, disponibilità **solo Italia**.
- Screenshot 6.9" e 6.7"; descrizione, promo, keyword.
- Privacy: nutrition label **"Data Not Collected"**; Privacy Policy URL `https://equinozio.app/privacy` (deploy del sito **prima** del submit).
- Nuovo questionario età (risposte su wellness/AI come da report compliance, atteso 4+).
- Support URL `https://systema360.it`, Marketing URL `https://equinozio.app`.
- Note per il revisore: niente account, funziona offline, nessuna credenziale demo.

### 5. Dopo l'approvazione

- CMS (Filament): `app_state = online` + URL App Store reale.
- Tag git `v1.0-build1`.

## Stato verificato oggi

✅ Icona 1024×1024 RGB senza alpha · ✅ FoundationModels correttamente gated `#available(iOS 26)` su target 18.0 · ✅ Privacy manifest app+widget · ✅ Entitlements iCloud/CloudKit/aps · ✅ Versione 1.0 (1) · ✅ Trader status DSA · ✅ Helper schema aggiunto e agganciato in `EquinozioApp.init` (DEBUG).

## Azioni

1. [ ] Push su GitHub (`git push -u origin main` dal Mac — credenziali nel portachiavi)
2. [ ] Eseguire runbook §1 (schema in Production)
3. [ ] Deploy sito equinozio.app (privacy URL deve rispondere)
4. [ ] Archive + Validate + TestFlight (§2–3)
5. [ ] Completare scheda App Store Connect (§4)
6. [ ] Submit for review
