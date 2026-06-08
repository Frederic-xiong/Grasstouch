import SwiftUI
import CoreData

struct DashboardView: View {
    @FetchRequest(
        entity: ThrottleSession.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ThrottleSession.startedAt, ascending: false)],
        predicate: NSPredicate(format: "startedAt >= %@", Date().addingTimeInterval(-7*24*3600) as NSDate)
    )
    private var sessions: FetchedResults<ThrottleSession>

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summaryCard
                    BarChart(buckets: dailyTotals())
                        .frame(height: 180)
                        .padding(.horizontal)
                    frustrationCard
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
        }
    }

    private var summaryCard: some View {
        let totalSeconds = sessions.reduce(0.0) { acc, s in
            let end = s.endedAt ?? Date()
            return acc + end.timeIntervalSince(s.startedAt)
        }
        return VStack(spacing: 4) {
            Text(formatHours(totalSeconds)).font(.system(size: 40, weight: .bold, design: .rounded))
            Text("throttled in the last 7 days").font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private var frustrationCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sessions started").font(.headline)
            Text("\(sessions.count)").font(.system(size: 32, weight: .bold, design: .rounded))
            Text("Each one is a moment you'd otherwise have spent scrolling.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private func dailyTotals() -> [BarChart.Bucket] {
        let cal = Calendar.current
        var totals: [Date: TimeInterval] = [:]
        for s in sessions {
            let day = cal.startOfDay(for: s.startedAt ?? Date())
            let end = s.endedAt ?? Date()
            totals[day, default: 0] += end.timeIntervalSince(s.startedAt ?? end)
        }
        return (0..<7).reversed().map { offset in
            let day = cal.startOfDay(for: Date().addingTimeInterval(Double(-offset) * 86400))
            return .init(label: shortDay(day), value: totals[day] ?? 0)
        }
    }

    private func shortDay(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "E"; return f.string(from: d)
    }

    private func formatHours(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        return "\(h)h \(m)m"
    }
}

struct BarChart: View {
    struct Bucket: Identifiable { let id = UUID(); let label: String; let value: Double }
    let buckets: [Bucket]

    var body: some View {
        GeometryReader { geo in
            let maxV = max(buckets.map(\.value).max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(buckets) { b in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.accentColor.opacity(0.7))
                            .frame(height: CGFloat(b.value / maxV) * (geo.size.height - 24))
                        Text(b.label).font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}
