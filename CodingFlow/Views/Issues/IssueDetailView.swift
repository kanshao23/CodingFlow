//
//  IssueDetailView.swift
//  CodingFlow
//
//  任务详情视图 - 完全可编辑
//

import SwiftUI
import SwiftData

struct IssueDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var issue: Issue

    @Query(sort: \Project.updatedAt, order: .reverse) private var allProjects: [Project]

    @State private var showingDeleteAlert = false
    @State private var showingSubtaskSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 头部 - 编号
                    HStack {
                        Text("#\(issue.issueNumber)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if issue.isAIGenerated {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.caption2)
                                Text("AI")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.cyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.cyan.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)

                    // 标题 - 可编辑
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Issue title", text: $issue.title, axis: .vertical)
                            .font(.title2)
                            .fontWeight(.bold)
                            .lineLimit(2...4)
                    }
                    .padding(.horizontal)

                    // 类型选择
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            ForEach(IssueType.allCases.filter { $0 != .subtask }, id: \.self) { type in
                                TypeButton(type: type, isSelected: issue.type == type) {
                                    issue.type = type
                                    issue.updatedAt = Date()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.vertical, 8)

                    // 描述 - 可编辑
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "text.alignleft")
                                .foregroundStyle(.secondary)
                            Text("Description")
                                .font(.headline)
                        }

                        TextEditor(text: $issue.issueDescription)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.vertical, 8)

                    // 属性设置
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Properties")
                            .font(.headline)
                            .padding(.horizontal)

                        // 状态和优先级
                        HStack(spacing: 12) {
                            StatusPickerView(status: $issue.status)
                            PriorityPickerView(priority: $issue.priority)
                        }
                        .padding(.horizontal)

                        // 项目选择
                        ProjectPickerView(issue: issue, allProjects: allProjects)
                            .padding(.horizontal)

                        // 预估时间
                        EstimatedHoursView(estimatedHours: $issue.estimatedHours)
                            .padding(.horizontal)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // 子任务
                    if let subtasks = issue.subtasks, !subtasks.isEmpty {
                        subtasksSection(subtasks)
                        Divider()
                    }

                    // 添加子任务按钮
                    Button {
                        showingSubtaskSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Subtask")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)

                    // AI 元数据（只读显示）
                    if issue.isAIGenerated {
                        aiMetadataSection
                        Divider()
                    }

                    // 活动历史（只读显示）
                    activitySection
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .sheet(isPresented: $showingSubtaskSheet) {
                CreateSubtaskSheet(parentIssue: issue)
            }
            .alert("Delete Issue?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    modelContext.delete(issue)
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .onChange(of: issue.title) { _, _ in
                issue.updatedAt = Date()
            }
            .onChange(of: issue.issueDescription) { _, _ in
                issue.updatedAt = Date()
            }
        }
    }

    // MARK: - Subtasks Section

    private func subtasksSection(_ subtasks: [Issue]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(.secondary)
                Text("Subtasks")
                    .font(.headline)

                Spacer()

                let completedCount = subtasks.filter { $0.status == .done }.count
                Text("\(completedCount)/\(subtasks.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            ForEach(subtasks) { subtask in
                SubtaskRow(subtask: subtask)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - AI Metadata Section

    private var aiMetadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.cyan)
                Text("AI Development")
                    .font(.headline)
            }
            .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetadataItem(
                    title: "Tool Used",
                    value: issue.aiToolUsed?.replacingOccurrences(of: "_", with: " ").capitalized ?? "Unknown",
                    icon: "cpu"
                )

                MetadataItem(
                    title: "AI Revisions",
                    value: "\(issue.aiGenerationCount)",
                    icon: "arrow.triangle.2.circlepath"
                )

                if let tokens = issue.aiContextTokens {
                    MetadataItem(
                        title: "Context Tokens",
                        value: formatNumber(tokens),
                        icon: "text.alignleft"
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Activity Section

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text("Activity")
                    .font(.headline)
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                ActivityRow(
                    icon: "plus.circle.fill",
                    color: .green,
                    title: "Issue created",
                    time: issue.createdAt.formatted(date: .abbreviated, time: .shortened)
                )

                if issue.updatedAt != issue.createdAt {
                    ActivityRow(
                        icon: "pencil.circle.fill",
                        color: .blue,
                        title: "Last updated",
                        time: issue.updatedAt.formatted(date: .abbreviated, time: .shortened)
                    )
                }

                if !issue.comments.isEmpty {
                    ActivityRow(
                        icon: "bubble.left.fill",
                        color: .purple,
                        title: "\(issue.comments.count) comments",
                        time: ""
                    )
                }
            }
            .padding(.horizontal)
        }
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

// MARK: - Type Button

struct TypeButton: View {
    let type: IssueType
    let isSelected: Bool
    let action: () -> Void

    private var color: Color {
        switch type {
        case .epic: return .purple
        case .story: return .blue
        case .task: return .green
        case .bug: return .red
        case .subtask: return .gray
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.caption)
                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Picker View

struct StatusPickerView: View {
    @Binding var status: IssueStatus

    private var color: Color {
        switch status {
        case .backlog: return .gray
        case .todo: return .blue
        case .inProgress: return .orange
        case .inReview: return .purple
        case .done: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.caption)
                .foregroundStyle(.secondary)

            Menu {
                ForEach(IssueStatus.allCases, id: \.self) { s in
                    Button {
                        status = s
                    } label: {
                        HStack {
                            Image(systemName: s.icon)
                            Text(s.displayName)
                            Spacer()
                            if s == status {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: status.icon)
                        .foregroundStyle(color)
                    Text(status.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

// MARK: - Priority Picker View

struct PriorityPickerView: View {
    @Binding var priority: IssuePriority

    private var color: Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Priority")
                .font(.caption)
                .foregroundStyle(.secondary)

            Menu {
                ForEach(IssuePriority.allCases, id: \.self) { p in
                    Button {
                        priority = p
                    } label: {
                        HStack {
                            Image(systemName: p.icon)
                            Text(p.displayName)
                            Spacer()
                            if p == priority {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: priority.icon)
                        .foregroundStyle(color)
                    Text(priority.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

// MARK: - Project Picker View

struct ProjectPickerView: View {
    let issue: Issue
    let allProjects: [Project]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Project")
                .font(.caption)
                .foregroundStyle(.secondary)

            Menu {
                Button {
                    issue.project = nil
                    issue.updatedAt = Date()
                } label: {
                    HStack {
                        Image(systemName: "folder")
                        Text("No Project")
                        Spacer()
                        if issue.project == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Divider()

                ForEach(allProjects) { project in
                    Button {
                        issue.project = project
                        issue.updatedAt = Date()
                    } label: {
                        HStack {
                            Image(systemName: project.icon)
                                .foregroundStyle(Color(hex: project.colorHex))
                            Text(project.name)
                            Spacer()
                            if issue.project?.id == project.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    if let project = issue.project {
                        Image(systemName: project.icon)
                            .foregroundStyle(Color(hex: project.colorHex))
                        Text(project.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    } else {
                        Image(systemName: "folder")
                            .foregroundStyle(.secondary)
                        Text("No Project")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

// MARK: - Estimated Hours View

struct EstimatedHoursView: View {
    @Binding var estimatedHours: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Estimated Time")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Text(estimatedHours.map { "\($0)h" } ?? "Not set")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Stepper("", value: Binding(
                    get: { estimatedHours ?? 0 },
                    set: { estimatedHours = $0 == 0 ? nil : $0 }
                ), in: 0...100, step: 0.5)
                .labelsHidden()
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Metadata Item

struct MetadataItem: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .font(.caption)
            VStack(alignment: .leading) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Subtask Row

struct SubtaskRow: View {
    @Bindable var subtask: Issue

    var body: some View {
        HStack {
            Button {
                if subtask.status == .done {
                    subtask.status = .todo
                } else {
                    subtask.status = .done
                }
                subtask.updatedAt = Date()
            } label: {
                Image(systemName: subtask.status == .done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(subtask.status == .done ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Text(subtask.title)
                .strikethrough(subtask.status == .done)
                .foregroundStyle(subtask.status == .done ? .secondary : .primary)
                .lineLimit(1)

            Spacer()

            if subtask.isAIGenerated {
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(.cyan)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let icon: String
    let color: Color
    let title: String
    let time: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
            Spacer()
            Text(time)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}

// MARK: - Create Subtask Sheet

struct CreateSubtaskSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let parentIssue: Issue

    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Subtask") {
                    TextField("Subtask title", text: $title)
                }
            }
            .navigationTitle("Add Subtask")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let subtask = Issue(
                            title: title,
                            issueDescription: "",
                            status: .todo,
                            priority: parentIssue.priority,
                            type: .subtask,
                            issueNumber: 0
                        )
                        subtask.parentIssue = parentIssue

                        modelContext.insert(subtask)
                        try? modelContext.save()

                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    IssueDetailView(
        issue: Issue(
            title: "Implement user authentication",
            issueDescription: "Add OAuth2 support with Apple, Google, and Email providers",
            status: .inProgress,
            priority: .high,
            type: .story
        )
    )
    .modelContainer(for: [Issue.self, Project.self], inMemory: true)
}
