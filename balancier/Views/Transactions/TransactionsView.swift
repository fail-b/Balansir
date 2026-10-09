import SwiftUI

struct TransactionsView: View {
    @Bindable var viewModel: TransactionsViewModel
    @Binding var isScrolled: Bool

    @State private var editEntryVM: AddEntryViewModel?
    @State private var showingEditEntry = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Операции")
                    .font(Theme.Font.screenTitle)
                    .tracking(Theme.Font.Tracking.screenTitle)
                    .foregroundStyle(Theme.Colors.ink)
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.top, Theme.Spacing.l)

                searchField
                    .padding(.top, Theme.Spacing.m)
                    .padding(.horizontal, Theme.Spacing.l)

                if viewModel.entriesByDay.isEmpty {
                    emptyStateView
                } else {
                    ForEach(viewModel.entriesByDay) { group in
                        DaySection(
                            group: group,
                            onTap: { entry in
                                editEntryVM = viewModel.makeEditEntryViewModel(for: entry)
                                showingEditEntry = true
                            },
                            onDelete: { entry in
                                Task { await viewModel.delete(entry) }
                            }
                        )
                        .padding(.top, Theme.Spacing.xl)
                        .padding(.horizontal, Theme.Spacing.l)
                    }
                }
            }
            .padding(.bottom, Theme.Spacing.s)
        }
        .reportsScroll(to: $isScrolled)
        .background(Theme.Colors.background)
        .sheet(isPresented: $showingEditEntry, onDismiss: { Task { await viewModel.load() } }) {
            if let vm = editEntryVM {
                AddEntryView(viewModel: vm)
            }
        }
        .task { await viewModel.load() }
        .alert("Ошибка", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Поиск

    private var searchField: some View {
        HStack(spacing: Theme.Spacing.s) {
            AppIcon.image(named: AppIcon.search)
                .font(.system(size: 17))
                .foregroundStyle(Theme.Colors.ink2)
            TextField("Категория, счёт или заметка", text: $viewModel.searchText)
                .font(.system(size: 17))
                .foregroundStyle(Theme.Colors.ink)
        }
        .padding(.horizontal, Theme.Spacing.m)
        .frame(height: 40)
        .background(Theme.Colors.fill, in: RoundedRectangle(cornerRadius: Theme.Radius.search))
    }

    // MARK: - Пусто

    private var emptyStateView: some View {
        Text(viewModel.searchText.isEmpty
             ? "Операций пока нет. Нажмите «+», чтобы добавить первую."
             : "Ничего не найдено")
            .font(.subheadline)
            .foregroundStyle(Theme.Colors.ink2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
            .padding(.horizontal, Theme.Spacing.l)
    }
}
