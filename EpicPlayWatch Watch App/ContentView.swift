//
//  ContentView.swift
//  EpicPlayWatch Watch App
//
//  Created by Rodrigo Rochin on 12/01/26.
//

import SwiftUI

// MARK: - EpicPlay Colors
extension Color {
    static let epicBlack = Color.black
    static let epicOrange = Color(red: 1.0, green: 0.45, blue: 0.0)
    static let epicWhite = Color.white
}

struct ContentView: View {

    @StateObject private var vm = WatchViewModel()
    @State private var isGameMode = false
    @State private var showInvalidCourtMessage = false

    var body: some View {
        NavigationStack {
            if isGameMode {
                gameModeView
            } else {
                setupView
            }
        }
    }

    // MARK: - SETUP VIEW

    private var setupView: some View {
        List {

            // -------- CLUB --------
            VStack(alignment: .leading, spacing: 6) {
                Text("CLUB")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ZStack {
                    Capsule()
                        .fill(Color.epicOrange)
                        .frame(height: 48)

                    Picker("", selection: $vm.selectedClub) {
                        ForEach(vm.clubs) { club in
                            Text(club.name)
                                .tag(Optional(club))
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.navigationLink)
                    .opacity(0.01) // invisible pero clickeable

                    Text(vm.selectedClub?.name ?? "Seleccionar club")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .allowsHitTesting(false)
                }
            }
            .listRowBackground(Color.clear)

            // -------- CANCHA --------
            if let club = vm.selectedClub {
                VStack(alignment: .leading, spacing: 6) {
                    Text("CANCHA")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    ZStack {
                        Capsule()
                            .fill(Color.epicOrange)
                            .frame(height: 48)

                        Picker("", selection: $vm.selectedCourt) {
                            ForEach(club.courts, id: \.self) { court in
                                let number = court.replacingOccurrences(
                                    of: "\\D",
                                    with: "",
                                    options: .regularExpression
                                )
                                Text(number.isEmpty ? court : number)
                                    .tag(Optional(court))
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.navigationLink)
                        .opacity(0.01)

                        Text(vm.selectedCourt ?? "Seleccionar cancha")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .allowsHitTesting(false)
                    }
                }
                .listRowBackground(Color.clear)
            }

            // ⚠️ ERROR
            if showInvalidCourtMessage {
                Text("⚠️ Selecciona club y cancha")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                    .multilineTextAlignment(.center)
            }

            // ➜ CONTINUAR (centrado)
            HStack {
                Spacer()

                Button {
                    if vm.selectedClub != nil && vm.selectedCourt != nil {
                        showInvalidCourtMessage = false
                        isGameMode = true
                    } else {
                        showInvalidCourtMessage = true
                    }
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.epicOrange)
                }
                .buttonStyle(.plain)
                .opacity(vm.selectedClub != nil && vm.selectedCourt != nil ? 1 : 0.35)

                Spacer()
            }
            .listRowBackground(Color.clear)

        }
        .listStyle(.carousel)
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

    // MARK: - RECORD BUTTON

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
                ProgressView().tint(.white)
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

    private var courtNumber: String {
        vm.selectedCourt?
            .replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
        ?? ""
    }
}
