import SwiftUI

/// Группа операций за один день: заголовок (день + сумма расходов справа)
/// и карточка со строками операций. Используется на Главной и в Операциях.
struct DaySection: View {
    let group: DayGroup
    let onTap: (EntryModel) -> Void
    let onDelete: (EntryModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                Text(dayLabel(for: group.date))
                    .font(Theme.Font.sectionTitle)
                    .foregroundStyle(Theme.Colors.ink)
                Spacer()
                if group.dayExpense > 0 {
                    Text("\u{2212}\(MoneyFormatter.format(group.dayExpense))")
                        .font(Theme.Font.sectionTitle)
                        .foregroundStyle(Theme.Colors.ink2)
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(group.entries.enumerated()), id: \.element.id) { idx, entry in
                    SwipeToDeleteRow(
                        content: { EntryRow(entry: entry, isLast: idx == group.entries.count - 1) },
                        onTap: { onTap(entry) },
                        onDelete: { onDelete(entry) }
                    )
                }
            }
            .background(Theme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
    }

    private func dayLabel(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Сегодня" }
        if cal.isDateInYesterday(date) { return "Вчера" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMMM"
        return f.string(from: date)
    }
}
