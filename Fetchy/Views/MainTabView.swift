import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 0: History
            NavigationView {
                HistoryView()
            }
            .tag(0)
            .tabItem {
                Image(systemName: "clock")
                Text("History")
            }
            
            // Tab 1: Download
            DownloadView()
                .tag(1)
                .tabItem {
                    Image(systemName: "arrow.down.circle")
                    Text("Download")
                }
                
            // Tab 2: Downloads
            NavigationView {
                DownloadsView()
            }
            .tag(2)
            .tabItem {
                Image(systemName: "arrow.down.app")
                Text("Downloads")
            }
            
            // Tab 3: Settings
            NavigationView {
                SettingsView()
            }
            .tag(3)
            .tabItem {
                Image(systemName: "gearshape")
                Text("Settings")
            }
        }
        .accentColor(DesignSystem.Colors.nothingRed)
    }
}


struct TabItemData: Identifiable {
    let id = UUID()
    let tag: Int
    let title: String
    let icon: String
}

#Preview {
    MainTabView()
}
