//
//  Tokens.swift
//  CodingFlow
//
//  设计系统令牌 - 定义统一的颜色、间距、排版和圆角
//  Design System Tokens - Defines unified colors, spacing, typography and corner radius
//

import SwiftUI

enum DesignTokens {
    // MARK: - Colors

    enum Colors {
        // 主要颜色 (Primary Colors)
        static let primary = Color.blue
        static let secondary = Color.gray
        static let accent = Color.cyan

        // 语义颜色 (Semantic Colors)
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue

        // 状态颜色 (Status Colors) - 映射到 IssueStatus
        static func statusColor(_ status: IssueStatus) -> Color {
            switch status {
            case .backlog: return .gray
            case .todo: return .blue
            case .inProgress: return .orange
            case .inReview: return .purple
            case .done: return .green
            }
        }

        // 优先级颜色 (Priority Colors) - 映射到 IssuePriority
        static func priorityColor(_ priority: IssuePriority) -> Color {
            switch priority {
            case .urgent: return .red
            case .high: return .orange
            case .medium: return .yellow
            case .low: return .blue
            }
        }

        // 背景颜色 (Background Colors)
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        static let groupedBackground = Color(.systemGroupedBackground)

        // 文本颜色 (Text Colors)
        static let label = Color(.label)
        static let secondaryLabel = Color(.secondaryLabel)
        static let tertiaryLabel = Color(.tertiaryLabel)

        // AI 特殊颜色
        static let aiAccent = Color.cyan
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle = Font.largeTitle
        static let title = Font.title
        static let title2 = Font.title2
        static let title3 = Font.title3
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }

    // MARK: - Shadow

    enum Shadow {
        static let small = (
            color: Color.black.opacity(0.05),
            radius: CGFloat(2),
            x: CGFloat(0),
            y: CGFloat(1)
        )

        static let medium = (
            color: Color.black.opacity(0.1),
            radius: CGFloat(4),
            x: CGFloat(0),
            y: CGFloat(2)
        )

        static let large = (
            color: Color.black.opacity(0.15),
            radius: CGFloat(8),
            x: CGFloat(0),
            y: CGFloat(4)
        )
    }
}

// MARK: - Convenience Extensions

extension View {
    /// 应用标准卡片样式 (Apply standard card style)
    func cardStyle() -> some View {
        self
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.background)
            .cornerRadius(DesignTokens.CornerRadius.md)
            .shadow(
                color: DesignTokens.Shadow.medium.color,
                radius: DesignTokens.Shadow.medium.radius,
                x: DesignTokens.Shadow.medium.x,
                y: DesignTokens.Shadow.medium.y
            )
    }

    /// 应用徽章样式 (Apply badge style)
    func badgeStyle(color: Color) -> some View {
        self
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .cornerRadius(DesignTokens.CornerRadius.sm)
    }
}
