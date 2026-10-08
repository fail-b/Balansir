import SwiftUI

struct AccountFormView: View {
    @Bindable var viewModel: AccountFormViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Например: Тинькофф", text: $viewModel.name)
                }
                Section("Тип счёта") {
                    Picker("Тип", selection: $viewModel.selectedType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Label(type.title, systemImage: type.defaultIcon).tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                Section("Начальный баланс") {
                    HStack {
                        Text("₽").foregroundStyle(.secondary)
                        TextField("0", text: $viewModel.initialBalanceString).keyboardType(.decimalPad)
                    }
                }
                Section("Цвет") { colorPicker }
                Section("Иконка") { iconPicker }
                Section {
                    HStack {
                        Text("Предпросмотр").foregroundStyle(.secondary)
                        Spacer()
                        accountPreview
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Редактировать счёт" : "Новый счёт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") {
                        Task { await viewModel.save(existingCount: 0); dismiss() }
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }

    private var colorPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
            ForEach(Theme.Palette.hexColors, id: \.self) { hex in
                Button { viewModel.selectedColorHex = hex } label: {
                    Circle()
                        .fill(Color(hex: hex) ?? .blue)
                        .frame(height: 36)
                        .overlay {
                            if viewModel.selectedColorHex == hex {
                                Image(systemName: "checkmark").font(.caption).fontWeight(.bold).foregroundStyle(.white)
                            }
                        }
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }

    private var iconPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
            ForEach(AppIcon.accountPicker, id: \.self) { icon in
                Button { viewModel.selectedIcon = icon } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.Radius.s)
                            .fill(viewModel.selectedIcon == icon ? (Color(hex: viewModel.selectedColorHex) ?? .blue) : Color(.systemGray5))
                            .frame(height: 40)
                        Image(systemName: icon).font(.system(size: 17))
                            .foregroundStyle(viewModel.selectedIcon == icon ? .white : .primary)
                    }
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }

    private var accountPreview: some View {
        HStack(spacing: Theme.Spacing.s) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.s)
                    .fill(Color(hex: viewModel.selectedColorHex) ?? .blue)
                    .frame(width: 36, height: 36)
                Image(systemName: viewModel.selectedIcon).font(.system(size: 16)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.name.isEmpty ? "Название счёта" : viewModel.name)
                    .font(.callout).fontWeight(.medium)
                Text(viewModel.selectedType.title).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
