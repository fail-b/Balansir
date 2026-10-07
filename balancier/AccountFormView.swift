import SwiftUI
import CoreData

struct AccountFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    var account: Account?

    @State private var name = ""
    @State private var selectedType = AccountType.debit
    @State private var initialBalanceString = "0"
    @State private var selectedColorHex = "#4A90D9"
    @State private var selectedIcon = "creditcard"

    private var isEditing: Bool { account != nil }

    private var initialBalance: Double {
        Double(initialBalanceString) ?? 0
    }

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    private let availableIcons = [
        "creditcard", "banknote", "building.columns", "wallet.pass",
        "dollarsign.circle", "eurosign.circle", "sterlingsign.circle",
        "briefcase", "house", "car", "airplane", "cart",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Например: Тинькофф", text: $name)
                }

                Section("Тип счёта") {
                    Picker("Тип", selection: $selectedType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Label(type.title, systemImage: type.defaultIcon).tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Начальный баланс") {
                    HStack {
                        Text("₽")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $initialBalanceString)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Цвет") {
                    colorPicker
                }

                Section("Иконка") {
                    iconPicker
                }

                Section {
                    HStack {
                        Text("Предпросмотр")
                            .foregroundStyle(.secondary)
                        Spacer()
                        accountPreview
                    }
                }
            }
            .navigationTitle(isEditing ? "Редактировать счёт" : "Новый счёт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") { saveAccount() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
        .onAppear {
            if let account {
                name = account.name
                selectedType = account.type
                initialBalanceString = String(account.initialBalance)
                selectedColorHex = account.colorHex
                selectedIcon = account.iconName
            }
        }
    }

    private var colorPicker: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
            spacing: 8
        ) {
            ForEach(Color.paletteHex, id: \.self) { hex in
                Button {
                    selectedColorHex = hex
                } label: {
                    Circle()
                        .fill(Color(hex: hex) ?? .blue)
                        .frame(height: 36)
                        .overlay {
                            if selectedColorHex == hex {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                        }
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }

    private var iconPicker: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
            spacing: 8
        ) {
            ForEach(availableIcons, id: \.self) { icon in
                Button {
                    selectedIcon = icon
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedIcon == icon
                                  ? (Color(hex: selectedColorHex) ?? .blue)
                                  : Color(.systemGray5))
                            .frame(height: 40)
                        Image(systemName: icon)
                            .font(.system(size: 17))
                            .foregroundStyle(selectedIcon == icon ? .white : .primary)
                    }
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }

    private var accountPreview: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: selectedColorHex) ?? .blue)
                    .frame(width: 36, height: 36)
                Image(systemName: selectedIcon)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(name.isEmpty ? "Название счёта" : name)
                    .font(.callout)
                    .fontWeight(.medium)
                Text(selectedType.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func saveAccount() {
        let target = account ?? Account(context: viewContext)

        if account == nil {
            target.id = UUID()
            target.createdAt = Date()
            target.isArchived = false
            let request = Account.fetchRequest()
            let count = (try? viewContext.count(for: request)) ?? 0
            target.sortOrder = Int32(count)
        }

        target.name = name.trimmingCharacters(in: .whitespaces)
        target.accountType = selectedType.rawValue
        target.initialBalance = initialBalance
        target.currency = "RUB"
        target.colorHex = selectedColorHex
        target.iconName = selectedIcon

        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    AccountFormView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
