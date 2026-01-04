//
//  LoadingView.swift
//  CodingFlow
//
//  加载状态视图组件 - 包括加载指示器和骨架屏
//  Loading state view component - includes loading indicator and skeleton screens
//

import SwiftUI

// MARK: - Loading View

/// 加载视图组件 - 显示加载指示器和可选消息 (Design System version)
/// Loading view component - displays loading indicator with optional message (Design System version)
struct DSLoadingView: View {
    let message: String

    init(message: String = "加载中...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)

            Text(message)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.secondaryLabel)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

// MARK: - Skeleton Screen Components

/// 骨架行组件 - 用于列表加载状态 (Design System version)
/// Skeleton row component - for list loading states (Design System version)
struct DSSkeletonRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // 标题骨架 (Title skeleton)
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 20)
                .cornerRadius(DesignTokens.CornerRadius.xs)

            // 副标题骨架 (Subtitle skeleton)
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 16)
                .frame(maxWidth: 200)
                .cornerRadius(DesignTokens.CornerRadius.xs)
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.secondaryBackground)
        .cornerRadius(DesignTokens.CornerRadius.md)
        .redacted(reason: .placeholder)
        .shimmer()
    }
}

/// 骨架卡片组件 - 用于卡片加载状态 (Design System version)
/// Skeleton card component - for card loading states (Design System version)
struct DSSkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)

                Spacer()

                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 20)
                    .cornerRadius(DesignTokens.CornerRadius.xs)
            }

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 32)
                .cornerRadius(DesignTokens.CornerRadius.xs)

            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 16)
                .frame(maxWidth: 100)
                .cornerRadius(DesignTokens.CornerRadius.xs)
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.background)
        .cornerRadius(DesignTokens.CornerRadius.md)
        .shadow(
            color: DesignTokens.Shadow.medium.color,
            radius: DesignTokens.Shadow.medium.radius,
            x: DesignTokens.Shadow.medium.x,
            y: DesignTokens.Shadow.medium.y
        )
        .redacted(reason: .placeholder)
        .shimmer()
    }
}

// MARK: - Shimmer Effect

/// 闪烁效果修饰器 - 为骨架屏添加加载动画 (Design System version)
/// Shimmer effect modifier - adds loading animation to skeleton screens (Design System version)
struct DSShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(70))
                    .offset(x: phase)
                    .onAppear {
                        withAnimation(
                            .linear(duration: 1.5)
                            .repeatForever(autoreverses: false)
                        ) {
                            phase = 300
                        }
                    }
            )
            .clipped()
    }
}

extension View {
    /// 添加闪烁效果 (Add shimmer effect)
    func shimmer() -> some View {
        modifier(DSShimmerModifier())
    }
}

// MARK: - Previews

#Preview("Loading View") {
    VStack(spacing: 32) {
        DSLoadingView(message: "加载中...")
        DSLoadingView(message: "加载任务...")
        DSLoadingView(message: "正在同步...")
    }
    .padding()
}

#Preview("Skeleton Row") {
    VStack(spacing: 12) {
        DSSkeletonRow()
        DSSkeletonRow()
        DSSkeletonRow()
    }
    .padding()
    .background(DesignTokens.Colors.groupedBackground)
}

#Preview("Skeleton Card") {
    ScrollView {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 16
        ) {
            ForEach(0..<4, id: \.self) { _ in
                DSSkeletonCard()
            }
        }
        .padding()
    }
}
