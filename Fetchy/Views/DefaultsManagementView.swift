import SwiftUI

struct DefaultsManagementView: View {
    @ObservedObject var settings = SettingsManager.shared
    
    // Constants for pickers
    let videoResolutions = ["MAX", "2160p", "1080p", "720p", "480p"]
    let audioBitrates = ["320", "256", "192", "128"]
    
    var body: some View {
        Form {
            Section(header: DotMatrixText(text: "VIDEO PREFERENCES")) {
                Picker("Default Resolution", selection: $settings.defaultResolution) {
                    ForEach(videoResolutions, id: \.self) { res in
                        Text(res).tag(res)
                    }
                }
                Picker("Default Format", selection: $settings.defaultVideoFormat) {
                    ForEach(["mp4", "webm", "mkv", "mov"], id: \.self) { fmt in
                        Text(fmt.uppercased()).tag(fmt)
                    }
                }
            }
            
            Section(header: DotMatrixText(text: "AUDIO PREFERENCES")) {
                Picker("Default Bitrate", selection: $settings.defaultBitrate) {
                    ForEach(audioBitrates, id: \.self) { rate in
                        Text("\(rate) kbps").tag(rate)
                    }
                }
                Picker("Default Format", selection: $settings.defaultAudioFormat) {
                    ForEach(["mp3", "m4a", "wav", "ogg"], id: \.self) { fmt in
                        Text(fmt.uppercased()).tag(fmt)
                    }
                }
            }
            
            Section(header: DotMatrixText(text: "METADATA & POST-PROCESSING")) {
                Toggle("Embed Metadata", isOn: $settings.embedMetadata)
                Toggle("Embed Thumbnail", isOn: $settings.embedThumbnail)
                Toggle("Remove Sponsors (Beta)", isOn: $settings.removeSponsors)
                Toggle("Embed Subtitles", isOn: $settings.embedSubtitles)
                Toggle("Embed Chapters", isOn: $settings.embedChapters)
            }
            
            Section(footer: Text("These settings will be used as the initial state for new downloads.")) {
                // Empty section for footer
            }
        }
        .navigationTitle("Default Management")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        DefaultsManagementView()
    }
}
