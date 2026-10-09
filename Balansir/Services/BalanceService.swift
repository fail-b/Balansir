import Foundation

enum BalanceService {
    static func computeBalances(accounts: [AccountModel], entries: [EntryModel]) -> [UUID: Decimal] {
        var result: [UUID: Decimal] = [:]
        for a in accounts { result[a.id] = a.initialBalance }
        for e in entries {
            if let id = e.fromAccount?.id { result[id, default: 0] -= e.amount }
            if let id = e.toAccount?.id { result[id, default: 0] += e.amount }
        }
        return result
    }
}
