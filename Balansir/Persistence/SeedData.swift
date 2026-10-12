import CoreData

enum SeedData {
    /// Только категории. Счета пользователь заводит сам в онбординге (§4.9) — демо-счетов нет.
    static func populate(in context: NSManagedObjectContext) {
        addCategories(to: context)
        try? context.save()
    }

    private static func addCategories(to context: NSManagedObjectContext) {
        let expense: [(String, String, String)] = [
            ("Еда", "fork.knife", "#FF6B6B"),
            ("Продукты", "cart", "#FF8C42"),
            ("Транспорт", "tram", "#4ECDC4"),
            ("Поездки", "airplane", "#45B7D1"),
            ("Машина", "car", "#96CEB4"),
            ("Услуги", "wrench.and.screwdriver", "#DDA0DD"),
            ("Одежда", "tshirt", "#E0B83A"),
            ("Кредиты", "creditcard", "#E74C3C"),
            ("Подписки", "star", "#9B59B6"),
            ("Развлечения", "gamecontroller", "#1ABC9C"),
            ("Здоровье", "heart.text.square", "#E91E63"),
            ("Аптеки", "pills", "#00BCD4"),
            ("Подарки", "gift", "#FF5722"),
            ("Хозтовары", "house", "#795548"),
            ("Бизнес", "briefcase", "#607D8B"),
            ("Электроника", "iphone", "#2196F3"),
            ("Связь", "phone", "#2E9E5B"),
            ("Физкультура", "figure.run", "#FF9800"),
            ("За квартиру", "building.2", "#3F51B5"),
        ]
        let income: [(String, String, String)] = [
            ("Зарплата", "banknote", "#4CAF50"),
            ("Фриланс", "laptopcomputer", "#2196F3"),
            ("Кэшбэк", "percent", "#00BCD4"),
            ("Возврат", "arrow.uturn.left", "#9C27B0"),
            ("Другое", "ellipsis.circle", "#607D8B"),
        ]

        for (i, (name, icon, color)) in expense.enumerated() {
            let c = Category(context: context)
            c.id = UUID()
            c.name = name
            c.categoryType = CategoryType.expense.rawValue
            c.iconName = icon
            c.colorHex = color
            c.sortOrder = Int32(i)
            c.createdAt = Date()
            c.updatedAt = Date()
            c.isArchived = false
        }
        for (i, (name, icon, color)) in income.enumerated() {
            let c = Category(context: context)
            c.id = UUID()
            c.name = name
            c.categoryType = CategoryType.income.rawValue
            c.iconName = icon
            c.colorHex = color
            c.sortOrder = Int32(i)
            c.createdAt = Date()
            c.updatedAt = Date()
            c.isArchived = false
        }
    }
}
