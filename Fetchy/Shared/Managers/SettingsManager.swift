import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let appGroupIdentifier = "group.com.nisesimadao.Fetchy"
    private var store: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    @Published var vibrationEnabled: Bool = true {
        didSet { save("vibrationEnabled", value: vibrationEnabled) }
    }
    
    @Published var vibrationStrength: String = "light" {
        didSet { save("vibrationStrength", value: vibrationStrength) }
    }
    
    @Published var progressVisible: Bool = false {
        didSet { save("progressVisible", value: progressVisible) }
    }
    
    @Published var toastEnabled: Bool = true {
        didSet { save("toastEnabled", value: toastEnabled) }
    }
    
    @Published var toastIntervals: String = "5,8" {
        didSet { save("toastIntervals", value: toastIntervals) }
    }
    
    @Published var defaultResolution: String = "1080p" {
        didSet { save("defaultResolution", value: defaultResolution) }
    }
    
    @Published var defaultQuality: String = "44.1k" {
        didSet { save("defaultQuality", value: defaultQuality) }
    }
    
    private init() {
        self.vibrationEnabled = store?.bool(forKey: "vibrationEnabled") ?? true
        self.vibrationStrength = store?.string(forKey: "vibrationStrength") ?? "light"
        self.progressVisible = store?.bool(forKey: "progressVisible") ?? false
        self.toastEnabled = store?.bool(forKey: "toastEnabled") ?? true
        self.toastIntervals = store?.string(forKey: "toastIntervals") ?? "5,8"
        self.defaultResolution = store?.string(forKey: "defaultResolution") ?? "1080p"
        self.defaultQuality = store?.string(forKey: "defaultQuality") ?? "44.1k"
    }
    
    private func save(_ key: String, value: Any) {
        store?.set(value, forKey: key)
    }
    
    func getValue<T>(forKey key: String) -> T? {
        store?.value(forKey: key) as? T
    }
}

