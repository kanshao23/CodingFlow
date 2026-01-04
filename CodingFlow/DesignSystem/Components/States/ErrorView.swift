//
//  ErrorView.swift
//  CodingFlow
//
//  错误状态视图组件
//  Error state view component
//

import SwiftUI

/// 错误视图组件 - 显示错误信息和重试按钮 (Design System version)
/// Error view component - displays error message and retry button (Design System version)
struct DSErrorView: View {
    let title: String
    let message: String
    let icon: String
    let retryAction: (() -> Void)?

    /// 使用自定义标题和消息初始化
    /// Initialize with custom title and message
    init(
        title: String = "出错了",
        message: String,
        icon: String = "exclamationmark.triangle.fill",
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.retryAction = retryAction
    }

    /// 使用 Error 对象初始化
    /// Initialize with Error object
    init(error: Error, retryAction: (() -> Void)? = nil) {
        self.title = "出错了"
        self.message = error.localizedDescription
        self.icon = "exclamationmark.triangle.fill"
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // 错误图标 (Error icon)
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(DesignTokens.Colors.error)

            // 错误标题和消息 (Error title and message)
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(DesignTokens.Typography.headline)
                    .foregroundStyle(DesignTokens.Colors.label)

                Text(message)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }

            // 重试按钮 (Retry button)
            if let retryAction {
                Button {
                    retryAction()
                } label: {
                    Label("重试", systemImage: "arrow.clockwise")
                        .font(DesignTokens.Typography.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
        .accessibilityHint(retryAction != nil ? "双击重试" : "")
    }
}

// MARK: - Preview

#Preview("Error with retry") {
    DSErrorView(
        title: "加载失败",
        message: "无法加载任务列表，请检查网络连接后重试。"
    ) {
        print("Retry tapped")
    }
}

#Preview("Error from Error object") {
    DSErrorView(
        error: NSError(
            domain: "test",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "未找到数据"]
        )
    ) {
        print("Retry")
    }
}

#Preview("Error without retry") {
    DSErrorView(
        title: "权限不足",
        message: "您没有权限访问此内容"
    )
}
