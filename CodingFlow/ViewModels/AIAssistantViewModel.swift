//
//  AIAssistantViewModel.swift
//  CodingFlow
//
//  AI 助手视图模型
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class AIAssistantViewModel {
    private let modelContext: ModelContext

    // AI 开发追踪
    var aiEvents: [AITrackingEvent] = []
    var contextSnapshots: [ContextSnapshot] = []

    // 统计
    var todayAIInteractions: Int = 0
    var totalTokensUsed: Int = 0
    var mostUsedTool: AITool = .unknown
    var aiGenerationRate: Double = 0

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadAIStats()
    }

    // MARK: - AI Event Tracking

    func trackAIEvent(
        eventType: String,
        aiTool: AITool,
        promptSummary: String = "",
        codeFilesChanged: [String] = [],
        tokensUsed: Int = 0,
        issue: Issue? = nil
    ) -> AITrackingEvent {
        let event = AITrackingEvent(
            eventType: eventType,
            aiTool: aiTool.rawValue,
            promptSummary: promptSummary,
            codeFilesChanged: codeFilesChanged,
            tokensUsed: tokensUsed,
            issue: issue
        )

        // 更新关联问题的 AI 元数据
        if let issue = issue {
            issue.isAIGenerated = true
            issue.aiToolUsed = aiTool.rawValue
            issue.aiGenerationCount += 1
            if let tokens = issue.aiContextTokens {
                issue.aiContextTokens = tokens + tokensUsed
            } else {
                issue.aiContextTokens = tokensUsed
            }
            issue.updatedAt = Date()
        }

        modelContext.insert(event)
        try? modelContext.save()

        loadAIStats()
        return event
    }

    // MARK: - Context Snapshot

    func saveContextSnapshot(
        for issue: Issue,
        completionPercentage: Double,
        keyFiles: [String] = [],
        pendingItems: [String] = [],
        notes: String = ""
    ) -> ContextSnapshot {
        let snapshot = ContextSnapshot(
            completionPercentage: completionPercentage,
            keyFiles: keyFiles,
            pendingItems: pendingItems,
            notes: notes,
            issue: issue
        )

        modelContext.insert(snapshot)
        try? modelContext.save()

        contextSnapshots.append(snapshot)
        return snapshot
    }

    func loadContextSnapshots(for issue: Issue) -> [ContextSnapshot] {
        let descriptor = FetchDescriptor<ContextSnapshot>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            let snapshots = try modelContext.fetch(descriptor)
            return snapshots.filter { $0.issue?.id == issue.id }
        } catch {
            return []
        }
    }

    // MARK: - AI Statistics

    func loadAIStats() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        // 获取今日 AI 事件
        let todayDescriptor = FetchDescriptor<AITrackingEvent>(
            predicate: #Predicate { $0.timestamp >= startOfDay }
        )

        do {
            let todayEvents = try modelContext.fetch(todayDescriptor)
            todayAIInteractions = todayEvents.count
            totalTokensUsed = todayEvents.reduce(0) { $0 + $1.tokensUsed }

            // 统计工具使用频率
            let toolCounts = Dictionary(grouping: todayEvents, by: { $0.aiTool })
                .mapValues { $0.count }
            if let (mostUsed, _) = toolCounts.max(by: { $0.value < $1.value }) {
                mostUsedTool = AITool(rawValue: mostUsed) ?? .unknown
            }

            // 获取所有问题计算 AI 生成率
            let allIssuesDescriptor = FetchDescriptor<Issue>()
            let allIssues = try modelContext.fetch(allIssuesDescriptor)
            let aiIssues = allIssues.filter { $0.isAIGenerated }
            aiGenerationRate = allIssues.isEmpty ? 0 : Double(aiIssues.count) / Double(allIssues.count) * 100
        } catch {
            print("Failed to load AI stats: \(error)")
        }
    }

    // MARK: - AI Events

    func fetchAIEvents(for issue: Issue? = nil, limit: Int = 50) -> [AITrackingEvent] {
        let descriptor = FetchDescriptor<AITrackingEvent>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            let events = try modelContext.fetch(descriptor)
            if let issue = issue {
                return events.filter { $0.issue?.id == issue.id }.prefix(limit).map { $0 }
            }
            return Array(events.prefix(limit))
        } catch {
            return []
        }
    }

    // MARK: - Natural Language Issue Creation

    func createIssueFromNaturalLanguage(
        _ text: String,
        project: Project? = nil
    ) -> Issue {
        // 简单的自然语言解析
        let lowercased = text.lowercased()

        // 检测优先级
        var priority: IssuePriority = .medium
        if lowercased.contains("urgent") || lowercased.contains("asap") || lowercased.contains("重要") {
            priority = .urgent
        } else if lowercased.contains("high") || lowercased.contains("重要") || lowercased.contains("紧急") {
            priority = .high
        } else if lowercased.contains("low") || lowercased.contains("低") {
            priority = .low
        }

        // 检测类型
        var type: IssueType = .task
        if lowercased.contains("bug") || lowercased.contains("错误") || lowercased.contains("修复") {
            type = .bug
        } else if lowercased.contains("feature") || lowercased.contains("功能") || lowercased.contains("feature") {
            type = .story
        } else if lowercased.contains("epic") || lowercased.contains("史诗") {
            type = .epic
        }

        // 创建问题
        let issue = Issue(
            title: text.trimmingCharacters(in: .whitespacesAndNewlines),
            issueDescription: "Created via AI Assistant",
            status: .backlog,
            priority: priority,
            type: type,
            project: project
        )

        modelContext.insert(issue)
        try? modelContext.save()

        // 记录 AI 事件
        trackAIEvent(
            eventType: "issue_creation",
            aiTool: .claudeCode,
            promptSummary: text,
            issue: issue
        )

        return issue
    }
}
