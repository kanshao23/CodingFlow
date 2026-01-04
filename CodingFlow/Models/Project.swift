//
//  Project.swift
//  CodingFlow
//
//  面向独立开发者的项目管理模型
//

import Foundation
import SwiftData

// MARK: - Issue Status

enum IssueStatus: String, Codable, CaseIterable, Identifiable {
    case backlog = "backlog"
    case todo = "todo"
    case inProgress = "in_progress"
    case inReview = "in_review"
    case done = "done"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .backlog: return "Backlog"
        case .todo: return "To Do"
        case .inProgress: return "In Progress"
        case .inReview: return "In Review"
        case .done: return "Done"
        }
    }

    var icon: String {
        switch self {
        case .backlog: return "tray"
        case .todo: return "list.bullet"
        case .inProgress: return "play.circle"
        case .inReview: return "eye.circle"
        case .done: return "checkmark.circle"
        }
    }

    var color: String {
        switch self {
        case .backlog: return "gray"
        case .todo: return "blue"
        case .inProgress: return "orange"
        case .inReview: return "purple"
        case .done: return "green"
        }
    }
}

// MARK: - Issue Priority

enum IssuePriority: Int, Codable, CaseIterable, Identifiable, Comparable {
    case urgent = 0
    case high = 1
    case medium = 2
    case low = 3

    static func < (lhs: IssuePriority, rhs: IssuePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .urgent: return "Urgent"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }

    var icon: String {
        switch self {
        case .urgent: return "exclamationmark.triangle.fill"
        case .high: return "arrow.up.circle.fill"
        case .medium: return "minus.circle.fill"
        case .low: return "arrow.down.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .urgent: return "red"
        case .high: return "orange"
        case .medium: return "yellow"
        case .low: return "blue"
        }
    }
}

// MARK: - Issue Type

enum IssueType: String, Codable, CaseIterable, Identifiable {
    case epic = "epic"
    case story = "story"
    case task = "task"
    case bug = "bug"
    case subtask = "subtask"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .epic: return "Epic"
        case .story: return "Story"
        case .task: return "Task"
        case .bug: return "Bug"
        case .subtask: return "Subtask"
        }
    }

    var icon: String {
        switch self {
        case .epic: return "chart.bar.fill"
        case .story: return "book.fill"
        case .task: return "checkmark.circle"
        case .bug: return "ladybug.fill"
        case .subtask: return "circle"
        }
    }
}

// MARK: - AI Tool

enum AITool: String, Codable, CaseIterable, Identifiable {
    case claudeCode = "claude_code"
    case cursor = "cursor"
    case antigravity = "antigravity"
    case codexCLI = "codex_cli"
    case geminiCLI = "gemini_cli"
    case chatGPT = "chatgpt"
    case unknown = "unknown"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claudeCode: return "Claude Code"
        case .cursor: return "Cursor"
        case .antigravity: return "Antigravity"
        case .codexCLI: return "Codex CLI"
        case .geminiCLI: return "Gemini CLI"
        case .chatGPT: return "ChatGPT"
        case .unknown: return "Unknown"
        }
    }

    var icon: String {
        switch self {
        case .claudeCode: return "brain"
        case .cursor: return "cursorarrow"
        case .antigravity: return "sparkles"
        case .codexCLI: return "terminal"
        case .geminiCLI: return "sparkle"
        case .chatGPT: return "bubble.left.and.bubble.right"
        case .unknown: return "questionmark"
        }
    }
}

// MARK: - Project Model

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var name: String
    var projectDescription: String
    var icon: String
    var colorHex: String
    var createdAt: Date
    var updatedAt: Date

    // 关系
    @Relationship(deleteRule: .cascade, inverse: \Issue.project)
    var issues: [Issue]

    @Relationship(deleteRule: .cascade, inverse: \IssueLabel.project)
    var labels: [IssueLabel]

    @Relationship(deleteRule: .nullify, inverse: \Cycle.project)
    var cycles: [Cycle]

    init(
        id: UUID = UUID(),
        name: String,
        projectDescription: String = "",
        icon: String = "folder.fill",
        colorHex: String = "007AFF"
    ) {
        self.id = id
        self.name = name
        self.projectDescription = projectDescription
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = Date()
        self.updatedAt = Date()
        self.issues = []
        self.labels = []
        self.cycles = []
    }
}

// MARK: - IssueLabel Model

@Model
final class IssueLabel {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var icon: String
    var createdAt: Date

    // 关系
    var project: Project?

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "FF9500",
        icon: String = "tag.fill",
        project: Project? = nil
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.createdAt = Date()
        self.project = project
    }
}

// MARK: - Issue Model

@Model
final class Issue {
    @Attribute(.unique) var id: UUID
    var title: String
    var issueDescription: String
    var status: IssueStatus
    var priority: IssuePriority
    var type: IssueType
    var createdAt: Date
    var updatedAt: Date

    // 索引优化 - 为常用查询字段添加索引
    // Index optimization - Add indexes for frequently queried fields
    #Index<Int>([\.issueNumber], name: "IssueNumber")
    #Index<IssueStatus>([\.status], name: "Status")
    #Index<IssuePriority>([\.priority], name: "Priority")
    #Index<Date>([\.createdAt], name: "CreatedAt")
    #Index<Date>([\.updatedAt], name: "UpdatedAt")
    #Index<Bool>([\.isAIGenerated], name: "IsAIGenerated")

    // 时间追踪
    var estimatedHours: Double?
    var actualHours: Double?

    // AI 元数据
    var isAIGenerated: Bool
    var aiToolUsed: String?
    var aiGenerationCount: Int
    var aiContextTokens: Int?

    // 序号 (项目内自增)
    var issueNumber: Int

    // 关系
    var project: Project?
    var cycle: Cycle?

    @Relationship(deleteRule: .cascade, inverse: \Comment.issue)
    var comments: [Comment]

    // 移除与 Label.issues 的循环引用 - 改为单向关系
    var labels: [IssueLabel]?

    // 层级关系
    var parentIssue: Issue?
    @Relationship(deleteRule: .cascade, inverse: \Issue.parentIssue)
    var subtasks: [Issue]?

    init(
        id: UUID = UUID(),
        title: String,
        issueDescription: String = "",
        status: IssueStatus = .backlog,
        priority: IssuePriority = .medium,
        type: IssueType = .task,
        project: Project? = nil,
        issueNumber: Int = 0
    ) {
        self.id = id
        self.title = title
        self.issueDescription = issueDescription
        self.status = status
        self.priority = priority
        self.type = type
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isAIGenerated = false
        self.aiGenerationCount = 0
        self.issueNumber = issueNumber
        self.project = project
        self.comments = []
        self.subtasks = []
    }
}

// MARK: - Comment Model

@Model
final class Comment {
    @Attribute(.unique) var id: UUID
    var content: String
    var createdAt: Date
    var isAIGenerated: Bool

    var issue: Issue?

    init(
        id: UUID = UUID(),
        content: String,
        issue: Issue? = nil,
        isAIGenerated: Bool = false
    ) {
        self.id = id
        self.content = content
        self.createdAt = Date()
        self.isAIGenerated = isAIGenerated
        self.issue = issue
    }
}

// MARK: - Cycle Model (迭代周期)

@Model
final class Cycle {
    @Attribute(.unique) var id: UUID
    var name: String
    var cycleDescription: String
    var startDate: Date
    var endDate: Date
    var createdAt: Date
    var isArchived: Bool

    // 容量规划
    var totalCapacity: Double
    var plannedPoints: Double

    // 关系
    var project: Project?
    @Relationship(inverse: \Issue.cycle)
    var issues: [Issue]?

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        project: Project? = nil,
        cycleDescription: String = ""
    ) {
        self.id = id
        self.name = name
        self.cycleDescription = cycleDescription
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = Date()
        self.isArchived = false
        self.totalCapacity = 40 // 默认每周 40 小时
        self.plannedPoints = 0
        self.project = project
        self.issues = []
    }

    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }

    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
}

// MARK: - AI Tracking Event Model

@Model
final class AITrackingEvent {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var eventType: String // generation, refactor, fix, review
    var aiTool: String
    var promptSummary: String
    var codeFilesChanged: String // JSON array as string
    var tokensUsed: Int

    var issue: Issue?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        eventType: String,
        aiTool: String,
        promptSummary: String = "",
        codeFilesChanged: [String] = [],
        tokensUsed: Int = 0,
        issue: Issue? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.aiTool = aiTool
        self.promptSummary = promptSummary
        // Convert array to JSON string
        if let data = try? JSONEncoder().encode(codeFilesChanged),
           let jsonString = String(data: data, encoding: .utf8) {
            self.codeFilesChanged = jsonString
        } else {
            self.codeFilesChanged = "[]"
        }
        self.tokensUsed = tokensUsed
        self.issue = issue
    }
}

// MARK: - Context Snapshot Model

@Model
final class ContextSnapshot {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var completionPercentage: Double
    var keyFiles: String // JSON array
    var pendingItems: String // JSON array
    var notes: String

    var issue: Issue?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        completionPercentage: Double = 0,
        keyFiles: [String] = [],
        pendingItems: [String] = [],
        notes: String = "",
        issue: Issue? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.completionPercentage = completionPercentage
        // Convert arrays to JSON strings
        if let keyFilesData = try? JSONEncoder().encode(keyFiles),
           let keyFilesString = String(data: keyFilesData, encoding: .utf8) {
            self.keyFiles = keyFilesString
        } else {
            self.keyFiles = "[]"
        }
        if let pendingData = try? JSONEncoder().encode(pendingItems),
           let pendingString = String(data: pendingData, encoding: .utf8) {
            self.pendingItems = pendingString
        } else {
            self.pendingItems = "[]"
        }
        self.notes = notes
        self.issue = issue
    }
}
