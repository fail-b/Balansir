import SwiftUI

/// Группа операций за один день: заголовок (день + сумма расходов справа)
/// и карточка со строками операций. Используется на Главной и в Операциях.
struct DaySection: View {
    let group: DayGroup
    /// Открытая свайпом строка ленты — одна на всю ленту.
    @Binding var openRowId: UUID?
    let onTap: (EntryModel) -> Void
    /// Тап по чипу тега в строке (поиск по тегу). nil — чипы не нажимаются.
    var onTagTap: ((TagModel) -> Void)? = nil
    /// Удаление; `false` — не удалось, строка возвращается на место.
    let onDelete: (EntryModel) async -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                Text(dayLabel(for: group.date))
                    .font(Theme.Font.sectionTitle)
                    .foregroundStyle(Theme.Colors.ink)
                Spacer()
                if group.dayExpense > 0 {
                    Text(verbatim: "\u{2212}\(MoneyFormatter.format(group.dayExpense))")
                        .font(Theme.Font.sectionTitle)
                        .foregroundStyle(Theme.Colors.ink2)
                }
            }
            // Своя зона касания у заголовка: иначе SwiftUI отдаёт тап ближайшей
            // тапаемой строке (последней операции дня выше) и открывает её редактирование.
            .contentShape(Rectangle())
            .onTapGesture {}
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                ForEach(Array(group.entries.enumerated()), id: \.element.id) { idx, entry in
                    SwipeToDeleteRow(
                        id: entry.id,
                        openRowId: $openRowId,
                        content: { EntryRow(entry: entry, isLast: idx == group.entries.count - 1, onTagTap: onTagTap) },
                        onTap: { onTap(entry) },
                        onDelete: { await onDelete(entry) }
                    )
                }
            }
            .background(Theme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
    }

    private func dayLabel(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return String(localized: "Today") }
        if cal.isDateInYesterday(date) { return String(localized: "Yesterday") }
        // «12 октября», «October 12» — порядок и падеж из локали.
        return date.formatted(.dateTime.day().month(.wide))
    }
}
