# Compliance check — Equinozio (app iOS + sito equinozio.app)

> Verifica del 12 giugno 2026 · Distribuzione: solo Italia · Account: Organization Systema360 S.r.l. · Trader status DSA: verificato.
> Questo documento è un supporto operativo, non un parere legale: per la pubblicazione è consigliata una rilettura da parte di un legale.

## Sintesi

**Procedi con condizioni.** Il quadro è molto solido: l'app è genuinamente "Data Not Collected" (nessun SDK di terze parti, AI on-device con fallback gestito, dati su dispositivo + iCloud privato), il sito non usa font esterni, analytics o cookie di profilazione. I gap individuati erano puntuali e sono stati **corretti oggi** (vedi sotto). Restano solo azioni operative pre-submit in App Store Connect e in fase di archive.

## Normative e policy applicabili

| Norma / Policy | Rilevanza | Stato |
|---|---|---|
| **GDPR** + Codice Privacy (D.Lgs. 196/2003) | App: nessun dato raccolto dal titolare. Sito: log tecnici + email di contatto | ✅ Informativa ora completa (titolare identificato, base giuridica, diritti, reclamo al Garante) |
| **ePrivacy / Linee guida cookie Garante (2021)** | Il sito usa solo cookie tecnici (sessione/CSRF di Laravel) | ✅ Nessun banner necessario; cookie tecnici ora dichiarati in informativa |
| **Art. 35 DPR 633/72 + art. 7 D.Lgs. 70/2003** | Obbligo di P.IVA e dati identificativi sul sito | ✅ Corretto oggi: footer con ragione sociale, sede, P.IVA, REA, email |
| **DSA (Reg. UE 2022/2065)** — trader status | Obbligatorio per pubblicare/aggiornare app nell'UE | ✅ Già verificato in App Store Connect |
| **App Review Guidelines 5.1.1 + Privacy Manifest** | `PrivacyInfo.xcprivacy` coerente: tracking false, nessun dato raccolto, UserDefaults CA92.1 | ✅ Conforme (app e widget) |
| **Nuovo sistema di classificazione età Apple** (obbligatorio dal 31/01/2026) | Nuove fasce 4+/9+/13+/16+/18+, domande su temi *medical/wellness* e funzioni AI | ⬜ Da compilare con attenzione (vedi Rischi) |
| **Codice del Consumo** | App gratuita, senza acquisti né abbonamenti | ✅ Termini con foro del consumatore e limitazioni corrette |
| **AI Act (Reg. UE 2024/1689)** | Spunto/riassunto = Apple Intelligence on-device, rischio minimo | ✅ Trasparenza già fornita in app e informativa; nessun obbligo aggiuntivo |
| **EAA — Dir. 2019/882 (accessibilità)** | App gratuita fuori dai servizi elencati + esenzione microimprese per i servizi | ✅ Non applicabile; VoiceOver/Dynamic Type restano buona pratica |
| **Export compliance USA** | Solo crittografia di sistema Apple | ✅ `ITSAppUsesNonExemptEncryption = NO` |

## Correzioni applicate oggi (repo `Herd/equinozio`)

1. **`site-footer.tsx`** — aggiunta riga con dati societari obbligatori: *Systema360 S.r.l. · 85100 Potenza (PZ) · P.IVA/C.F. 02227730765 · REA PZ – 222676 · privacy@systema360.it*.
2. **`SiteContentSeeder.php` → privacy** — titolare identificato come *Systema360 S.r.l.* con sede e P.IVA (art. 13 GDPR); aggiunta base giuridica e conservazione dei log; dichiarati i cookie tecnici; aggiunto diritto di **opposizione** e diritto di **reclamo al Garante** (garanteprivacy.it).
3. **`SiteContentSeeder.php` → termini** — sezione "Chi siamo" con sede completa e P.IVA.
4. **Test estesi** — `LandingTest` (titolare + Garante in privacy) e `TerminiTest` (P.IVA nei termini).

### Da fare subito dopo (sul tuo Mac, non eseguibile da qui)

```bash
cd ~/Herd/equinozio
vendor/bin/pint --dirty --format agent
php artisan test --compact --filter="privacy|termini|landing"
php artisan db:seed --class=SiteContentSeeder   # aggiorna i contenuti nel DB
npm run build
```

⚠️ **Attenzione**: il seeder **sovrascrive** i contenuti del CMS (incluse eventuali modifiche fatte da Filament) e **resetta** `app_state` a `coming_soon` e `app_store_url` a null. Se hai già modificato contenuti dall'admin, riporta le tre sezioni a mano da Filament invece di ri-seedare.

## Rischi residui

| Rischio | Gravità | Mitigazione |
|---|---|---|
| Nuovo questionario età: diario + riassunti AI possono ricadere in "medical or wellness topics" e alzare il rating | Media | Rispondere come strumento di riflessione personale (non salute/medico); il disclaimer "Nessuna consulenza" nei Termini supporta la risposta. Atteso 4+ |
| CloudKit schema non deployato in Production = sync rotta per gli utenti App Store | Alta (silenzioso) | Deploy schema da CloudKit Dashboard + test con Apple ID diverso (già in checklist) |
| Aggiunta futura di analytics (sito o app) senza aggiornare policy/banner/nutrition label | Media | Prima di aggiungere qualunque SDK: aggiornare `PrivacyInfo.xcprivacy`, nutrition label, informativa e valutare banner consenso |
| Informativa non ancora rivista da un legale | Bassa | Rilettura professionale consigliata, non bloccante |

## Azioni raccomandate (in ordine)

1. Esegui pint, test e ri-seed (comandi sopra), poi commit e **deploy di equinozio.app prima del submit** — Apple verifica che la Privacy Policy URL risponda.
2. In App Store Connect: nutrition label **"Data Not Collected"**, **nuovo questionario età** (incluse domande AI/wellness), Privacy Policy URL `https://equinozio.app/privacy`, Support URL, disponibilità **solo Italia**.
3. CloudKit Dashboard: **deploy schema in Production** + test sync con Apple ID diverso.
4. In fase di archive: verifica `aps-environment = production` nell'entitlement dell'archivio e icona 1024 senza canale alpha.
5. Dopo l'approvazione: imposta `app_state = online` e l'URL App Store reale dal CMS (non dal seeder).

## Punti già a posto (nessuna azione)

Privacy manifest app + widget coerenti · nessun tracciamento o SDK terzi · AI on-device con guard di disponibilità (`SystemLanguageModel.availability` in MotoreSpunti, RiassuntoDiario, TagSuggestionService) · Face ID con usage description · termini con foro consumatore · attribuzione marchi Apple nel footer · security headers + HSTS · robots.txt che esclude /admin · trader status DSA verificato · export compliance dichiarata.
