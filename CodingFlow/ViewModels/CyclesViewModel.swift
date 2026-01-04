//
//  CyclesViewModel.swift
//  CodingFlow
//
//  迭代周期视图模型
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class CyclesViewModel {
    private let modelContext: ModelContext

    var searchText: String = ""

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch Cycles

    func fetchCycles(for project: Project? = nil) -> [Cycle] {
        let descriptor = FetchDescriptor<Cycle>(
            predicate: #Predicate { $0.isArchived == false },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        do {
            var cycles = try modelContext.fetch(descriptor)
            if let project = project {
                cycles = cycles.filter { $0.project?.id == project.id }
            }
            return cycles
        } catch {
            print("Failed to fetch cycles: \(error)")
            return []
        }
    }

    func fetchActiveCycles() -> [Cycle] {
        let descriptor = FetchDescriptor<Cycle>(
            predicate: #Predicate { $0.isArchived == false },
            sortBy: [SortDescriptor(\.startDate)]
        )

        do {
            let allCycles = try modelContext.fetch(descriptor)
            let now = Date()
            return allCycles.filter { $0.startDate <= now && $0.endDate >= now }
        } catch {
            return []
        }
    }

    func fetchUpcomingCycles() -> [Cycle] {
        let descriptor = FetchDescriptor<Cycle>(
            predicate: #Predicate { $0.isArchived == false },
            sortBy: [SortDescriptor(\.startDate)]
        )

        do {
            let allCycles = try modelContext.fetch(descriptor)
            let now = Date()
            return allCycles.filter { $0.startDate > now }
        } catch {
            return []
        }
    }

    // MARK: - Cycle CRUD

    func createCycle(
        name: String,
        startDate: Date,
        endDate: Date,
        project: Project? = nil,
        description: String = "",
        capacity: Double = 40
    ) -> Cycle {
        let cycle = Cycle(
            name: name,
            startDate: startDate,
            endDate: endDate,
            project: project,
            cycleDescription: description
        )
        cycle.totalCapacity = capacity

        modelContext.insert(cycle)
        try? modelContext.save()

        return cycle
    }

    func updateCycle(_ cycle: Cycle) {
        try? modelContext.save()
    }

    func deleteCycle(_ cycle: Cycle) {
        modelContext.delete(cycle)
        try? modelContext.save()
    }

    func archiveCycle(_ cycle: Cycle) {
        cycle.isArchived = true
        cycle.issues = nil // 解除关联
        try? modelContext.save()
    }

    // MARK: - Issue Assignment

    func assignIssueToCycle(_ issue: Issue, cycle: Cycle) {
        issue.cycle = cycle
        issue.updatedAt = Date()
        try? modelContext.save()
    }

    func removeIssueFromCycle(_ issue: Issue) {
        issue.cycle = nil
        issue.updatedAt = Date()
        try? modelContext.save()
    }

    // MARK: - Statistics

    func getCycleStats(_ cycle: Cycle) -> CycleStats {
        guard let issues = cycle.issues else {
            return CycleStats()
        }

        let total = issues.count
        let completed = issues.filter { $0.status == .done }.count
        let inProgress = issues.filter { $0.status == .inProgress }.count
        let inReview = issues.filter { $0.status == .inReview }.count
        let backlog = issues.filter { $0.status == .backlog || $0.status == .todo }.count

        // 计算预估时间
        let estimatedHours = issues.compactMap { $0.estimatedHours }.reduce(0, +)
        let actualHours = issues.compactMap { $0.actualHours }.reduce(0, +)

        return CycleStats(
            total: total,
            completed: completed,
            inProgress: inProgress,
            inReview: inReview,
            backlog: backlog,
            estimatedHours: estimatedHours,
            actualHours: actualHours,
            capacity: cycle.totalCapacity
        )
    }

    // MARK: - Quick Create

    func createCurrentWeekCycle(for project: Project? = nil) -> Cycle {
        let calendar = Calendar.current
        let now = Date()

        // 获取本周开始和结束
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!

        return createCycle(
            name: "Week \(calendar.component(.weekOfYear, from: now))",
            startDate: weekStart,
            endDate: weekEnd,
            project: project,
            capacity: 40
        )
    }

    func createTwoWeekSprint(for project: Project? = nil) -> Cycle {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!

        return createCycle(
            name: "Sprint \(calendar.component(.weekOfYear, from: now))",
            startDate: startOfWeek,
            endDate: calendar.date(byAdding: .day, value: 13, to: startOfWeek)!,
            project: project,
            capacity: 80
        )
    }
}

// MARK: - Cycle Stats

struct CycleStats {
    var total: Int = 0
    var completed: Int = 0
    var inProgress: Int = 0
    var inReview: Int = 0
    var backlog: Int = 0
    var estimatedHours: Double = 0
    var actualHours: Double = 0
    var capacity: Double = 40

    var completionRate: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total) * 100
    }

    var capacityUsed: Double {
        guard capacity > 0 else { return 0 }
        return estimatedHours / capacity * 100
    }

    var velocity: Double {
        // 假设已完成的任务每个估 2 小时
        return Double(completed) * 2
    }
}
