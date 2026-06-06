# Logo unificato "quattro cerchi a rombo" — Design

**Data:** 2026-06-06
**Stato:** approvato (in attesa di review utente sullo spec)
**Ambito:** 3 repo — app iOS (`/Users/giuseppe/XCode/Equinozio`), landing Equinozio (`/Users/giuseppe/Herd/equinozio`), sito Systema360 (`/Users/giuseppe/Herd/systema360`).

## Obiettivo

Unificare il marchio Equinozio su un unico logo — i **quattro cerchi disposti a rombo** (come il logo della card Systema360) — applicandolo coerentemente su tutte le superfici: emblemi in-UI, icona app iOS, favicon/OG/logo del web. Rimuovere il puntino centrale ovunque.

## Spec canonico del logo

Disposizione **a rombo** (non più a quadrato/Venn):
- **passione** in alto, **talento** a sinistra, **missione** a destra, **professione** in basso.
- I quattro cerchi si sovrappongono e convergono al centro.

Geometria (frazioni del lato del box quadrato; equivalenti su `viewBox 0 0 100 100`):
- raggio cerchio `r = 0.264 · lato` (diametro `0.527 · lato`)
- offset dei centri dal centro del box, lungo i 4 assi cardinali: `o = 0.236 · lato`
- centri: passione `(0.5, 0.264)`, talento `(0.264, 0.5)`, missione `(0.736, 0.5)`, professione `(0.5, 0.736)` (in frazioni)
- con questi numeri i cerchi toccano i 4 bordi del box ai punti cardinali (emblema "pieno"); per icona/OG si applica un margine scalando l'emblema (vedi sotto).

Colori (token già esistenti, invariati):
- passione `#d38e8c` · talento `#c2be7e` · missione `#88bc97` · professione `#82afc6`

Fusione:
- **`multiply`** su sfondo chiaro, **`screen`** su sfondo scuro (mantiene le intersezioni leggibili in entrambi i temi).

Niente **puntino centrale** (rimosso da app, card, ovunque).

Sfondo:
- **trasparente** per gli emblemi in-UI;
- **salvia soffuso** (gradiente come nell'immagine di riferimento) per icona app, OG image e favicon. Gradiente di riferimento: da `#e9efe3` (salvia pallido, alto/sx) a `#f2efe7` (paper caldo, basso/dx).

## Sorgente unica per gli asset statici

Tutti gli asset raster/vector statici (logo.svg, favicon, OG, AppIcon) derivano da **un unico SVG sorgente** del rombo, così restano identici pixel-per-pixel nella geometria.

`logo-sorgente.svg` (concetto, `viewBox 0 0 100 100`, multiply):
```svg
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <g style="isolation:isolate">
    <circle cx="50" cy="26.4" r="26.4" fill="#d38e8c" style="mix-blend-mode:multiply"/>
    <circle cx="26.4" cy="50" r="26.4" fill="#c2be7e" style="mix-blend-mode:multiply"/>
    <circle cx="73.6" cy="50" r="26.4" fill="#88bc97" style="mix-blend-mode:multiply"/>
    <circle cx="50" cy="73.6" r="26.4" fill="#82afc6" style="mix-blend-mode:multiply"/>
  </g>
</svg>
```
Rendering SVG→PNG: usare `rsvg-convert` (preferito) o, in assenza, Chrome headless / ImageMagick con librsvg. Il tool effettivo lo fissa il piano dopo verifica di disponibilità.

## Applicazione per superficie

### A. App iOS — `Equinozio/DesignSystem/Components/QuattroCerchi.swift`
- Cambiare l'array `posizioni` da quadrato (centri a `(cx±d, cy±d)`) a **rombo** (centri ai 4 assi cardinali) con le proporzioni canoniche: `distanzaCentri = lato · 0.236`, `raggio = lato · 0.264`.
  - passione `(cx, cy − d)`, talento `(cx − d, cy)`, missione `(cx + d, cy)`, professione `(cx, cy + d)`.
- **Rimuovere** il `Circle()` centrale salvia (il "punto equinozio").
- Mantenere `respira` (breathing) e la logica `multiply`/`screen`.
- `etichetteEsterne`: riposizionare le 4 etichette ai vertici del rombo (alto/sinistra/destra/basso) invece dei 4 angoli.
- Propagazione automatica a `MappaView`, `SplashScreenView`, `BloccoView`, `EsplorazioneView`.

### B. Icona app iOS — `Equinozio/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- Rigenerare 1024×1024 **opaca** (no alpha): rombo (scalato a ~64% del lato, centrato) su sfondo salvia (gradiente di riferimento). Generata dall'SVG sorgente + sfondo.
- `Contents.json` invariato (single-size 1024).

### C. Landing Equinozio
- `resources/js/components/quattro-cerchi.tsx` e `resources/js/components/cerchi-mark.tsx`: geometria a rombo con le proporzioni canoniche, niente puntino. Mantenere `mix-blend-mode` (multiply/screen) e i token colore `--passione|--talento|--missione|--professione`.
- Asset statici: rigenerare `public/logo.svg` (= SVG sorgente), `public/favicon.ico`, e l'immagine **OG** (rombo + eventuale wordmark su sfondo salvia). Verificare i riferimenti OG/favicon nelle pagine (`<Head>`/layout).
- Usi a cascata: `site-nav.tsx`, `site-footer.tsx`, `ios-device.tsx`, `app-screens.tsx`, `widget-mock.tsx`, `welcome.tsx`, `manifesto.tsx` ereditano dal componente aggiornato.

### D. Systema360
- `resources/css/site.css`: rimuovere la regola/uso di `.eqz-emblem__core` (il puntino) — l'emblema della card è già a rombo con le proporzioni corrette.
- `resources/views/site/partials/equinozio-home-card.blade.php`: rimuovere lo `<span class="eqz-emblem__core">`.
- (Opzionale, fuori scope salvo richiesta) un eventuale `logo.svg`/favicon Equinozio su Systema360.

## Coerenza / DRY

Ogni piattaforma mantiene la propria sorgente (Swift `QuattroCerchi`, React `cerchi-mark`/`quattro-cerchi`, CSS `eqz-emblem`), ma **tutte** allineate allo stesso spec numerico (raggio 0.264 / offset 0.236, stessi colori, stesso ordine, stesso blend, niente puntino). Gli asset statici da un unico SVG sorgente.

## Decomposizione (3 piani d'implementazione)

1. **App iOS** — `QuattroCerchi` (geometria + niente puntino + etichette) + AppIcon rigenerata. Verifica: build + test verdi; controllo visivo su device.
2. **Landing Equinozio** — `cerchi-mark`/`quattro-cerchi` + logo.svg/favicon/OG. Verifica: Pest + build + visivo (nav/footer/favicon/OG, chiaro/scuro).
3. **Systema360** — rimozione puntino dalla card. Verifica: Pest (card test invariato) + build + visivo.

Ogni piano è indipendente e produce software funzionante da solo.

## Edge case / note

- **App icon opaca**: nessun canale alpha (requisito App Store) → sfondo salvia pieno.
- **Blend negli SVG statici**: `mix-blend-mode` dentro `<g style="isolation:isolate">` è supportato dai renderer moderni e da rsvg/Chrome; per il favicon a dimensioni minime (16/32px) le intersezioni restano leggibili perché i 4 colori sono ben distinti.
- **Etichette app**: con il rombo, le etichette ai 4 punti cardinali; verificare che non escano dal frame nei contesti con `mostraEtichette: true` (es. Esplorazione/Mappa).
- **Dark mode web**: `cerchi-mark` deve usare `screen` su tema scuro (oggi usa `multiply` via `.eq-cerchi-blend`); verificare la classe e aggiungere la variante dark se assente.

## Fuori scope

- Ridisegno di altri elementi di brand (tipografia, palette) — solo il logo.
- Nuovi asset oltre quelli elencati (es. logo Equinozio dedicato dentro Systema360 oltre alla card).

## Sequenza suggerita

SVG sorgente del rombo → App (componente + icona) → Landing (componenti + asset) → Systema360 (puntino). Ogni repo verificato (build/test) prima del commit.
