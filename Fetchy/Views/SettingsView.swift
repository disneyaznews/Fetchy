import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @State private var proTapCount = 0
    @State private var playingSplash = false
    
    private var appDisplayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "App"
    }
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                List {
                    Section(header: DotMatrixText(text: "HAPTICS", usesUppercase: true)) {
                        Toggle("Vibration Feedback", isOn: $settings.vibrationEnabled)
                        
                        if settings.vibrationEnabled {
                            Picker("Intensity", selection: $settings.vibrationStrength) {
                                Text("Light").tag("light")
                                Text("Medium").tag("medium")
                                Text("Heavy").tag("heavy")
                            }
                            
                            Stepper(value: $settings.hapticFrequency, in: 1...10, step: 1) {
                                HStack {
                                    Text("Frequency Steps")
                                    Spacer()
                                    Text("\(settings.hapticFrequency)%")
                                        .foregroundStyle(DesignSystem.Colors.nothingRed)
                                        .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .bold))
                                }
                            }
                        }
                    }
                    
                    Section(header: DotMatrixText(text: "VISUALS", usesUppercase: true)) {
                        Toggle("Default Progress Visible", isOn: $settings.progressVisible)
                        Toggle("Safety Warnings (Toasts)", isOn: $settings.toastEnabled)
                        
                        if settings.toastEnabled {
                            Stepper(value: $settings.toastDelaySeconds, in: 1...30, step: 1) {
                                HStack {
                                    Text("Warning Delay")
                                    Spacer()
                                    Text("\(settings.toastDelaySeconds)s")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    Section(header: DotMatrixText(text: "DEFAULTS", usesUppercase: true)) {
                        NavigationLink(destination: DefaultsManagementView()) {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundStyle(.blue)
                                Text("Default Management")
                            }
                        }
                    }
                    
                    Section(header: DotMatrixText(text: "DIAGNOSTICS", usesUppercase: true)) {
                        NavigationLink(destination: DetailedLogView(targetEntryID: nil)) {
                            HStack {
                                Image(systemName: "terminal.fill")
                                    .foregroundStyle(DesignSystem.Colors.nothingRed)
                                Text("Detailed Sequence Logs")
                            }
                        }
                        
                        Link(destination: URL(string: "https://github.com/nisesimadao/Fetchy")!) {
                            HStack {
                                Image(systemName: "safari.fill")
                                    .foregroundStyle(.blue)
                                Text("Project Documentation")
                            }
                        }
                    }
                    
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 4) {
                                Text(appDisplayName)
                                    .font(.nothingMeta)
                                    .foregroundStyle(.primary)
                                    .onTapGesture {
                                        proTapCount += 1
                                        if proTapCount >= 3 {
                                            proTapCount = 0
                                            playingSplash = true
                                        }
                                    }
                                Text("Version \(appVersion) (Build \(appBuild))")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                    
                    // Extra space for floating bar
                    Color.clear
                        .frame(height: 100)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .navigationTitle("Settings")
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                )
            }
            
            if playingSplash {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    
                    SplashVideoView(videoName: "Splash.mov", isActive: $playingSplash)
                }
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: playingSplash)
    }
}

