//
//  BloccoView.swift
//  Equinozio · Features · Splash
//
//  Schermata di sblocco · appare quando "Proteggi con Face ID" è attivo
//  e l'app si avvia o torna dal background.
//

import SwiftUI

struct BloccoView: View {

    let tipoBiometria: TipoBiometria
    let onSbloccato: () -> Void

    @State private var sbloccando = false
    @State private var ultimoErrore: String?

    var body: some View {
        ZStack {
            Color.sfondo
                .ignoresSafeArea()

            VStack(spacing: S.x5) {
                Spacer()

                QuattroCerchi(mostraEtichette: false, respira: false)
                    .frame(width: 200, height: 200)

                Spacer()

                VStack(spacing: S.x3) {
                    if let err = ultimoErrore {
                        Text(err)
                            .font(.equinozio(.corpoMedio))
                            .foregroundStyle(Color.passione)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, S.x5)
                    }

                    Button(action: tentaSblocco) {
                        HStack(spacing: S.x3) {
                            Image(systemName: tipoBiometria.simbolo)
                                .font(.system(size: 24, weight: .light))
                            Text("Sblocca con \(tipoBiometria.nome)")
                                .font(.system(size: 14, weight: .medium))
                                .tracking(0.5)
                                .textCase(.uppercase)
                        }
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, S.x6)
                        .padding(.vertical, S.x4)
                        .background(Color.salvia)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(sbloccando)

                    Text("EQUINOZIO È PROTETTA")
                        .font(.equinozio(.etichetta))
                        .tracking(2.6)
                        .foregroundStyle(Color.attenuato)
                        .padding(.top, S.x3)
                }
                .padding(.bottom, S.x8)
            }
        }
        .task {
            // Tentativo automatico all'apertura
            await sblocca()
        }
    }

    private func tentaSblocco() {
        Task { await sblocca() }
    }

    private func sblocca() async {
        sbloccando = true
        ultimoErrore = nil
        let ok = await BlocoAppService.shared.sblocca(motivo: "Sblocca Equinozio per accedere al tuo diario")
        sbloccando = false
        if ok {
            onSbloccato()
        } else {
            ultimoErrore = "Non sono riuscito a sbloccarti. Riprova."
        }
    }
}

#Preview {
    BloccoView(tipoBiometria: .faceID, onSbloccato: {})
}
