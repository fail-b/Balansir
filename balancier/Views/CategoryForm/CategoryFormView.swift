import SwiftUI

struct CategoryFormView: View {
    @Bindable var viewModel: CategoryFormViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Например: Продукты", text: $viewModel.name)
                }
                Section("Тип") {
                    Picker("Тип", selection: $viewModel.selectedType) {
                        ForEach(CategoryType.allCases, id: \.self) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                Section("Цвет") { colorPicker }
                Section("Иконка") { iconPicker }
                Section {
                    HStack {
                        Text("Предпросмотр").foregroundStyle(.secondary)
                        Spacer()
                        categoryPreview
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Редактировать категорию" : "Новая категория")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Ошибка", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") {
                        Task {
                            await viewModel.save()
                            if viewModel.errorMessage == nil { dismiss() }
                        }
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
                        .fill(Color(hex: hex) ?? Theme.Colors.fallback)
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
            ForEach(AppIcon.categoryPicker, id: \.self) { icon in
                Button { viewModel.selectedIcon = icon } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.Radius.s)
                            .fill(viewModel.selectedIcon == icon
                                ? (Color(hex: viewModel.selectedColorHex) ?? Theme.Colors.fallback)
                                : Color(.systemGray5))
                            .frame(height: 40)
                        AppIcon.image(named: icon)
                            .font(.system(size: 17))
                            .foregroundStyle(viewModel.selectedIcon == icon ? .white : .primary)
                    }
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }

    private var categoryPreview: some View {
        HStack(spacing: Theme.Spacing.s) {
            ZStack {
                Circle()
                    .fill((Color(hex: viewModel.selectedColorHex) ?? Theme.Colors.fallback).opacity(0.15))
                    .frame(width: 36, height: 36)
                AppIcon.image(named: viewModel.selectedIcon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: viewModel.selectedColorHex) ?? Theme.Colors.fallback)
            }
            Text(viewModel.name.isEmpty ? "Название категории" : viewModel.name)
                .font(.callout).fontWeight(.medium)
        }
    }
}
