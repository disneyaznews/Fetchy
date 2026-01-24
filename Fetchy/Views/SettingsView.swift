import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    
    var body: some View {
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
                                    .fontWeight(.bold)
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
                
                Section(header: DotMatrixText(text: "QUALITY", usesUppercase: true)) {
                    Picker("Default Resolution", selection: $settings.defaultResolution) {
                        Text("1080p").tag("1080p")
                        Text("720p").tag("720p")
                        Text("480p").tag("480p")
                        Text("Highest").tag("best")
                    }
                    
                    Picker("Audio Quality", selection: $settings.defaultQuality) {
                        Text("44.1kHz").tag("44.1k")
                        Text("48kHz").tag("48k")
                        Text("96kHz").tag("96k")
                        Text("Lossless").tag("lossless")
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
                            Text("Fetchy Pro")
                                .font(.nothingMeta)
                                .foregroundStyle(.primary)
                            Text("Version 1.6.0 (Build 12)")
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
    }
}
