import SwiftUI

/// Настройки (§4.8): открываются переходом вглубь по шестерёнке с Главной и Счетов.
/// Данных из репозиториев экран не читает, поэтому без ViewModel: всё хранится в `@AppStorage`.
/// Пока работают выбор темы и «Показать приветствие», остальное — заглушки.
struct SettingsView: View {
    @AppStorage(AppSettingsKey.appearance) private var appearance: AppearanceMode = .system
    @AppStorage(AppSettingsKey.statsPeriod) private var statsPeriod: StatsPeriod = .month
    @AppStorage(AppSettingsKey.statsChartKind) private var statsChartKind: StatsChartKind = .bars
    @AppStorage(AppSettingsKey.statsWeekStart) private var weekStart: WeekStart = .monday
    @AppStorage(AppSettingsKey.eveningReminder) private var eveningReminder = false
    @AppStorage(AppSettingsKey.faceID) private var faceID = false
    /// Сброс флага — `ContentView` сразу показывает онбординг (§4.9).
    @AppStorage(AppSettingsKey.hasSeenOnboarding) private var hasSeenOnboarding = false

    var body: some View {
        List {
            Section {
                Picker("Тема", selection: $appearance) {
                    ForEach(AppearanceMode.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            } header: { sectionHeader("Тема") }

            // Заглушки: экран Статистики эти значения пока не читает.
            Section {
                Picker("Период", selection: $statsPeriod) {
                    ForEach(StatsPeriod.allCases) { Text($0.title).tag($0) }
                }
                Picker("Вид диаграммы", selection: $statsChartKind) {
                    ForEach(StatsChartKind.allCases) { Text($0.title).tag($0) }
                }
                Picker("Начало недели", selection: $weekStart) {
                    ForEach(WeekStart.allCases) { Text($0.title).tag($0) }
                }
            } header: { sectionHeader("Статистика") }

            Section {
                stubRow("Валюта", value: "Рубль, ₽")
                stubRow("Начало месяца", value: "1 число")
            } header: { sectionHeader("Учёт") }

            Section {
                Toggle(isOn: $eveningReminder) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        Text("Напоминание вечером")
                        Text("В 21:00, если за день нет операций")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Colors.ink2)
                    }
                }
                Toggle("Вход по Face ID", isOn: $faceID)
            } header: { sectionHeader("Напоминания и защита") }

            Section {
                stubAction("Экспорт в CSV", icon: AppIcon.export)
                stubAction("Импорт из CoinKeeper", icon: AppIcon.importData)
                Button("Показать приветствие") { hasSeenOnboarding = false }
            } header: { sectionHeader("Данные") }

            Section {
                Text("Balansir \(appVersion)")
                    .font(Theme.Font.appVersion)
                    .foregroundStyle(Theme.Colors.ink2)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .font(Theme.Font.body)
        .foregroundStyle(Theme.Colors.ink)
        .tint(Theme.Colors.accent)
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.background)
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Theme.Font.caption)
            .foregroundStyle(Theme.Colors.ink2)
    }

    /// Строка «Название — значение» без действия (пока заглушка).
    private func stubRow(_ title: String, value: String) -> some View {
        LabeledContent(title) {
            Text(value).foregroundStyle(Theme.Colors.ink2)
        }
    }

    /// Кнопка-заглушка: видна, но неактивна, пока функция не сделана.
    private func stubAction(_ title: String, icon: String?) -> some View {
        Button {} label: {
            if let icon {
                Label { Text(title) } icon: { AppIcon.image(named: icon) }
            } else {
                Text(title)
            }
        }
        .disabled(true)
    }
}
