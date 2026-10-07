import SwiftUI
import CoreData

struct AddEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "sortOrder", ascending: true)],
        predicate: NSPredicate(format: "isArchived == NO")
    ) private var accounts: FetchedResults<Account>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "sortOrder", ascending: true)],
        predicate: NSPredicate(format: "isArchived == NO")
    ) private var categories: FetchedResults<Category>

    @State private var selectedType = EntryType.expense
    @State private var amountString = "0"
    @State private var selectedAccount: Account?
    @State private var selectedToAccount: Account?
    @State private var selectedCategory: Category?
    @State private var note = ""
    @State private var date = Date()

    private var amount: Double { Double(amountString) ?? 0 }

    private var filteredCategories: [Category] {
        categories.filter { $0.categoryType == selectedType.rawValue }
    }

    private var canSave: Bool {
        guard amount > 0 else { return false }
        switch selectedType {
        case .expense, .income: return selectedAccount != nil && selectedCategory != nil
        case .transfer: return selectedAccount != nil && selectedToAccount != nil && selectedAccount?.id != selectedToAccount?.id
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Type selector
                Picker("Тип", selection: $selectedType) {
                    ForEach(EntryType.allCases, id: \.self) { type in
                        Text(type.title).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .onChange(of: selectedType) { _, _ in
                    selectedCategory = nil
                }

                // Amount display
                Text(amountString == "0" ? "0 ₽" : formatAmountDisplay())
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(selectedType.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Divider()

                ScrollView {
                    VStack(spacing: 20) {
                        // Account selector
                        accountSection

                        // Category or destination account
                        if selectedType == .transfer {
                            toAccountSection
                        } else {
                            categorySection
                        }

                        // Note and date
                        noteAndDateSection
                    }
                    .padding(.vertical, 16)
                }

                Divider()

                // Numpad
                NumpadView(amountString: $amountString)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
            .navigationTitle("Новая операция")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") { saveEntry() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
        .onAppear {
            selectedAccount = accounts.first
        }
    }

    private func formatAmountDisplay() -> String {
        let value = amount
        return value.formatted(.currency(code: "RUB").precision(.fractionLength(amountString.contains(".") ? 2 : 0)))
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedType == .transfer ? "Откуда" : "Счёт")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(accounts) { account in
                        AccountPillButton(
                            account: account,
                            isSelected: selectedAccount?.id == account.id
                        ) {
                            selectedAccount = account
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var toAccountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Куда")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(accounts.filter { $0.id != selectedAccount?.id }) { account in
                        AccountPillButton(
                            account: account,
                            isSelected: selectedToAccount?.id == account.id
                        ) {
                            selectedToAccount = account
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Категория")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                spacing: 8
            ) {
                ForEach(filteredCategories) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory?.id == category.id
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var noteAndDateSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "text.quote")
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                TextField("Заметка", text: $note)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)

            DatePicker("Дата", selection: $date, displayedComponents: .date)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
        }
    }

    private func saveEntry() {
        let entry = Entry(context: viewContext)
        entry.id = UUID()
        entry.date = date
        entry.entryType = selectedType.rawValue
        entry.amount = amount
        entry.currency = "RUB"
        entry.note = note.isEmpty ? nil : note
        entry.isRecurring = false
        entry.createdAt = Date()

        switch selectedType {
        case .expense:
            entry.fromAccount = selectedAccount
            entry.category = selectedCategory
        case .income:
            entry.toAccount = selectedAccount
            entry.category = selectedCategory
        case .transfer:
            entry.fromAccount = selectedAccount
            entry.toAccount = selectedToAccount
        }

        try? viewContext.save()
        dismiss()
    }
}

struct AccountPillButton: View {
    let account: Account
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: account.iconName)
                    .font(.caption)
                Text(account.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected ? account.color : Color(.systemGray5),
                in: Capsule()
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.color : category.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: category.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? .white : category.color)
                }
                Text(category.name)
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? category.color : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}

struct NumpadView: View {
    @Binding var amountString: String

    private let rows: [[String]] = [
        ["7", "8", "9"],
        ["4", "5", "6"],
        ["1", "2", "3"],
        [".", "0", "⌫"]
    ]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            handleKey(key)
                        } label: {
                            Group {
                                if key == "⌫" {
                                    Image(systemName: "delete.left")
                                        .font(.title3)
                                } else {
                                    Text(key)
                                        .font(.title2)
                                        .fontWeight(.medium)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
        }
    }

    private func handleKey(_ key: String) {
        switch key {
        case "⌫":
            if amountString.count > 1 {
                amountString.removeLast()
            } else {
                amountString = "0"
            }
        case ".":
            if !amountString.contains(".") {
                amountString += "."
            }
        default:
            if amountString == "0" {
                amountString = key
            } else if amountString.count < 12 {
                amountString += key
            }
        }
    }
}

#Preview {
    AddEntryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
