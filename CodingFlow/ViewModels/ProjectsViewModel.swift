//
//  ProjectsViewModel.swift
//  CodingFlow
//
//  项目视图模型
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class ProjectsViewModel {
    private let modelContext: ModelContext

    var searchText: String = ""

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch Projects

    func fetchProjects() -> [Project] {
        let descriptor: FetchDescriptor<Project>

        if searchText.isEmpty {
            descriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        } else {
            descriptor = FetchDescriptor<Project>(
                predicate: #Predicate {
                    $0.name.localizedStandardContains(searchText) ||
                    $0.projectDescription.localizedStandardContains(searchText)
                },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
        }

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch projects: \(error)")
            return []
        }
    }

    // MARK: - Project CRUD

    func createProject(
        name: String,
        description: String = "",
        icon: String = "folder.fill",
        colorHex: String = "007AFF"
    ) -> Project {
        let project = Project(
            name: name,
            projectDescription: description,
            icon: icon,
            colorHex: colorHex
        )

        // 创建默认标签
        let defaultLabels = [
            IssueLabel(name: "Feature", colorHex: "34C759", icon: "star.fill", project: project),
            IssueLabel(name: "Bug", colorHex: "FF3B30", icon: "ladybug.fill", project: project),
            IssueLabel(name: "Tech Debt", colorHex: "FF9500", icon: "wrench.fill", project: project),
            IssueLabel(name: "Research", colorHex: "5856D6", icon: "magnifyingglass", project: project),
            IssueLabel(name: "AI Generated", colorHex: "00C7BE", icon: "sparkles", project: project)
        ]

        for label in defaultLabels {
            modelContext.insert(label)
        }

        modelContext.insert(project)
        try? modelContext.save()

        return project
    }

    func updateProject(_ project: Project) {
        project.updatedAt = Date()
        try? modelContext.save()
    }

    func deleteProject(_ project: Project) {
        modelContext.delete(project)
        try? modelContext.save()
    }

    // MARK: - Statistics

    func getProjectStats(_ project: Project) -> ProjectStats {
        let issues = project.issues

        let total = issues.count
        let completed = issues.filter { $0.status == .done }.count
        let inProgress = issues.filter { $0.status == .inProgress }.count
        let inReview = issues.filter { $0.status == .inReview }.count
        let backlog = issues.filter { $0.status == .backlog }.count
        let aiGenerated = issues.filter { $0.isAIGenerated }.count

        return ProjectStats(
            total: total,
            completed: completed,
            inProgress: inProgress,
            inReview: inReview,
            backlog: backlog,
            aiGenerated: aiGenerated
        )
    }
}

// MARK: - Project Stats

struct ProjectStats {
    var total: Int = 0
    var completed: Int = 0
    var inProgress: Int = 0
    var inReview: Int = 0
    var backlog: Int = 0
    var aiGenerated: Int = 0

    var completionRate: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total) * 100
    }
}
