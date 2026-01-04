//
//  IssueComponents.swift
//  CodingFlow
//
//  任务相关 UI 组件
//

import SwiftUI

// MARK: - Issue Card

struct IssueCard: View {
    let issue: Issue
    let onStatusChange: ((IssueStatus) -> Void)?
    let onTap: (() -> Void)?

    init(issue: Issue, onStatusChange: ((IssueStatus) -> Void)? = nil, onTap: (() -> Void)? = nil) {
        self.issue = issue
        self.onStatusChange = onStatusChange
        self.onTap = onTap
    }

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 6) {
                // 顶部：类型图标 + 编号 + 项目
                HStack(spacing: 6) {
                    IssueTypeIcon(type: issue.type)

                    Text("#\(issue.issueNumber)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    // 项目标签
                    if let project = issue.project {
                        HStack(spacing: 3) {
                            Image(systemName: project.icon)
                                .font(.system(size: 9))
                            Text(project.name)
                                .font(.system(size: 10))
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(Color(hex: project.colorHex))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: project.colorHex).opacity(0.15))
                        .clipShape(Capsule())
                    }
                }

                // 标题
                Text(issue.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // 底部：优先级 + AI + 标签
                HStack(spacing: 6) {
                    PriorityBadge(priority: issue.priority)

                    if issue.isAIGenerated {
                        HStack(spacing: 2) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 9))
                            Text("AI")
                                .font(.system(size: 10))
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.cyan)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.cyan.opacity(0.15))
                        .clipShape(Capsule())
                    }

                    if let labels = issue.labels, !labels.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 9))
                            Text("\(labels.count)")
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            ForEach(IssueStatus.allCases) { status in
                Button {
                    onStatusChange?(status)
                } label: {
                    Label(status.displayName, systemImage: status.icon)
                }
            }
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: IssueStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption)
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .backlog: return .gray
        case .todo: return .blue
        case .inProgress: return .orange
        case .inReview: return .purple
        case .done: return .green
        }
    }
}

// MARK: - Priority Badge

struct PriorityBadge: View {
    let priority: IssuePriority

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: priority.icon)
                .font(.caption2)
            Text(priority.displayName)
                .font(.caption2)
        }
        .foregroundStyle(priorityColor)
    }

    private var priorityColor: Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

// MARK: - Issue Type Icon

struct IssueTypeIcon: View {
    let type: IssueType

    var body: some View {
        Image(systemName: type.icon)
            .font(.caption2)
            .foregroundStyle(typeColor)
            .frame(width: 18, height: 18)
    }

    private var typeColor: Color {
        switch type {
        case .epic: return .purple
        case .story: return .blue
        case .task: return .green
        case .bug: return .red
        case .subtask: return .gray
        }
    }
}

// MARK: - Label Tag

struct LabelTag: View {
    let label: IssueLabel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: label.icon)
                .font(.caption2)
            Text(label.name)
                .font(.caption2)
        }
        .foregroundStyle(Color(hex: label.colorHex))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color(hex: label.colorHex).opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - AI Badge

struct AIBadge: View {
    let tool: String?

    var body: some View {
        if let tool = tool {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                Text(tool.replacingOccurrences(of: "_", with: " ").capitalized)
            }
            .font(.caption2)
            .foregroundStyle(.cyan)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.cyan.opacity(0.15))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview("Issue Card") {
    VStack {
        IssueCard(
            issue: Issue(
                title: "Implement user authentication",
                issueDescription: "Add OAuth2 support",
                status: .inProgress,
                priority: .high,
                type: .story
            )
        )

        IssueCard(
            issue: Issue(
                title: "Fix login bug on iOS 17",
                issueDescription: "Crash when tapping login",
                status: .todo,
                priority: .urgent,
                type: .bug
            )
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
