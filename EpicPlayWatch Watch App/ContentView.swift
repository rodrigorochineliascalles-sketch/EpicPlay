//
//  ContentView.swift
//  EpicPlayWatch Watch App
//
//  Created by Rodrigo Rochin on 12/01/26.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var vm = WatchViewModel()
    @State private var isGameMode = false

    // Feedback visual
    @State private var showInvalidCourtMessage = false

    var body: some View {
        Group {
            if isGameMode {
                gameModeView
            } else {
                setupView
            }
        }
        // Transición automática
        .onChange(of: vm.selectedClub) {
            handleSelectionChange()
        }
        .onChange(of: vm.selectedCourt) {
            handleSelectionChange()
        }
    }

    // MARK: - SETUP VIEW

    private var setupView: some View {
        ScrollView {
            VStack(spacing: 10) {

                // CLUB
                VStack(alignment: .leading, spacing: 4) {
                    Text("CLUB")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Picker("", selection: $vm.selectedClub) {
                        ForEach(vm.clubs) { club in
                            Text(club.name)
                                .font(.headline)
                                .tag(Optional(club))
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                // CANCHA
                if let club = vm.selectedClub {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CANCHA")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Picker("", selection: $vm.selectedCourt) {
                            ForEach(club.courts, id: \.self) { court in
                                let number = court.replacingOccurrences(
                                    of: "\\D",
                                    with: "",
                                    options: .regularExpression
                                )

                                Text(number.isEmpty ? court : number)
                                    .font(.title3)
                                    .tag(Optional(court))
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                }

                // ⚠️ MENSAJE DE ERROR VISUAL
                if showInvalidCourtMessage {
                    Text("⚠️ Selecciona una cancha válida para este club")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
    }

    // MARK: - GAME MODE VIEW

    private var gameModeView: some View {
        VStack(spacing: 10) {

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.selectedClub?.name ?? "")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("Cancha \(courtNumber)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    isGameMode = false
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.caption)
                }
            }

            Button {
                vm.record()
            } label: {
                recordButton
            }
            .disabled(vm.recordState != .idle)
        }
        .padding()
    }

    // MARK: - Botón principal

    private var recordButton: some View {
        ZStack {
            Circle()
                .fill(Color.red)
                .opacity(vm.recordState == .idle ? 1 : 0.6)

            switch vm.recordState {
            case .idle:
                Text("GRABAR")
                    .font(.headline)
                    .foregroundStyle(.white)

            case .sending:
                ProgressView()
                    .tint(.white)

            case .success:
                Image(systemName: "checkmark")
                    .font(.title2)
                    .foregroundStyle(.white)

            case .error:
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 120, height: 120)
    }

    // MARK: - Helpers

    private func handleSelectionChange() {
        // Si hay club pero no cancha → feedback visual
        if vm.selectedClub != nil && vm.selectedCourt == nil {
            showInvalidCourtMessage = true
            isGameMode = false
        } else {
            showInvalidCourtMessage = false
        }

        // Entrar a modo partido solo si todo es válido
        if vm.selectedClub != nil && vm.selectedCourt != nil {
            isGameMode = true
        }
    }

    private var courtNumber: String {
        vm.selectedCourt?
            .replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        ?? ""
    }
}
