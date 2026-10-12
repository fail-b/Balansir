import Foundation

/// Логика тегов без UI и Core Data: порядок в карусели шита и сравнение имён (§4.7).
enum TagUsageService {
    /// Порядок карусели тегов: сначала чаще использованные с категорией, затем чаще использованные
    /// вообще, затем по имени. Фильтр (скрытые и т.п.) — на стороне вызывающего, здесь только сортировка.
    /// Удалённые операции не считаются.
    static func ordered(_ tags: [TagModel], entries: [EntryModel], category: CategoryModel?) -> [TagModel] {
        var withCategory: [UUID: Int] = [:]
        var overall: [UUID: Int] = [:]
        for entry in entries where !entry.isSoftDeleted {
            let sameCategory = category != nil && entry.category?.id == category?.id
            for tag in entry.tags {
                overall[tag.id, default: 0] += 1
                if sameCategory { withCategory[tag.id, default: 0] += 1 }
            }
        }
        return tags.sorted { a, b in
            let ca = withCategory[a.id] ?? 0, cb = withCategory[b.id] ?? 0
            if ca != cb { return ca > cb }
            let oa = overall[a.id] ?? 0, ob = overall[b.id] ?? 0
            if oa != ob { return oa > ob }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
    }

    /// Имя тега без пробелов по краям (как ввёл пользователь, регистр сохраняется).
    static func cleanName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Совпадают ли имена тегов: без учёта регистра и пробелов по краям («бензин » = «Бензин»).
    static func sameName(_ a: String, _ b: String, locale: Locale) -> Bool {
        cleanName(a).compare(cleanName(b), options: .caseInsensitive, range: nil, locale: locale) == .orderedSame
    }
}
