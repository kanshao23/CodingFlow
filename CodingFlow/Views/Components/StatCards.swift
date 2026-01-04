//
//  StatCards.swift
//  CodingFlow
//
//  统计卡片组件
//

import SwiftUI
import Charts

// MARK: - Dashboard Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let trend: Trend?

    init(
        _ title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        color: Color = .blue,
        trend: Trend? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.trend = trend
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Spacer()

                if let trend = trend {
                    TrendBadge(trend: trend)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Trend Badge

struct TrendBadge: View {
    let trend: Trend

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trend.icon)
            Text(trend.value)
        }
        .font(.caption)
        .foregroundStyle(trend.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(trend.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

enum Trend {
    case up(Double)
    case down(Double)
    case neutral

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .neutral: return .gray
        }
    }

    var value: String {
        switch self {
        case .up(let v): return "+\(Int(v))%"
        case .down(let v): return "-\(Int(v))%"
        case .neutral: return "0%"
        }
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat

    init(progress: Double, color: Color = .blue, lineWidth: CGFloat = 8) {
        self.progress = min(max(progress, 0), 100)
        self.color = color
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress / 100)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(Int(progress))%")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("Complete")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Issue Count Card

struct IssueCountCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - AI Stats Card

struct AIStatsCard: View {
    let todayInteractions: Int
    let totalTokens: Int
    let aiGenerationRate: Double
    let mostUsedTool: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.cyan)
                Text("AI Activity")
                    .font(.headline)
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("\(todayInteractions)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading) {
                    Text(formatNumber(totalTokens))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Tokens")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading) {
                    Text("\(Int(aiGenerationRate))%")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("AI Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Image(systemName: "cpu")
                    .foregroundStyle(.secondary)
                Text("Most used: \(mostUsedTool)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func formatNumber(_ num: Int) -> String {
        if num >= 1000000 {
            return String(format: "%.1fM", Double(num) / 1000000)
        } else if num >= 1000 {
            return String(format: "%.1fK", Double(num) / 1000)
        }
        return "\(num)"
    }
}

// MARK: - Weekly Activity Chart

struct WeeklyActivityChart: View {
    let data: [DayActivity]

    struct DayActivity: Identifiable {
        let id = UUID()
        let day: String
        let count: Int
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity This Week")
                .font(.headline)

            Chart(data) { item in
                BarMark(
                    x: .value("Day", item.day),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(4)
            }
            .frame(height: 150)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

#Preview("Stat Cards") {
    ScrollView {
        VStack(spacing: 16) {
            StatCard(
                "Total Issues",
                value: "42",
                subtitle: "3 completed today",
                icon: "list.bullet.rectangle",
                color: .blue,
                trend: .up(12)
            )

            HStack(spacing: 16) {
                IssueCountCard(title: "In Progress", count: 5, icon: "play.circle", color: .orange)
                IssueCountCard(title: "In Review", count: 3, icon: "eye.circle", color: .purple)
                IssueCountCard(title: "Done", count: 12, icon: "checkmark.circle", color: .green)
            }

            AIStatsCard(
                todayInteractions: 23,
                totalTokens: 45800,
                aiGenerationRate: 68,
                mostUsedTool: "Claude Code"
            )

            WeeklyActivityChart(data: [
                .init(day: "Mon", count: 8),
                .init(day: "Tue", count: 12),
                .init(day: "Wed", count: 6),
                .init(day: "Thu", count: 15),
                .init(day: "Fri", count: 9),
                .init(day: "Sat", count: 3),
                .init(day: "Sun", count: 5)
            ])
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
