import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // TODO: Replace with your actual App Group Identifier
    private let appGroupIdentifier = "group.com.nisesimadao.Fetchy"
    
    private var userDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
    
    @AppStorage("vibrationEnabled") var vibrationEnabled: Bool = true
    @AppStorage("vibrationStrength") var vibrationStrength: String = "light" // light, medium, heavy
    @AppStorage("progressVisible") var progressVisible: Bool = false
    @AppStorage("toastEnabled") var toastEnabled: Bool = true
    @AppStorage("toastIntervals") var toastIntervals: String = "5,8" // comma separated minutes
    @AppStorage("defaultResolution") var defaultResolution: String = "1080p"
    @AppStorage("defaultQuality") var defaultQuality: String = "44.1k"
    
    // Helper to get UserDefaults for non-SwiftUI contexts (like Extension code not in a View)
    func getValue<T>(forKey key: String) -> T? {
        userDefaults.value(forKey: key) as? T
    }
}
