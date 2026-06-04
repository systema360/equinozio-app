# Widget Home Screen — setup (passi manuali in Xcode)

Il widget richiede un nuovo target e un App Group, da creare nella GUI di Xcode.

## 1. App Group
1. Seleziona il target **Equinozio** → Signing & Capabilities → **+ Capability** → **App Groups**.
2. Aggiungi il gruppo: `group.it.systema360.equinozio`.

## 2. Nuovo target Widget Extension
1. File → New → Target… → **Widget Extension** → nome `EquinozioWidget`.
2. Al target widget aggiungi la stessa capability **App Groups** con `group.it.systema360.equinozio`.

## 3. Codice del widget
Sostituisci il contenuto del file generato `EquinozioWidget.swift` con:

```swift
import WidgetKit
import SwiftUI

struct Voce: TimelineEntry { let date: Date; let equilibrio: Int }

struct Fornitore: TimelineProvider {
    func placeholder(in context: Context) -> Voce { Voce(date: .now, equilibrio: 50) }
    func getSnapshot(in context: Context, completion: @escaping (Voce) -> Void) {
        completion(Voce(date: .now, equilibrio: leggiEquilibrio()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Voce>) -> Void) {
        let voce = Voce(date: .now, equilibrio: leggiEquilibrio())
        completion(Timeline(entries: [voce], policy: .after(.now.addingTimeInterval(3600))))
    }
    private func leggiEquilibrio() -> Int {
        UserDefaults(suiteName: "group.it.systema360.equinozio")?.integer(forKey: "equilibrioCorrente") ?? 50
    }
}

struct EquinozioWidgetView: View {
    var voce: Voce
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("EQUILIBRIO").font(.system(size: 10, weight: .medium)).tracking(1.6).foregroundStyle(.secondary)
            Text("\(voce.equilibrio)").font(.system(size: 44, weight: .thin))
            Text("Equinozio").font(.system(size: 11, weight: .light)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .containerBackground(.background, for: .widget)
    }
}

@main
struct EquinozioWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "EquinozioWidget", provider: Fornitore()) { voce in
            EquinozioWidgetView(voce: voce)
        }
        .configurationDisplayName("Equilibrio")
        .description("Il tuo equilibrio settimanale.")
        .supportedFamilies([.systemSmall])
    }
}
```

## 4. Verifica
L'app aggiorna `equilibrioCorrente` nel gruppo al salvataggio di una riflessione (`WidgetSnapshot.aggiorna`). Dopo aver salvato una riflessione, il widget mostra il valore.
