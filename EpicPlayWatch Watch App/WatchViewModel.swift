//
//  WatchViewModel.swift
//  EpicPlay
//
//  Created by user289202 on 1/13/26.
//
import Foundation
import SwiftUI

struct WatchConfigResponse: Decodable {
    let clubs: [Club]
}

@MainActor
class WatchViewModel: ObservableObject {

    enum RecordState {
        case idle
        case sending
        case success
        case error
    }

    @Published var clubs: [Club] = []

    // 👇 VALIDACIÓN AUTOMÁTICA AL CAMBIAR CLUB
    @Published var selectedClub: Club? {
        didSet {
            validateSelectedCourt()
        }
    }

    @Published var selectedCourt: String?
    @Published var recordState: RecordState = .idle

    init() {
        loadClubs()
    }

    // MARK: - Load Clubs

    func loadClubs() {
        guard let url = URL(string: "https://studio--epic-play.us-central1.hosted.app/api/watch-config") else {
            print("❌ URL inválida")
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoded = try JSONDecoder().decode(WatchConfigResponse.self, from: data)

                self.clubs = decoded.clubs
                // ⚠️ OJO: no auto-seleccionamos cancha aquí
                self.selectedClub = nil
                self.selectedCourt = nil

            } catch {
                print("❌ Error cargando clubs:", error)
            }
        }
    }

    // MARK: - Validation

    private func validateSelectedCourt() {
        guard let club = selectedClub else {
            selectedCourt = nil
            return
        }

        // Si la cancha actual no pertenece al nuevo club → se invalida
        if let court = selectedCourt, !club.courts.contains(court) {
            selectedCourt = nil
        }
    }

    // MARK: - Record Action

    func record() {
        guard let club = selectedClub,
              let courtName = selectedCourt else {
            recordState = .error
            resetLater()
            return
        }

        recordState = .sending

        // "Cancha 2" -> "2"
        let courtId = courtName.replacingOccurrences(
            of: "\\D",
            with: "",
            options: .regularExpression
        )

        guard let url = URL(string: "https://studio--epic-play.us-central1.hosted.app/api/trigger-highlight") else {
            recordState = .error
            resetLater()
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "club": club.id,
            "court": courtId
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        Task {
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    recordState = .success
                } else {
                    recordState = .error
                }
            } catch {
                recordState = .error
            }

            resetLater()
        }
    }

    private func resetLater() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.recordState = .idle
        }
    }
}
