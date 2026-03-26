import Foundation

struct AppSetting: Equatable {
    let key: String
    var value: String
}

enum AppSettingKey: String {
    case syncEnabled = "sync_enabled"
    case syncServerURL = "sync_server_url"
    case lastSyncTimestamp = "last_sync_timestamp"
    case themeMode = "theme_mode"
}
