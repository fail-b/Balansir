import SwiftUI

/// Ключи `@AppStorage` для экрана Настроек (§4.8) — в одном месте, чтобы не опечататься.
enum AppSettingsKey {
    static let appearance = "appearance"
    static let statsPeriod = "statsPeriod"
    static let statsChartKind = "statsChartKind"
    static let statsWeekStart = "statsWeekStart"
    static let eveningReminder = "eveningReminder"
    static let faceID = "faceID"
}

/// Тема приложения: применяется сразу через `.preferredColorScheme` в `BalansirApp`.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: Self { self }

    var title: String {
        switch self {
        case .system: "Системная"
        case .light: "Светлая"
        case .dark: "Тёмная"
        }
    }

    /// `nil` — как в системе.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

// MARK: - Настройки статистики (пока заглушки: значение сохраняется, но экран Статистики его не читает)

enum StatsPeriod: String, CaseIterable, Identifiable {
    case week, month, year
    var id: Self { self }

    var title: String {
        switch self {
        case .week: "Неделя"
        case .month: "Месяц"
        case .year: "Год"
        }
    }
}

enum StatsChartKind: String, CaseIterable, Identifiable {
    case bars, line, pie
    var id: Self { self }

    var title: String {
        switch self {
        case .bars: "Столбики"
        case .line: "Линия"
        case .pie: "Круговая"
        }
    }
}

enum WeekStart: String, CaseIterable, Identifiable {
    case monday, sunday
    var id: Self { self }

    var title: String {
        switch self {
        case .monday: "Понедельник"
        case .sunday: "Воскресенье"
        }
    }
}
