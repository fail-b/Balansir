import SwiftUI

struct DonutChart: View {
    let items: [(category: CategoryModel, total: Decimal)]
    let total: Decimal

    private struct Slice: Identifiable {
        let id: UUID
        let color: Color
        let startAngle: Angle
        let endAngle: Angle
    }

    private var slices: [Slice] {
        var result: [Slice] = []
        var cumulative = Decimal(0)
        let totalDouble = (total as NSDecimalNumber).doubleValue
        for item in items {
            let start = (cumulative as NSDecimalNumber).doubleValue / totalDouble
            cumulative += item.total
            let end = (cumulative as NSDecimalNumber).doubleValue / totalDouble
            result.append(Slice(
                id: item.category.id,
                color: Color(hex: item.category.colorHex) ?? .orange,
                startAngle: .degrees(start * 360 - 90),
                endAngle: .degrees(end * 360 - 90)
            ))
        }
        return result
    }

    var body: some View {
        ZStack {
            ForEach(slices) { slice in
                DonutSlice(startAngle: slice.startAngle, endAngle: slice.endAngle, color: slice.color)
            }
            VStack(spacing: 4) {
                Text((total as NSDecimalNumber).doubleValue, format: .currency(code: "RUB"))
                    .font(.system(.callout, design: .rounded, weight: .bold))
                Text("всего").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct DonutSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2
            let innerRadius = radius * 0.6
            Path { path in
                path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}
