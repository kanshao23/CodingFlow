//
//  StatCard.swift
//  CodingFlow
//
//  统一统计卡片组件 - 替代所有统计卡片变体
//  Unified stat card component - replaces all stat card variations
//

import SwiftUI

/// 统一统计卡片组件 (Design System version)
/// Unified stat card component (Design System version)
struct DSStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: Trend?
    let size: Size

    // MARK: - Size Enum

    enum Size {
        case small, medium, large

        var padding: CGFloat {
            switch self {
            case .small: return DesignTokens.Spacing.sm
            case .medium: return DesignTokens.Spacing.md
            case .large: return DesignTokens.Spacing.lg
            }
        }

        var valueFont: Font {
            switch self {
            case .small: return DesignTokens.Typography.title3
            case .medium: return DesignTokens.Typography.title2
            case .large: return DesignTokens.Typography.largeTitle
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 24
            case .large: return 32
            }
        }
    }

    // MARK: - Trend Enum

    enum Trend {
        case up(Double)
        case down(Double)
        case neutral

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return DesignTokens.Colors.success
            case .down: return DesignTokens.Colors.error
            case .neutral: return DesignTokens.Colors.secondary
            }
        }

        var value: String {
            switch self {
            case .up(let percent): return "+\(String(format: "%.1f", percent))%"
            case .down(let percent): return "-\(String(format: "%.1f", percent))%"
            case .neutral: return "0%"
            }
        }
    }

    // MARK: - Initializer

    init(
        title: String,
        value: String,
        icon: String,
        color: Color,
        trend: Trend? = nil,
        size: Size = .medium
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.trend = trend
        self.size = size
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Header - Icon and Trend
            HStack {
                Image(systemName: icon)
                    .font(.system(size: size.iconSize))
                    .foregroundStyle(color)
                    .accessibilityHidden(true) // Icon 被组合在主标签中

                Spacer()

                if let trend {
                    DSTrendBadge(trend: trend)
                        .accessibilityHidden(true) // Trend 被组合在主标签中
                }
            }

            // Value
            Text(value)
                .font(size.valueFont)
                .fontWeight(.bold)
                .foregroundStyle(DesignTokens.Colors.label)
                .accessibilityAddTraits(.isHeader) // Value 是重要信息

            // Title
            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.secondaryLabel)
        }
        .padding(size.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(DesignTokens.CornerRadius.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(buildAccessibilityLabel())
        .accessibilityValue(buildAccessibilityValue())
    }

    // 构建可访问性标签
    private func buildAccessibilityLabel() -> String {
        var label = title
        if let trend {
            label += ", " + trend.value
        }
        return label
    }

    // 构建可访问性值
    private func buildAccessibilityValue() -> String {
        var valueText = value
        if let trend {
            switch trend {
            case .up:
                valueText += ", 上升趋势"
            case .down:
                valueText += ", 下降趋势"
            case .neutral:
                valueText += ", 平稳"
            }
        }
        return valueText
    }
}

// MARK: - Trend Badge

/// 趋势徽章组件 (Design System version)
/// Trend badge component (Design System version)
struct DSTrendBadge: View {
    let trend: DSStatCard.Trend

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trend.icon)
                .font(.caption2)
            Text(trend.value)
                .font(DesignTokens.Typography.caption2)
        }
        .foregroundStyle(trend.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(trend.color.opacity(0.15))
        .cornerRadius(DesignTokens.CornerRadius.xs)
    }
}

// MARK: - Previews
// Note: Previews temporarily removed to avoid conflicts with legacy StatCards.swift
// Will be re-enabled after migration is complete
