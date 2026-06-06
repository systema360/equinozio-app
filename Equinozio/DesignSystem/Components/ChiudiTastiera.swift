//
//  ChiudiTastiera.swift
//  Equinozio · DesignSystem
//
//  Strumenti per chiudere la tastiera (toolbar "Fine" + helper resignFirstResponder).
//

import SwiftUI

extension View {
    /// Aggiunge alla tastiera una toolbar con il bottone "Fine" che la chiude.
    func toolbarTastieraFine() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fine") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                    )
                }
                .tint(.salvia)
            }
        }
    }
}
