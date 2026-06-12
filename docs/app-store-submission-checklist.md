# Equinozio — Checklist submit App Store

> Stato al 2026-06-12. ✅ = fatto · ⬜ = da fare · 🔁 = da verificare in fase di archive.
> Vedi anche `adr-001-cloudkit-production-e-pre-submit.md` (runbook) e `compliance-check-2026-06-12.md`.

## 1. Configurazione progetto (Xcode)

- ✅ Deployment target app **iOS 18.0** (i target di test sono a 26.5 — irrilevanti per il submit; opz. allinearli)
- ✅ Icona app 1024×1024 (single-size) — ✅ verificata 2026-06-12: PNG RGB **senza canale alpha**
- ✅ Launch screen (`UILaunchScreen`)
- ✅ `NSFaceIDUsageDescription` presente
- ✅ `UIBackgroundModes: remote-notification` (per sync CloudKit)
- ✅ Entitlements iCloud + CloudKit + aps-environment
- ✅ **`PrivacyInfo.xcprivacy`** creato (Tracking=false, Data Not Collected, UserDefaults reason CA92.1) e incluso nel bundle
- ✅ **`ITSAppUsesNonExemptEncryption = NO`** in Info.plist (salta il prompt export compliance)
- ✅ Versione **1.0** / build **1**
- ✅ Signing automatico + Development Team impostato
- 🔁 Build di **distribuzione** con `aps-environment = production` (con signing automatico Xcode lo imposta in archive — verificare nell'entitlement dell'archivio)

## 2. CloudKit (blocco silenzioso n.1)

- ✅ **Deploy dello schema CloudKit in Production** (2026-06-12): schema inizializzato con `SchemaCloudKitDebug` (7 record type `CD_*` verificati in console) e deployato in Production. Da ripetere a ogni modifica dei modelli, prima del rilascio dell'update.
- ⬜ Test su device con un Apple ID **diverso** dal tuo, dopo il deploy in Production (o build TestFlight), per confermare che la sync parta da zero.

## 3. Account & firma

- ⬜ Apple Developer Program attivo (membership pagata)
- ⬜ App ID `it.systema360.equinozio` registrato con capability **iCloud** + **Push Notifications** (di norma automatico col signing)
- ⬜ Certificato di distribuzione + provisioning App Store (automatico)

## 4. App Store Connect — scheda app

- ⬜ Creare l'app (nome **Equinozio**, lingua principale **Italiano**, bundle id, SKU)
- ⬜ Categoria (proposta: **Stile di vita** o **Salute e fitness**)
- ⬜ Prezzo: **Gratis**, disponibilità (almeno Italia; valutare resto mondo)
- ⬜ **Screenshot** obbligatori: iPhone 6.9" e 6.7" (almeno uno per taglia). Se l'app è universale anche iPad 13".
- ⬜ Descrizione, testo promozionale, **keyword**
- ⬜ **Support URL** → https://systema360.it (o pagina dedicata)
- ⬜ **Marketing URL** → la landing page di Equinozio
- ⬜ **Privacy Policy URL** → `…/privacy` (pagina creata sulla landing) ✅ pagina pronta
- ⬜ **App Privacy ("nutrition label")**: compilare il questionario → con tutta probabilità **"Data Not Collected"** (i dati restano nell'iCloud privato dell'utente; nulla arriva a Systema360). Coerente col `PrivacyInfo.xcprivacy`.
- ⬜ Classificazione per età (questionario)
- ⬜ Note per il revisore: l'app **non ha account**; funziona offline e con iCloud. Nessuna credenziale demo necessaria.

## 5. Build & invio

- ⬜ In Xcode: **Product → Archive** (configurazione Release, destinazione "Any iOS Device")
- ⬜ **Validate App** nell'Organizer (risolve eventuali errori entitlement/privacy prima dell'upload)
- ⬜ **Distribute App → App Store Connect** (upload)
- ⬜ (Consigliato) **TestFlight** interno per provare la build reale prima della review
- ⬜ Selezionare la build nella scheda, completare i metadati, **Submit for Review**

## 6. Dopo l'approvazione

- ⬜ Sostituire nella landing il placeholder `APP_STORE_URL = '#'` (in `resources/js/pages/welcome.tsx`) con il link reale dell'App Store, poi `npm run build`.
- ⬜ Aggiornare eventualmente il Marketing/Support URL se cambiano.

## Note

- La privacy policy sulla landing è una base ragionevole e GDPR-aware, ma **va riletta/adattata** (eventualmente con un legale) prima della pubblicazione; verificare anche l'indirizzo email `privacy@systema360.it`.
- Se in futuro si aggiungono SDK/analytics o si raccolgono dati, aggiornare `PrivacyInfo.xcprivacy` e la nutrition label.
