//
//  SettingsView.swift
//  SwipeClean
//
//  Created by Jan Haider on 03.02.25.
//

import SwiftUICore
import SwiftUI

struct SettingsView: View {
    @State private var showResetConfirmation = false
    @State private var showSlideOver = false
    @AppStorage("mediaMuted") var mediaMuted: Bool = false  // Toggle für "Medien stummschalten"
    @AppStorage("iCloudSyncEnabled") var iCloudSyncEnabled: Bool = false

    // Verwende CloudKitSyncManager als Sync-Manager
    @StateObject private var syncManager: CloudKitSyncManager

    init() {
        _syncManager = StateObject(wrappedValue: CloudKitSyncManager.shared)
        // Setze den Hintergrund der UITableView und ihrer Zellen für diese View
        UITableView.appearance().backgroundColor = UIColor.systemGroupedBackground
        UITableViewCell.appearance().backgroundColor = UIColor.systemGroupedBackground
    }
    
    private var syncStatusText: String {
        return syncManager.syncStatus
    }
    
    private var syncIcon: String {
        if syncStatusText.contains("Synchronisiere") {
            return "icloud.and.arrow.up"
        } else if syncStatusText.contains("Synchronisiert") {
            return "icloud"
        } else {
            return "exclamationmark.icloud"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 25) {
                    // Oberer Header mit Icon und Titel
                    VStack {
                        Image("SwipeClean-Icon_Light")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: UIScreen.main.bounds.width * 0.3)
                            .clipShape(RoundedRectangle(cornerRadius: UIScreen.main.bounds.width / 15, style: .continuous))
                            .padding(.top, 16)
                        Text("SwipeClean")
                            .font(.largeTitle)
                            .padding(.top, 8)
                    }
                    
                    Form {
                        Section("Einstellungen") {
                            Toggle("Medien stummschalten", isOn: $mediaMuted)
                                .accessibilityIdentifier("toggleMediaMuted")
                            
                            Button(action: {
                                showResetConfirmation = true
                            }) {
                                Text("Datenbank zurücksetzen")
                                    .foregroundColor(.red)
                            }
                            .accessibilityLabel("Datenbank zurücksetzen")
                            .alert(isPresented: $showResetConfirmation) {
                                Alert(
                                    title: Text("Datenbank zurücksetzen"),
                                    message: Text("Bist du dir sicher, dass du die lokale und Cloud-Datenbank zurücksetzen möchtest?"),
                                    primaryButton: .destructive(Text("Zurücksetzen"), action: {
                                        DatabaseManager.shared.resetDatabase()
                                        syncManager.resetCloudDatabase { _ in }
                                        withAnimation {
                                            showSlideOver = true
                                        }
                                        // SlideOver nach kurzer Zeit ausblenden
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                            withAnimation { showSlideOver = false }
                                        }
                                    }),
                                    secondaryButton: .cancel()
                                )
                            }
                        }
                        
                        // Abschnitt für CloudKit Synchronisierung mit manuellem Sync-Button
                        Section("CloudKit Synchronisierung") {
                            Toggle("CloudKit Synchronisierung aktivieren", isOn: $iCloudSyncEnabled)
                                .accessibilityIdentifier("toggleICloudSyncEnabled")
                            
                            HStack {
                                Image(systemName: syncIcon)
                                    .foregroundColor(.blue)
                                Text(syncStatusText)
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                            
                            // Button zum manuellen Auslösen der Synchronisierung
                            Button(action: {
                                syncManager.syncData()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Manuell synchronisieren")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Section("Hilfe") {
                            Button(action: {
                                openEmail()
                            }) {
                                Text("Supportanfrage")
                            }
                            Button(action: {
                                if let url = URL(string: "https://swipeclean.jan-haider.dev/PrivacyPolice.html") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("Privacy Policy")
                            }
                        }
                        
                        Section("Developer") {
                            Text("Entwickelt von: Jan Haider")
                            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                                Text("Version \(version) (Build \(build))").font(.subheadline)
                            } else {
                                Text("Version nicht verfügbar").font(.subheadline)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color(UIColor.systemGroupedBackground))
                }
                
                if showSlideOver {
                    SlideOverView(message: "Datenbank wurde zurückgesetzt")
                        .transition(.move(edge: .trailing))
                        .zIndex(1)
                        .accessibilityIdentifier("slideOverMessage")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SlideOverView: View {
    var message: String

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(message)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .shadow(radius: 5)
                Spacer()
            }
            .padding(.bottom, 50)
        }
    }
}

func openEmail() {
    let email = "support.SwipeClean@jan-haider.dev"
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unbekannt"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unbekannt"
    let subject = "Support SwipeClean - App Version \(appVersion) (Build \(buildNumber))"
    let body = "Bitte tragen Sie hier ihre Probleme oder fragen ein:\n\n\n"
    if let emailURL = URL(string: "mailto:\(email)?subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) {
        if UIApplication.shared.canOpenURL(emailURL) {
            UIApplication.shared.open(emailURL)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
