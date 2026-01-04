//
//  IssuesView.swift
//  CodingFlow
//
//  任务列表主视图
//

import SwiftUI
import SwiftData

struct IssuesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: IssuesViewModel?
    @State private var selectedIssue: Issue?
    @State private var showingCreateSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部标题栏
                headerSection

                // 筛选栏
                if let vm = viewModel {
                    FilterBarView(viewModel: vm)
                }

                Divider()

                // 任务列表
                if let vm = viewModel {
                    IssueListView(viewModel: vm, selectedIssue: $selectedIssue)
                }
            }
            .background(DesignTokens.Colors.groupedBackground)
            .navigationTitle("Issues")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    sortMenu
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateSheet.toggle() }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(DesignTokens.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateIssueSheet(preselectedProject: viewModel?.selectedProject)
            }
            .sheet(item: $selectedIssue) { issue in
                IssueDetailView(issue: issue)
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = IssuesViewModel(modelContext: modelContext)
                }
            }
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Issues")
                    .font(DesignTokens.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignTokens.Colors.label)

                Text("All issues")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.secondaryLabel)
            }

            Spacer()

            // 今日统计
            if let vm = viewModel {
                let todayCount = vm.getTodayIssues().count
                if todayCount > 0 {
                    VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xxs) {
                        Text("\(todayCount)")
                            .font(DesignTokens.Typography.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(DesignTokens.Colors.primary)
                        Text("today")
                            .font(DesignTokens.Typography.caption2)
                            .foregroundStyle(DesignTokens.Colors.secondaryLabel)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.background)
    }

    private var sortMenu: some View {
        Menu {
            ForEach(IssuesViewModel.SortOrder.allCases, id: \.self) { order in
                Button {
                    viewModel?.sortOrder = order
                } label: {
                    Label(order.rawValue, systemImage: "arrow.up.arrow.down")
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
}

// MARK: - Filter Bar

struct FilterBar: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.updatedAt, order: .reverse) private var allProjects: [Project]

    private var viewModel: IssuesViewModel? {
        // 通过 EnvironmentObject 模式获取 viewModel
        // 这里需要从父视图获取
        nil
    }

    var body: some View {
        // 筛选栏的实现将放在 IssuesView 内部
        EmptyView()
    }
}

struct FilterBarView: View {
    @Bindable var viewModel: IssuesViewModel
    @Query(sort: \Project.updatedAt, order: .reverse) private var allProjects: [Project]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                // 搜索框
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.Colors.secondaryLabel)

                    TextField("Search...", text: $viewModel.searchText)
                        .font(DesignTokens.Typography.subheadline)
                        .textFieldStyle(.plain)
                        .frame(width: 120)

                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(DesignTokens.Colors.secondaryLabel)
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, 10)
                .background(DesignTokens.Colors.secondaryBackground.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
                .frame(width: 180)

                // 项目筛选按钮
                Menu {
                    Button {
                        viewModel.selectedProject = nil
                    } label: {
                        Label("All Projects", systemImage: "folder")
                    }
                    Divider()
                    ForEach(allProjects) { project in
                        Button {
                            viewModel.selectedProject = project
                        } label: {
                            Label(project.name, systemImage: project.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if let project = viewModel.selectedProject {
                            Image(systemName: project.icon)
                                .font(.system(size: 12))
                            Text(project.name)
                                .font(DesignTokens.Typography.subheadline)
                                .fontWeight(.medium)
                        } else {
                            Image(systemName: "folder")
                                .font(.system(size: 12))
                            Text("Project")
                                .font(DesignTokens.Typography.subheadline)
                        }
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundStyle(DesignTokens.Colors.secondaryLabel)
                    }
                    .foregroundStyle(viewModel.selectedProject != nil ? Color(hex: viewModel.selectedProject!.colorHex) : DesignTokens.Colors.secondaryLabel)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, 10)
                    .background(DesignTokens.Colors.secondaryBackground.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
                }

                // 状态筛选
                if let status = viewModel.selectedStatus {
                    ActiveFilterChip(
                        icon: status.icon,
                        label: status.displayName,
                        color: DesignTokens.Colors.statusColor(status)
                    ) {
                        viewModel.selectedStatus = nil
                    }
                }

                // 优先级筛选
                if let priority = viewModel.selectedPriority {
                    ActiveFilterChip(
                        icon: priority.icon,
                        label: priority.displayName,
                        color: DesignTokens.Colors.priorityColor(priority)
                    ) {
                        viewModel.selectedPriority = nil
                    }
                }

                // AI 筛选
                if viewModel.showOnlyAI {
                    ActiveFilterChip(
                        icon: "sparkles",
                        label: "AI",
                        color: DesignTokens.Colors.aiAccent
                    ) {
                        viewModel.showOnlyAI = false
                    }
                }

                // 快捷筛选菜单
                Menu {
                    Section("Status") {
                        ForEach(IssueStatus.allCases) { status in
                            Button {
                                viewModel.selectedStatus = status
                            } label: {
                                Label(status.displayName, systemImage: status.icon)
                            }
                        }
                    }
                    Divider()
                    Section("Priority") {
                        ForEach(IssuePriority.allCases) { priority in
                            Button {
                                viewModel.selectedPriority = priority
                            } label: {
                                Label(priority.displayName, systemImage: priority.icon)
                            }
                        }
                    }
                    Divider()
                    Button {
                        viewModel.showOnlyAI.toggle()
                    } label: {
                        Label(viewModel.showOnlyAI ? "Show AI Only (On)" : "Show AI Only", systemImage: "sparkles")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 16))
                        Text("Filter")
                            .font(DesignTokens.Typography.subheadline)
                    }
                    .foregroundStyle(DesignTokens.Colors.secondaryLabel)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, 10)
                    .background(DesignTokens.Colors.secondaryBackground.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
        .background(DesignTokens.Colors.background)
    }
}

// MARK: - Active Filter Chip

struct ActiveFilterChip: View {
    let icon: String
    let label: String
    let color: Color
    let onClear: () -> Void

    var body: some View {
        Button(action: onClear) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(DesignTokens.Typography.subheadline)
                    .fontWeight(.medium)
                Image(systemName: "xmark")
                    .font(.system(size: 10))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Issue List View

struct IssueListView: View {
    @Bindable var viewModel: IssuesViewModel
    @Binding var selectedIssue: Issue?

    var body: some View {
        let issues = viewModel.fetchIssues()

        if issues.isEmpty {
            ContentUnavailableView(
                viewModel.searchText.isEmpty ? "No Issues" : "No Results",
                systemImage: viewModel.searchText.isEmpty ? "list.bullet.rectangle" : "magnifyingglass",
                description: Text(viewModel.searchText.isEmpty ? "Create your first issue to get started" : "Try adjusting your filters")
            )
        } else {
            List {
                // 分组显示
                ForEach(IssueStatus.allCases, id: \.self) { status in
                    let statusIssues = issues.filter { $0.status == status && $0.type != .subtask }

                    if !statusIssues.isEmpty {
                        Section {
                            ForEach(statusIssues) { issue in
                                IssueCard(issue: issue) { newStatus in
                                    viewModel.changeStatus(issue, to: newStatus)
                                } onTap: {
                                    selectedIssue = issue
                                }
                            }
                            .onDelete { indexSet in
                                let issuesToDelete = statusIssues
                                viewModel.deleteIssues(issuesToDelete)
                            }
                        } header: {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(DesignTokens.Colors.statusColor(status).opacity(0.2))
                                        .frame(width: 24, height: 24)
                                    Image(systemName: status.icon)
                                        .font(.system(size: 12))
                                        .foregroundStyle(DesignTokens.Colors.statusColor(status))
                                }

                                Text(status.displayName)
                                    .font(DesignTokens.Typography.subheadline)
                                    .fontWeight(.semibold)

                                Spacer()

                                Text("\(statusIssues.count)")
                                    .font(DesignTokens.Typography.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(DesignTokens.Colors.secondaryLabel)
                                    .padding(.horizontal, DesignTokens.Spacing.sm)
                                    .padding(.vertical, 2)
                                    .background(DesignTokens.Colors.secondaryBackground.opacity(0.5))
                                    .clipShape(Capsule())
                            }
                            .padding(.bottom, DesignTokens.Spacing.sm)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
    }
}

// MARK: - Create Issue Sheet

struct CreateIssueSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let preselectedProject: Project?

    @State private var title = ""
    @State private var description = ""
    @State private var type: IssueType = .task
    @State private var priority: IssuePriority = .medium
    @State private var estimatedHours: Double?
    @State private var selectedProject: Project?

    @Query(sort: \Project.updatedAt, order: .reverse) private var allProjects: [Project]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Issue title", text: $title)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Project") {
                    Picker("Project", selection: $selectedProject) {
                        Text("No Project").tag(nil as Project?)
                        ForEach(allProjects) { project in
                            Label(project.name, systemImage: project.icon)
                                .tag(project as Project?)
                        }
                    }
                }

                Section("Properties") {
                    Picker("Type", selection: $type) {
                        ForEach(IssueType.allCases) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }

                    Picker("Priority", selection: $priority) {
                        ForEach(IssuePriority.allCases) { priority in
                            Label(priority.displayName, systemImage: priority.icon)
                                .tag(priority)
                        }
                    }

                    Stepper(
                        "Estimated: \(estimatedHours.map { "\($0)h" } ?? "None")",
                        value: Binding(
                            get: { estimatedHours ?? 0 },
                            set: { estimatedHours = $0 == 0 ? nil : $0 }
                        ),
                        in: 0...100,
                        step: 0.5
                    )
                }
            }
            .navigationTitle("New Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createIssue()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            selectedProject = preselectedProject
        }
    }

    private func createIssue() {
        let viewModel = IssuesViewModel(modelContext: modelContext)
        let _ = viewModel.createIssue(
            title: title,
            description: description,
            type: type,
            priority: priority,
            project: selectedProject,
            estimatedHours: estimatedHours
        )
        dismiss()
    }
}

#Preview {
    IssuesView()
        .modelContainer(for: [Issue.self, Project.self, IssueLabel.self, Cycle.self], inMemory: true)
}
