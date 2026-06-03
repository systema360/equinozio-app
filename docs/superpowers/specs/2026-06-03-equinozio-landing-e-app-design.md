# Equinozio — Landing page + migliorie app — Design

**Data:** 2026-06-03
**Autore:** Giuseppe (Systema360) + Claude
**Stato:** approvato (in attesa di revisione finale della spec)

---

## 1. Contesto e obiettivo

Equinozio è un'app italiana di equilibrio personale basata sulla filosofia "ikigai / quattro
cerchi" (Passione, Talento, Missione, Professione). Stack:

- **App iOS** — `/Users/giuseppe/XCode/Equinozio` · SwiftUI + SwiftData + CloudKit, offline-first,
  **senza account**. Quattro schede (Mappa, Diario, Riflessione, Decisione) + onboarding
  (Esplorazione) + Manifesto.
- **Sito web** — `/Users/giuseppe/Herd/equinozio` · Laravel + Inertia + React + Tailwind.
  Oggi è un **clone web completo** dell'app, con autenticazione.

L'app è realizzata da **Systema360** (studio di consulenza/progettazione digitale, Potenza) ed è
il suo biglietto da visita.

**Obiettivo del progetto:** (1) migliorare l'app iOS; (2) trasformare il sito in una **landing
page** coerente con l'app; (3) definire il modello di vendita.

---

## 2. Decisioni strategiche

### 2.1 Modello di vendita — gratis, vetrina, lead-gen indiretto

L'app resta **gratuita, senza account, senza pubblicità, senza vendita di dati** (conferma il
Manifesto "sempre gratuita"). Non si introduce freemium/pagamento/abbonamento: contraddirebbero
il posizionamento e richiederebbero infrastruttura account/pagamenti oggi assente.

La monetizzazione è **indiretta**: Equinozio è la *prova vivente* della qualità di Systema360 e
genera contatti di consulenza.

### 2.2 Lead-gen a doppio pubblico

La landing serve due pubblici con due percorsi distinti:

- **Primario — B2C (la prova):** l'individuo scopre e scarica l'app. CTA principale: **Scarica su
  App Store**. Volume/recensioni dell'app *sono* il portfolio.
- **Secondario — B2B (la conversione di valore):** sezione dedicata *"Progettato e costruito da
  Systema360 — sistemi digitali curati così, anche per la tua organizzazione"* con CTA **Parla con
  lo studio**. È il contatto che genera valore reale.

I due percorsi si alimentano: il B2C rende credibile il pitch B2B.

### 2.3 Destino del clone web

Il clone web funzionante (login + Mappa/Diario/Riflessione/Decisione) viene **rimosso/archiviato**.
Il sito diventa **pura landing di marketing**; l'unico prodotto è l'app iOS.

---

## 3. Design — Landing page (workstream 1, da fare per primo)

### 3.1 Direzione visiva

**"Editoriale & calmo"**: molto respiro, testo sottile gigante, il diagramma a quattro cerchi come
protagonista. Estensione senza soluzione di continuità dell'app, non un sito di marketing separato.

**Vincoli di design (fermi):**
- **Tipografia:** Helvetica / Helvetica Neue, peso **Light** (corpo), Thin per i titoli grandi.
  **Mai Bold.** Titoli con tracking negativo; etichette piccole maiuscole con tracking ampio.
- **Iconografia:** identica all'app — diagramma **QuattroCerchi** come motivo distintivo + le stesse
  icone SF Symbols delle schede (`circle.grid.2x2.fill`, `book.closed`, `moon.stars`, `scale.3d`).
- **Palette (valori reali dell'app):** salvia `#5B8E84`, salviaProfonda `#3F6F66`, inchiostro
  `#1F2A37`, inchiostroTenue `#475569`, sfondo `#F1F6F4`, superficie `#FFFFFF`, attenuato `#94A3B0`,
  lineaSottile `#DCE6E2`. Cerchi: Passione `#D49C9C`, Talento `#C2C088`, Missione `#8FBE9B`,
  Professione `#8BB1C9`.

### 3.2 Struttura (7 sezioni, dall'alto in basso)

1. **Hero** — "Equinozio · Il tuo equilibrio" + diagramma quattro cerchi + CTA *Scarica su App
   Store* + microcopy "Gratis · senza account · senza pubblicità".
2. **Il metodo** — quattro cerchi, quattro domande (con i colori dei cerchi).
3. **Cosa fa l'app** — i quattro gesti (Mappa, Diario, Riflessione, Decisione) con **screenshot
   reali** dell'app (uno per gesto) e le icone SF Symbols.
4. **Privacy** — "I tuoi dati restano tuoi": niente account/pubblicità/vendita dati, tutto sul
   dispositivo e iCloud privato.
5. **Manifesto (teaser)** — frase-chiave ("un quiz una-tantum non cambia una vita; un compagno
   discreto può farlo") + link al manifesto completo.
6. **Systema360 (B2B)** — sezione scura (inchiostro): *"Sistemi digitali curati così, anche per la
   tua organizzazione"* + CTA **Parla con lo studio**.
7. **Footer** — "Fatto con cura da Systema360 · 2026" + link essenziali.

Responsive: layout a colonna singola su mobile; griglia a due colonne (metodo/funzioni) da tablet
in su.

### 3.3 Approccio tecnico

- Ricostruire la pagina `welcome` Inertia/React come landing, usando i token di design dell'app
  (palette + Helvetica Light) via Tailwind.
- **Rimuovere** rotte/controller/pagine dell'app autenticata: `mappa`, `diario`, `riflessione`,
  `decisione`, `esplorazione`, `dashboard`, e lo scaffolding di autenticazione (`auth.php`,
  `settings.php`) non più necessario per una landing pubblica. Archiviare il codice rimosso in un
  branch/git tag prima della rimozione.
- **Pagine pubbliche secondarie (opzionali, da confermare in fase di plan):** `manifesto` e `aiuto`
  possono restare come pagine statiche pubbliche linkate dalla landing.
- Asset: gli screenshot reali dell'app vanno prodotti/esportati e inseriti nella sezione 3.
- Link App Store: placeholder fino alla pubblicazione; CTA B2B → `systema360.it` / form contatti.

---

## 4. Design — Migliorie app iOS (workstream 2, dopo la landing, a fasi)

Base: audit completo del codice (loop centrale solido; opportunità = completare l'abbozzato +
rifinire). Quattro temi, da implementare in fasi successive.

### Tema 1 — Completare il già abbozzato (fase 1, priorità massima)
- **Campo `pensiero` nella Riflessione**: il modello lo prevede (`Modelli.swift:98`) e la UI mostra
  la domanda, ma manca il campo di input. Aggiungere la textarea e persistere; mostrare il pensiero
  nello Storico (già predisposto in lettura).
- **Insight reali**: il modello `Insight` (`Modelli.swift:164`) è inutilizzato. Implementare la
  logica di generazione (bilanciamento basso, cerchio dominante, trend di crescita, decisioni in
  scadenza) e mostrarli nella **Mappa**.
- **Suggerimento tag in modifica** del Diario (oggi solo nel composer).
- **Modifica riflessioni passate** nello Storico (oggi sola lettura).
- **Radar live** in Decisione mentre si trascinano gli slider.

### Tema 2 — Nuove funzionalità (fase 2)
- **Widget Home Screen** (equilibrio + promemoria) — alto effetto-vetrina.
- **Ricerca testuale** nel Diario.
- **Promemoria personalizzabile** (orario + testo; oggi fissi domenica 19:00).
- **Stato sync iCloud in tempo reale** con indicatore (oggi solo on-demand).
- **Export/condivisione** del diario · **Undo** dopo cancellazione nel Diario.

### Tema 3 — Rifinitura UI/UX & accessibilità (fase 3)
- **Accessibilità**: label sui `TextEditor`, `accessibilityValue` annunciato sugli slider della
  Riflessione, label di stato sui filtri.
- Empty state coerenti; banner intro ri-mostrabili (icona "?"); formula equilibrio spiegata
  (info/tooltip); stringhe centralizzate; rimuovere l'emoji ❤ dal Manifesto (rottura di tono).

### Tema 4 — Gancio Systema360 in-app (fase 4)
- Sezione **"Chi l'ha fatta"** in Impostazioni con invito curato allo studio (discreto, coerente
  con "compagno discreto").
- **"Condividi Equinozio"** per il passaparola B2C.

---

## 5. Sequenza di implementazione

1. **Landing page** (workstream 1) — self-contained, risultato visibile, abilita vetrina e lead-gen.
2. **App — Tema 1**, poi **Tema 2**, **Tema 3**, **Tema 4** (un piano d'implementazione per fase).

Ogni workstream/fase avrà il proprio piano d'implementazione (skill writing-plans) al momento
opportuno. Si parte dal piano della **landing page**.

---

## 6. Fuori scope

- Monetizzazione diretta dell'app (freemium/pagamento/abbonamento).
- Account utente / sync cross-platform via web.
- Localizzazione multilingua (l'app resta italiana per scelta).
- App Android o web-app come prodotto.

---

## 7. Criteri di successo

- **Landing:** pagina unica, coerente con l'identità dell'app (Helvetica Light + quattro cerchi +
  palette), responsive, con CTA B2C (App Store) e B2B (contatto studio) chiari; clone web rimosso.
- **App:** campo pensiero catturato e mostrato; insight visibili nella Mappa; gap di accessibilità
  chiave risolti; gancio Systema360 presente con gusto; nessuna regressione del loop centrale.
