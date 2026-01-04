//
//  Badge.swift
//  CodingFlow
//
//  标准化徽章组件 - 包含形状指示器支持色盲用户
//  Standardized badge component - includes shape indicators for colorblind users
//

import SwiftUI

/// 徽章组件 - 支持文本、图标和形状指示器 (Design System version)
/// Badge component - supports text, icon, and shape indicators (Design System version)
struct DSBadge: View {
    let text: String
    let color: Color
    let icon: String?
    let shape: Shape

    // MARK: - Shape Enum

    enum Shape {
        case circle, square, diamond, triangle

        var accessibilityLabel: String {
            switch self {
            case .circle: return "圆形"
            case .square: return "方形"
            case .diamond: return "菱形"
            case .triangle: return "三角形"
            }
        }
    }

    // MARK: - Initializers

    init(
        text: String,
        color: Color,
        icon: String? = nil,
        shape: Shape = .circle
    ) {
        self.text = text
        self.color = color
        self.icon = icon
        self.shape = shape
    }

    // MARK: - Convenience Initializers for Status

    /// 状态徽章便捷初始化器
    /// Convenience initializer for status badge
    static func status(_ status: IssueStatus) -> DSBadge {
        let shape: Shape = switch status {
        case .backlog: .circle
        case .todo: .square
        case .inProgress: .triangle
        case .inReview: .diamond
        case .done: .circle
        }

        return DSBadge(
            text: status.displayName,
            color: DesignTokens.Colors.statusColor(status),
            icon: status.icon,
            shape: shape
        )
    }

    /// 优先级徽章便捷初始化器
    /// Convenience initializer for priority badge
    static func priority(_ priority: IssuePriority) -> DSBadge {
        let shape: Shape = switch priority {
        case .urgent: .triangle
        case .high: .diamond
        case .medium: .square
        case .low: .circle
        }

        return DSBadge(
            text: priority.displayName,
            color: DesignTokens.Colors.priorityColor(priority),
            icon: priority.icon,
            shape: shape
        )
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            // Icon (optional)
            if let icon {
                Image(systemName: icon)
                    .font(.caption2)
                    .accessibilityHidden(true) // Icon 被组合在主标签中
            }

            // Shape indicator (for colorblind support)
            DSShapeIndicator(shape: shape)
                .frame(width: 8, height: 8)
                .foregroundStyle(color)
                .accessibilityHidden(true) // 形状被组合在主标签中

            // Text
            Text(text)
                .font(DesignTokens.Typography.caption)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .cornerRadius(DesignTokens.CornerRadius.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text), \(shape.accessibilityLabel)")
        .accessibilityAddTraits(.isButton) // 如果可交互，添加按钮特征
    }
}

// MARK: - Shape Indicator

/// 形状指示器 - 为色盲用户提供额外的视觉提示
/// Shape indicator - provides additional visual cues for colorblind users
struct DSShapeIndicator: View {
    let shape: DSBadge.Shape

    var body: some View {
        switch shape {
        case .circle:
            Circle()
                .fill(Color.primary)
        case .square:
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.primary)
        case .diamond:
            Diamond()
                .fill(Color.primary)
        case .triangle:
            Triangle()
                .fill(Color.primary)
        }
    }
}

// MARK: - Custom Shapes

/// 菱形形状
/// Diamond shape
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: width, y: height / 2))
        path.addLine(to: CGPoint(x: width / 2, y: height))
        path.addLine(to: CGPoint(x: 0, y: height / 2))
        path.closeSubpath()

        return path
    }
}

/// 三角形形状
/// Triangle shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Previews

#Preview("DSBadge Shapes") {
    VStack(spacing: 16) {
        Text("Shapes for Colorblind Support")
            .font(.headline)

        DSBadge(text: "Circle", color: .blue, shape: .circle)
        DSBadge(text: "Square", color: .green, shape: .square)
        DSBadge(text: "Diamond", color: .purple, shape: .diamond)
        DSBadge(text: "Triangle", color: .red, shape: .triangle)
    }
    .padding()
}

#Preview("Status Badges") {
    VStack(spacing: 12) {
        Text("Status Badges")
            .font(.headline)

        ForEach(IssueStatus.allCases) { status in
            DSBadge.status(status)
        }
    }
    .padding()
}

#Preview("Priority Badges") {
    VStack(spacing: 12) {
        Text("Priority Badges")
            .font(.headline)

        ForEach(IssuePriority.allCases) { priority in
            DSBadge.priority(priority)
        }
    }
    .padding()
}

#Preview("Badges with Icons") {
    VStack(spacing: 12) {
        DSBadge(
            text: "待办",
            color: .blue,
            icon: "circle",
            shape: .square
        )

        DSBadge(
            text: "进行中",
            color: .orange,
            icon: "arrow.clockwise",
            shape: .triangle
        )

        DSBadge(
            text: "已完成",
            color: .green,
            icon: "checkmark.circle.fill",
            shape: .circle
        )

        DSBadge(
            text: "紧急",
            color: .red,
            icon: "exclamationmark.triangle.fill",
            shape: .triangle
        )
    }
    .padding()
}

#Preview("Badge Grid") {
    LazyVGrid(
        columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ],
        spacing: 12
    ) {
        DSBadge(text: "新功能", color: .blue)
        DSBadge(text: "Bug", color: .red)
        DSBadge(text: "文档", color: .green)
        DSBadge(text: "优化", color: .purple)
        DSBadge(text: "测试", color: .orange)
        DSBadge(text: "设计", color: .pink)
    }
    .padding()
}
