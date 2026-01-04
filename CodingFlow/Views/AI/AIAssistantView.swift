//
//  AIAssistantView.swift
//  CodingFlow
//
//  AI 助手视图
//

import SwiftUI
import SwiftData

struct AIAssistantView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: AIAssistantViewModel?

    @State private var showingNaturalLanguageSheet = false
    @State private var naturalLanguageInput = ""
    @State private var selectedIssue: Issue?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // AI 统计卡片
                    if let vm = viewModel {
                        AIStatsCard(
                            todayInteractions: vm.todayAIInteractions,
                            totalTokens: vm.totalTokensUsed,
                            aiGenerationRate: vm.aiGenerationRate,
                            mostUsedTool: vm.mostUsedTool.displayName
                        )

                        // 自然语言创建
                        naturalLanguageSection

                        // 快速操作
                        quickActionsSection

                        // 最近 AI 事件
                        recentAIEventsSection(events: vm.fetchAIEvents(limit: 10))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("AI Assistant")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNaturalLanguageSheet = true
                    } label: {
                        Image(systemName: "sparkles")
                    }
                }
            }
            .sheet(isPresented: $showingNaturalLanguageSheet) {
                NaturalLanguageSheet(
                    input: $naturalLanguageInput,
                    onCreate: { issue in
                        showingNaturalLanguageSheet = false
                        naturalLanguageInput = ""
                        selectedIssue = issue
                    }
                )
            }
            .sheet(item: $selectedIssue) { issue in
                IssueDetailView(issue: issue)
            }
            .onAppear {
                viewModel = AIAssistantViewModel(modelContext: modelContext)
            }
        }
    }

    // MARK: - Natural Language Section

    private var naturalLanguageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.bubble")
                    .foregroundStyle(.cyan)
                Text("Quick Create")
                    .font(.headline)
            }

            TextField("Describe what you need to build...", text: $naturalLanguageInput, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)

            Button {
                if !naturalLanguageInput.isEmpty, let vm = viewModel {
                    let issue = vm.createIssueFromNaturalLanguage(naturalLanguageInput)
                    selectedIssue = issue
                    naturalLanguageInput = ""
                }
            } label: {
                Label("Create Issue", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(naturalLanguageInput.isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.yellow)
                Text("Quick Actions")
                    .font(.headline)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    title: "Track AI Event",
                    icon: "plus.circle",
                    color: .blue
                ) {
                    showingNaturalLanguageSheet = true
                }

                QuickActionButton(
                    title: "Save Context",
                    icon: "bookmark",
                    color: .purple
                ) {
                    // 上下文保存
                }

                QuickActionButton(
                    title: "AI Summary",
                    icon: "text.document",
                    color: .green
                ) {
                    // AI 摘要
                }

                QuickActionButton(
                    title: "Generate Tests",
                    icon: "testpipe.2",
                    color: .orange
                ) {
                    // 测试生成
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recent AI Events Section

    private func recentAIEventsSection(events: [AITrackingEvent]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text("Recent AI Activity")
                    .font(.headline)
                Spacer()
                Button("See All") {}
                    .font(.caption)
            }

            if events.isEmpty {
                ContentUnavailableView(
                    "No AI Activity",
                    systemImage: "sparkles",
                    description: Text("AI interactions will appear here")
                )
                .frame(height: 150)
            } else {
                ForEach(events) { event in
                    AIEventRow(event: event)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AI Event Row

struct AIEventRow: View {
    let event: AITrackingEvent

    var body: some View {
        HStack(spacing: 12) {
            // 事件类型图标
            ZStack {
                Circle()
                    .fill(eventColor.opacity(0.2))
                Image(systemName: eventIcon)
                    .foregroundStyle(eventColor)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(eventTypeDisplayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(event.aiTool.replacingOccurrences(of: "_", with: " ").capitalized)
                    if event.tokensUsed > 0 {
                        Text("•")
                        Text("\(event.tokensUsed) tokens")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var eventTypeDisplayName: String {
        switch event.eventType {
        case "generation": return "Code Generation"
        case "refactor": return "Refactoring"
        case "fix": return "Bug Fix"
        case "review": return "Code Review"
        case "issue_creation": return "Issue Created"
        default: return event.eventType.capitalized
        }
    }

    private var eventIcon: String {
        switch event.eventType {
        case "generation": return "wand.and.stars"
        case "refactor": return "arrow.triangle.2.circlepath"
        case "fix": return "wrench.and.screwdriver"
        case "review": return "eye"
        case "issue_creation": return "plus.circle"
        default: return "questionmark"
        }
    }

    private var eventColor: Color {
        switch event.eventType {
        case "generation": return .cyan
        case "refactor": return .purple
        case "fix": return .orange
        case "review": return .blue
        case "issue_creation": return .green
        default: return .gray
        }
    }
}

// MARK: - Natural Language Sheet

struct NaturalLanguageSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Binding var input: String
    let onCreate: (Issue) -> Void

    @State private var selectedProject: Project?
    @State private var parsedPriority: IssuePriority = .medium
    @State private var parsedType: IssueType = .task
    @State private var isParsing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 输入区域
                VStack(alignment: .leading, spacing: 8) {
                    Text("Describe your task")
                        .font(.headline)

                    TextEditor(text: $input)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // 解析结果预览
                if !input.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detected")
                            .font(.headline)

                        HStack(spacing: 16) {
                            DetectedBadge(
                                title: "Priority",
                                value: parsedPriority.displayName,
                                icon: parsedPriority.icon
                            )

                            DetectedBadge(
                                title: "Type",
                                value: parsedType.displayName,
                                icon: parsedType.icon
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()

                // 创建按钮
                Button {
                    createIssue()
                } label: {
                    Label("Create Issue", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(input.isEmpty)
            }
            .padding()
            .navigationTitle("Quick Create")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: input) { _, newValue in
                parseInput(newValue)
            }
        }
        .presentationDetents([.large])
    }

    private func parseInput(_ text: String) {
        let lowercased = text.lowercased()

        // 解析优先级
        if lowercased.contains("urgent") || lowercased.contains("asap") || lowercased.contains("重要") {
            parsedPriority = .urgent
        } else if lowercased.contains("high") || lowercased.contains("紧急") {
            parsedPriority = .high
        } else if lowercased.contains("low") {
            parsedPriority = .low
        } else {
            parsedPriority = .medium
        }

        // 解析类型
        if lowercased.contains("bug") || lowercased.contains("错误") || lowercased.contains("修复") {
            parsedType = .bug
        } else if lowercased.contains("feature") || lowercased.contains("功能") {
            parsedType = .story
        } else if lowercased.contains("epic") || lowercased.contains("史诗") {
            parsedType = .epic
        } else {
            parsedType = .task
        }
    }

    private func createIssue() {
        let viewModel = AIAssistantViewModel(modelContext: modelContext)
        let issue = viewModel.createIssueFromNaturalLanguage(input, project: selectedProject)
        onCreate(issue)
    }
}

// MARK: - Detected Badge

struct DetectedBadge: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    AIAssistantView()
        .modelContainer(for: [Issue.self, Project.self, AITrackingEvent.self], inMemory: true)
}
