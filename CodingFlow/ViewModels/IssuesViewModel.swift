//
//  IssuesViewModel.swift
//  CodingFlow
//
//  任务视图模型
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
@Observable
final class IssuesViewModel {
    private let modelContext: ModelContext

    // 筛选状态
    var selectedProject: Project?
    var selectedStatus: IssueStatus?
    var selectedPriority: IssuePriority?
    var searchText: String = ""
    var showOnlyAI: Bool = false

    // 排序
    var sortOrder: SortOrder = .updatedDesc

    enum SortOrder: String, CaseIterable {
        case updatedDesc = "最近更新"
        case updatedAsc = "最早更新"
        case priorityHigh = "优先级高"
        case createdDesc = "最近创建"
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch Issues

    func fetchIssues() -> [Issue] {
        let descriptor = FetchDescriptor<Issue>(
            sortBy: buildSortDescriptors()
        )

        do {
            var issues = try modelContext.fetch(descriptor)

            // 应用筛选条件
            if let project = selectedProject {
                issues = issues.filter { $0.project?.id == project.id }
            }
            if let status = selectedStatus {
                issues = issues.filter { $0.status == status }
            }
            if let priority = selectedPriority {
                issues = issues.filter { $0.priority == priority }
            }
            if showOnlyAI {
                issues = issues.filter { $0.isAIGenerated }
            }
            if !searchText.isEmpty {
                issues = issues.filter {
                    $0.title.localizedStandardContains(searchText) ||
                    $0.issueDescription.localizedStandardContains(searchText)
                }
            }

            return issues
        } catch {
            print("Failed to fetch issues: \(error)")
            return []
        }
    }

    private func buildSortDescriptors() -> [SortDescriptor<Issue>] {
        switch sortOrder {
        case .updatedDesc:
            return [SortDescriptor(\.updatedAt, order: .reverse)]
        case .updatedAsc:
            return [SortDescriptor(\.updatedAt)]
        case .priorityHigh:
            return [SortDescriptor(\.priority, order: .reverse)]
        case .createdDesc:
            return [SortDescriptor(\.createdAt, order: .reverse)]
        }
    }

    // MARK: - Issue CRUD

    func createIssue(
        title: String,
        description: String = "",
        type: IssueType = .task,
        priority: IssuePriority = .medium,
        status: IssueStatus = .backlog,
        project: Project? = nil,
        cycle: Cycle? = nil,
        parentIssue: Issue? = nil,
        estimatedHours: Double? = nil
    ) -> Issue {
        let issue = Issue(
            title: title,
            issueDescription: description,
            status: status,
            priority: priority,
            type: type,
            project: project,
            issueNumber: generateNextIssueNumber(for: project)
        )
        issue.cycle = cycle
        issue.parentIssue = parentIssue
        issue.estimatedHours = estimatedHours

        modelContext.insert(issue)
        try? modelContext.save()

        return issue
    }

    func updateIssue(_ issue: Issue) {
        issue.updatedAt = Date()
        try? modelContext.save()
    }

    func deleteIssue(_ issue: Issue) {
        modelContext.delete(issue)
        try? modelContext.save()
    }

    func deleteIssues(_ issues: [Issue]) {
        for issue in issues {
            modelContext.delete(issue)
        }
        try? modelContext.save()
    }

    func changeStatus(_ issue: Issue, to status: IssueStatus) {
        issue.status = status
        issue.updatedAt = Date()
        try? modelContext.save()
    }

    // MARK: - Helpers

    private func generateNextIssueNumber(for project: Project?) -> Int {
        guard let project = project else { return 1 }

        let descriptor = FetchDescriptor<Issue>()

        do {
            let allIssues = try modelContext.fetch(descriptor)
            let projectIssues = allIssues.filter { $0.project?.id == project.id }
            let maxNumber = projectIssues.map { $0.issueNumber }.max() ?? 0
            return maxNumber + 1
        } catch {
            return 1
        }
    }

    // MARK: - Statistics

    func getIssueCounts(by status: IssueStatus, project: Project? = nil) -> Int {
        let descriptor = FetchDescriptor<Issue>()

        do {
            let allIssues = try modelContext.fetch(descriptor)
            return allIssues.filter { issue in
                issue.status == status && issue.project?.id == project?.id
            }.count
        } catch {
            return 0
        }
    }

    func getTodayIssues() -> [Issue] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<Issue>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let allIssues = try modelContext.fetch(descriptor)
            return allIssues.filter { $0.createdAt >= startOfDay }
        } catch {
            return []
        }
    }

    func clearFilters() {
        selectedProject = nil
        selectedStatus = nil
        selectedPriority = nil
        searchText = ""
        showOnlyAI = false
    }
}
