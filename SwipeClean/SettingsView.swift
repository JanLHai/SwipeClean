//
//  SettingsView.swift
//  SwipeClean
//
//  Created by Jan Haider on 03.02.25.
//

import SwiftUICore
import SwiftUI
import MyFeedbackLibrary

struct SettingsView: View {
    @State private var showConfirmation = false
    @State private var showSlideOver = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.gray
                                    .ignoresSafeArea()
                Form {
                    Section("Einstellungen") {
                        Button(action: {
                            // Popup zur Bestätigung anzeigen
                            showConfirmation = true
                        }) {
                            Text("Datenbank Zurücksetzen")
                                .foregroundColor(.red)
                        }.alert(isPresented: $showConfirmation) {
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
                    }
                    
                    Section("Hilfe") {
                        NavigationLink(destination: FeatureRequestsView()) {
                            Text("Feature Anfragen")
                        }
                        Button(action: {
                            openEmail()
                        }) {
                            Text("Supportanfrage")
                        }
                    }
                    
                    Section("Information") {
                        Button(action: {
                            if let url = URL(string: "https://swipeclean.jan-haider.dev/PrivacyPolice.html") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Privacy Policy")
                        }
                    }
                }
                .navigationTitle("Einstellungen")
                .navigationBarTitleDisplayMode(.inline)
                
                // SlideOver-Nachricht
                if showSlideOver {
                    SlideOverView(message: "Datenbank wurde gelöscht")
                        .transition(.move(edge: .trailing))
                        .zIndex(1)
                        .accessibilityIdentifier("slideOverMessage")
                }
            }
        }
        // Alert, der den Löschvorgang bestätigt
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
