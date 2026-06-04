//
//  SplashScreenView.swift
//  Equinozio · Features · Splash
//
//  Splash animata · solo l'emblema centrato, niente scritte.
//

import SwiftUI

struct SplashScreenView: View {

    let onTerminato: () -> Void

    @State private var apparso = false
    @State private var scomparendo = false

    var body: some View {
        ZStack {
            Color.sfondo
                .ignoresSafeArea()

            QuattroCerchi(mostraEtichette: false, respira: false)
                .frame(width: 280, height: 280)
                .scaleEffect(apparso ? 1.0 : 0.5)
                .opacity(apparso ? 1.0 : 0.0)
        }
        .opacity(scomparendo ? 0 : 1)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                apparso = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                withAnimation(.easeIn(duration: 0.5)) {
                    scomparendo = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                onTerminato()
            }
        }
    }
}

#Preview {
    SplashScreenView(onTerminato: {})
}
