import SwiftUI

struct EntryRowView: View {
    let entry: EntryModel

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(entry.displayColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                AppIcon.image(named: entry.displayIcon)
                    .font(.system(size: 17))
                    .foregroundStyle(entry.displayColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayTitle)
                    .font(.callout)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    Text(entry.displayAccount)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let note = entry.note, !note.isEmpty {
                        Text("· \(note)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.formattedAmount)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(entry.amountColor)
                Text(entry.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
    }
}
