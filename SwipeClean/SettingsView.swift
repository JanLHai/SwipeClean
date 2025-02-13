//
//  SettingsView.swift
//  SwipeClean
//
//  Created by Jan Haider on 03.02.25.
//

import SwiftUICore
import SwiftUI
//import MyFeedbackLibrary

struct SettingsView: View {
    @State private var showConfirmation = false
    @State private var showSlideOver = false
    @AppStorage("mediaMuted") var mediaMuted: Bool = false  // Neuer Toggle für "Medien stummschalten"

    init() {
        // Setze den Hintergrund der UITableView und ihrer Zellen für diese View
        UITableView.appearance().backgroundColor = UIColor.systemGroupedBackground
        UITableViewCell.appearance().backgroundColor = UIColor.systemGroupedBackground
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea(.all)
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
                    
                    // Formular mit den übrigen Elementen
                    Form {
                        Section("Einstellungen") {
                            // Toggle zum Stummschalten der Medien
                            Toggle("Medien stummschalten", isOn: $mediaMuted)
                                .accessibilityIdentifier("toggleMediaMuted")
                            
                            Button(action: {
                                // Popup zur Bestätigung anzeigen
                                showConfirmation = true
                            }) {
                                Text("Datenbank Zurücksetzen")
                                    .foregroundColor(.red)
                            }
                            .alert(isPresented: $showConfirmation) {
                                Alert(
                                    title: Text("Datenbank zurücksetzen"),
                                    message: Text("Bist du dir sicher, dass du die Datenbank löschen möchtest?"),
                                    primaryButton: .destructive(Text("Löschen"), action: {
                                        DatabaseManager.shared.resetDatabase()
                                        withAnimation {
                                            showSlideOver = true
                                        }
                                        // SlideOver nach 3 Sekunden wieder ausblenden
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                            withAnimation {
                                                showSlideOver = false
                                            }
                                        }
                                    }),
                                    secondaryButton: .cancel(Text("Abbrechen"))
                                )
                            }
                            .accessibilityLabel("Datenbank zurücksetzen")
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
                    // Entferne den Standard-Hintergrund der Form
                    .scrollContentBackground(.hidden)
                    .background(Color(UIColor.systemGroupedBackground))
                }
                
                // SlideOver-Nachricht
                if showSlideOver {
                    SlideOverView(message: "Datenbank wurde gelöscht")
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
