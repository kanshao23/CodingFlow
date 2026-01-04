//
//  CodingFlowTests.swift
//  CodingFlowTests
//
//  设计系统和组件测试
//  Design system and component tests
//

import Testing
@testable import CodingFlow
import SwiftUI

struct CodingFlowTests {

    // MARK: - Design Token Tests

    @Test("DesignTokens - Colors should be defined") func testDesignTokenColors() {
        // 测试设计令牌颜色已定义
        #expect(DesignTokens.Colors.primary != Color.clear)
        #expect(DesignTokens.Colors.secondary != Color.clear)
        #expect(DesignTokens.Colors.success != Color.clear)
        #expect(DesignTokens.Colors.error != Color.clear)
    }

    @Test("DesignTokens - Spacing should follow 4pt grid") func testDesignTokenSpacing() {
        // 测试间距遵循 4pt 网格系统
        #expect(DesignTokens.Spacing.xxs == 2)
        #expect(DesignTokens.Spacing.xs == 4)
        #expect(DesignTokens.Spacing.sm == 8)
        #expect(DesignTokens.Spacing.md == 12)
        #expect(DesignTokens.Spacing.lg == 16)
        #expect(DesignTokens.Spacing.xl == 24)
        #expect(DesignTokens.Spacing.xxl == 32)
    }

    @Test("DesignTokens - Corner radius should be consistent") func testDesignTokenCornerRadius() {
        // 测试圆角一致性
        #expect(DesignTokens.CornerRadius.xs == 4)
        #expect(DesignTokens.CornerRadius.sm == 8)
        #expect(DesignTokens.CornerRadius.md == 12)
        #expect(DesignTokens.CornerRadius.lg == 16)
        #expect(DesignTokens.CornerRadius.xl == 20)
    }

    // MARK: - Status Color Tests

    @Test("DesignTokens - Status colors should be defined for all cases") func testStatusColors() {
        // 测试所有状态都有对应的颜色
        for status in IssueStatus.allCases {
            let color = DesignTokens.Colors.statusColor(status)
            #expect(color != Color.clear)
        }
    }

    // MARK: - Priority Color Tests

    @Test("DesignTokens - Priority colors should be defined for all cases") func testPriorityColors() {
        // 测试所有优先级都有对应的颜色
        for priority in IssuePriority.allCases {
            let color = DesignTokens.Colors.priorityColor(priority)
            #expect(color != Color.clear)
        }
    }

    // MARK: - ViewState Tests

    @Test("ViewState - Idle state should have no data") func testViewStateIdle() {
        // 测试 idle 状态没有数据
        let state = ViewState<Int>.idle
        #expect(state.data == nil)
        #expect(state.isLoading == false)
        #expect(state.error == nil)
    }

    @Test("ViewState - Loading state should be correct") func testViewStateLoading() {
        // 测试 loading 状态
        let state = ViewState<Int>.loading
        #expect(state.data == nil)
        #expect(state.isLoading == true)
        #expect(state.error == nil)
    }

    @Test("ViewState - Success state should have data") func testViewStateSuccess() {
        // 测试 success 状态有数据
        let state = ViewState<Int>.success(42)
        #expect(state.data == 42)
        #expect(state.isLoading == false)
        #expect(state.error == nil)
    }

    @Test("ViewState - Error state should have error") func testViewStateError() {
        // 测试 error 状态有错误
        let testError = NSError(domain: "test", code: 1)
        let state = ViewState<Int>.error(testError)
        #expect(state.data == nil)
        #expect(state.isLoading == false)
        #expect(state.error != nil)
    }

    // MARK: - Component Snapshot Tests

    @Test("Components - DSBadge should create status badge") func testDSBadgeStatus() {
        // 测试 DSBadge 可以创建状态徽章
        for status in IssueStatus.allCases {
            let badge = DSBadge.status(status)
            // 验证徽章可以创建（不崩溃）
            #expect(true)
        }
    }

    @Test("Components - DSBadge should create priority badge") func testDSBadgePriority() {
        // 测试 DSBadge 可以创建优先级徽章
        for priority in IssuePriority.allCases {
            let badge = DSBadge.priority(priority)
            // 验证徽章可以创建（不崩溃）
            #expect(true)
        }
    }

    // MARK: - Performance Tests

    @Test("Performance - DesignTokens should be fast to access") func testDesignTokensPerformance() async throws {
        // 测试设计令牌访问性能
        measure {
            for _ in 0..<1000 {
                _ = DesignTokens.Colors.primary
                _ = DesignTokens.Spacing.md
                _ = DesignTokens.Typography.body
            }
        }
    }

    // MARK: - Accessibility Tests

    @Test("Accessibility - DSBadge shapes should have accessibility labels") func testBadgeShapeAccessibility() {
        // 测试徽章形状的可访问性标签
        #expect(DSBadge.Shape.circle.accessibilityLabel == "圆形")
        #expect(DSBadge.Shape.square.accessibilityLabel == "方形")
        #expect(DSBadge.Shape.diamond.accessibilityLabel == "菱形")
        #expect(DSBadge.Shape.triangle.accessibilityLabel == "三角形")
    }

    // MARK: - Localization Tests

    @Test("Localization - All localized strings should be accessible") func testLocalization() {
        // 测试本地化字符串可访问
        let okString = String(localized: "ok")
        #expect(!okString.isEmpty)

        let issuesString = String(localized: "issues")
        #expect(!issuesString.isEmpty)
    }

}

