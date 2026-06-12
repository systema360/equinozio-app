//
//  FoglioAdattivo.swift
//  Equinozio · DesignSystem
//
//  Presentazione adattiva delle sheet: su iPad il foglio usa il formato
//  "page", più largo, per sfruttare lo schermo; su iPhone restano i
//  detents con l'indicatore di trascinamento.
//

import SwiftUI

public extension View {

    /// Da applicare al contenuto di una `.sheet`: page su iPad, detents su iPhone.
    @ViewBuilder
    func foglioAdattivo(detents: Set<PresentationDetent> = [.large]) -> some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            presentationSizing(.page)
        } else {
            presentationDetents(detents)
                .presentationDragIndicator(.visible)
        }
        #else
        presentationSizing(.page)
        #endif
    }
}
