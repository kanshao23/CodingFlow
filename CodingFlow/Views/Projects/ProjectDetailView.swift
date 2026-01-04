//
//  ProjectDetailView.swift
//  CodingFlow
//
//  项目详情视图
//

import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project

    @State private var viewModel: ProjectsViewModel?
    @State private var showingCreateIssue = false
    @State private var showingSettings = false
    @State private var selectedIssue: Issue?

    @Query(sort: \Issue.createdAt, order: .reverse) private var allIssues: [Issue]

    private var issues: [Issue] {
        allIssues.filter { $0.project?.id == project.id }
    }

    private var stats: ProjectStats {
        viewModel?.getProjectStats(project) ?? ProjectStats()
    }

    var body: some View {
        List {
            // 项目头部
            Section {
                projectHeader
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            // 统计概览
            Section("Overview") {
                HStack(spacing: 16) {
                    StatMiniCard(
                        title: "Total",
                        value: "\(stats.total)",
                        icon: "list.bullet",
                        color: .blue
                    )

                    StatMiniCard(
                        title: "Done",
                        value: "\(stats.completed)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )

                    StatMiniCard(
                        title: "In Progress",
                        value: "\(stats.inProgress)",
                        icon: "play.circle.fill",
                        color: .orange
                    )

                    if stats.aiGenerated > 0 {
                        StatMiniCard(
                            title: "AI",
                            value: "\(stats.aiGenerated)",
                            icon: "sparkles",
                            color: .cyan
                        )
                    }
                }
            }

            // 按状态分组
            ForEach(IssueStatus.allCases, id: \.self) { status in
                let statusIssues = issues.filter { $0.status == status && $0.type != .subtask }

                if !statusIssues.isEmpty {
                    Section {
                        ForEach(statusIssues) { issue in
                            IssueRowCompact(issue: issue)
                                .onTapGesture {
                                    selectedIssue = issue
                                }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                modelContext.delete(statusIssues[index])
                            }
                            try? modelContext.save()
                        }
                    } header: {
                        HStack {
                            Label(status.displayName, systemImage: status.icon)
                            Spacer()
                            Text("\(statusIssues.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Quick add button
                    Button {
                        showingCreateIssue = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }

                    // Settings menu
                    Menu {
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateIssue) {
            CreateIssueSheet(preselectedProject: project)
        }
        .sheet(item: $selectedIssue) { issue in
            IssueDetailView(issue: issue)
        }
        .sheet(isPresented: $showingSettings) {
            ProjectSettingsView(project: project)
        }
        .onAppear {
            viewModel = ProjectsViewModel(modelContext: modelContext)
        }
    }

    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(hex: project.colorHex).opacity(0.2))
                    Image(systemName: project.icon)
                        .foregroundStyle(Color(hex: project.colorHex))
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    if !project.projectDescription.isEmpty {
                        Text(project.projectDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                ProgressRing(progress: stats.completionRate, color: Color(hex: project.colorHex), lineWidth: 6)
                    .frame(width: 60, height: 60)
            }

            // 标签
            if !project.labels.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(project.labels) { label in
                            LabelTag(label: label)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Stat Mini Card

struct StatMiniCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Issue Row Compact

struct IssueRowCompact: View {
    let issue: Issue

    var body: some View {
        HStack(spacing: 12) {
            // 类型图标
            IssueTypeIcon(type: issue.type)

            VStack(alignment: .leading, spacing: 2) {
                Text("#\(issue.issueNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(issue.title)
                    .font(.body)
                    .lineLimit(1)
            }

            Spacer()

            if issue.isAIGenerated {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.cyan)
            }

            PriorityBadge(priority: issue.priority)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Project Settings View

struct ProjectSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var project: Project

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var selectedIcon: String = ""
    @State private var selectedColor: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Project Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(["folder.fill", "star.fill", "heart.fill", "bolt.fill", "flame.fill", "leaf.fill"], id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                                project.icon = icon
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(selectedIcon == icon ? Color(hex: selectedColor) : Color(hex: selectedColor).opacity(0.2))
                                    Image(systemName: icon)
                                        .foregroundStyle(selectedIcon == icon ? .white : Color(hex: selectedColor))
                                }
                                .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(["007AFF", "34C759", "FF9500", "FF3B30", "5856D6"], id: \.self) { color in
                            Button {
                                selectedColor = color
                                project.colorHex = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .fontWeight(.bold)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Project Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        project.name = name
                        project.projectDescription = description
                        project.updatedAt = Date()
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = project.name
                description = project.projectDescription
                selectedIcon = project.icon
                selectedColor = project.colorHex
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Preview
#if DEBUG
struct ProjectDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProjectDetailView(
                project: Project(
                    name: "My App",
                    projectDescription: "iOS app for developers"
                )
            )
        }
        .modelContainer(for: [Project.self, Issue.self, IssueLabel.self], inMemory: true)
    }
}
#endif
