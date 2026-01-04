//
//  CyclesView.swift
//  CodingFlow
//
//  迭代周期视图
//

import SwiftUI
import SwiftData

struct CyclesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CyclesViewModel?
    @State private var showingCreateCycle = false
    @State private var selectedCycle: Cycle?

    @Query(sort: \Cycle.startDate, order: .reverse) private var allCycles: [Cycle]

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    cyclesContentView(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Cycles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateCycle = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingCreateCycle) {
                CreateCycleSheet()
            }
            .sheet(item: $selectedCycle) { cycle in
                CycleDetailView(cycle: cycle)
            }
            .onAppear {
                viewModel = CyclesViewModel(modelContext: modelContext)
            }
        }
    }

    private func cyclesContentView(viewModel: CyclesViewModel) -> some View {
        let activeCycles = viewModel.fetchActiveCycles()
        let upcomingCycles = viewModel.fetchUpcomingCycles()
        let pastCycles = allCycles.filter { $0.endDate < Date() && !$0.isArchived }

        return List {
            // 当前周期
            if !activeCycles.isEmpty {
                Section("Active Cycles") {
                    ForEach(activeCycles) { cycle in
                        CycleRow(
                            cycle: cycle,
                            stats: viewModel.getCycleStats(cycle),
                            isActive: true
                        )
                        .onTapGesture {
                            selectedCycle = cycle
                        }
                    }
                }
            }

            // 即将开始
            if !upcomingCycles.isEmpty {
                Section("Upcoming") {
                    ForEach(upcomingCycles) { cycle in
                        CycleRow(
                            cycle: cycle,
                            stats: viewModel.getCycleStats(cycle),
                            isActive: false
                        )
                        .onTapGesture {
                            selectedCycle = cycle
                        }
                    }
                }
            }

            // 历史周期
            if !pastCycles.isEmpty {
                Section("Past Cycles") {
                    ForEach(pastCycles) { cycle in
                        CycleRow(
                            cycle: cycle,
                            stats: viewModel.getCycleStats(cycle),
                            isActive: false
                        )
                        .onTapGesture {
                            selectedCycle = cycle
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.archiveCycle(pastCycles[index])
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Cycle Row

struct CycleRow: View {
    let cycle: Cycle
    let stats: CycleStats
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cycle.name)
                        .font(.headline)

                    HStack(spacing: 8) {
                        Label(
                            cycle.startDate.formatted(date: .abbreviated, time: .omitted),
                            systemImage: "calendar"
                        )
                        Image(systemName: "arrow.right")
                        Label(
                            cycle.endDate.formatted(date: .abbreviated, time: .omitted),
                            systemImage: "calendar"
                        )
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if isActive {
                    StatusBadge(status: .inProgress)
                }
            }

            // 进度条
            VStack(spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))

                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: geometry.size.width * stats.completionRate / 100)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("\(stats.completed)/\(stats.total) completed")
                    Spacer()
                    Text("\(Int(stats.completionRate))%")
                        .fontWeight(.medium)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            // 统计
            HStack(spacing: 16) {
                Label("\(stats.estimatedHours, specifier: "%.1f")h planned", systemImage: "clock")
                Spacer()
                Label("\(cycle.daysRemaining) days left", systemImage: "calendar.badge.clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Cycle Sheet

struct CreateCycleSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 一周后
    @State private var capacity: Double = 40
    @State private var selectedTemplate = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Cycle Name") {
                    TextField("Cycle name", text: $name)
                }

                Section("Duration") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)

                    // 模板
                    Picker("Quick Select", selection: $selectedTemplate) {
                        Text("This Week").tag(0)
                        Text("Two Week Sprint").tag(1)
                        Text("Month").tag(2)
                    }
                    .onChange(of: selectedTemplate) { _, newValue in
                        applyTemplate(newValue)
                    }
                }

                Section("Capacity") {
                    VStack(alignment: .leading) {
                        Text("Weekly Capacity: \(Int(capacity)) hours")
                        Slider(value: $capacity, in: 8...80, step: 8)
                    }
                }

                // 预览
                Section("Preview") {
                    let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
                    VStack(alignment: .leading, spacing: 8) {
                        Text(name.isEmpty ? "Cycle Name" : name)
                            .font(.headline)
                        Text("\(days) days • \(Int(capacity))h/week capacity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Cycle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createCycle()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func applyTemplate(_ template: Int) {
        let calendar = Calendar.current
        let now = Date()

        switch template {
        case 0: // This Week
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            startDate = weekStart
            endDate = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            name = "Week \(calendar.component(.weekOfYear, from: now))"
            capacity = 40
        case 1: // Two Week Sprint
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            startDate = weekStart
            endDate = calendar.date(byAdding: .day, value: 13, to: weekStart)!
            name = "Sprint \(calendar.component(.weekOfYear, from: now))"
            capacity = 80
        case 2: // Month
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            startDate = monthStart
            endDate = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            name = "Month \(calendar.component(.month, from: now))"
            capacity = 160
        default:
            break
        }
    }

    private func createCycle() {
        let viewModel = CyclesViewModel(modelContext: modelContext)
        let _ = viewModel.createCycle(
            name: name,
            startDate: startDate,
            endDate: endDate,
            capacity: capacity
        )
        dismiss()
    }
}

// MARK: - Cycle Detail View

struct CycleDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var cycle: Cycle

    @State private var viewModel: CyclesViewModel?

    private var stats: CycleStats {
        viewModel?.getCycleStats(cycle) ?? CycleStats()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 头部
                    cycleHeader

                    // 进度
                    cycleProgress

                    // 统计
                    cycleStats

                    // 问题列表
                    if let issues = cycle.issues, !issues.isEmpty {
                        issuesSection(issues)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(cycle.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel = CyclesViewModel(modelContext: modelContext)
            }
        }
    }

    private var cycleHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cycle.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 8) {
                        Label(
                            cycle.startDate.formatted(date: .abbreviated, time: .omitted),
                            systemImage: "calendar"
                        )
                        Image(systemName: "arrow.right")
                        Label(
                            cycle.endDate.formatted(date: .abbreviated, time: .omitted),
                            systemImage: "calendar"
                        )
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if cycle.isActive {
                    StatusBadge(status: .inProgress)
                }
            }

            if cycle.isActive {
                HStack {
                    Image(systemName: "clock")
                    Text("\(cycle.daysRemaining) days remaining")
                }
                .font(.subheadline)
                .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var cycleProgress: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Progress")
                    .font(.headline)
                Spacer()
                Text("\(Int(stats.completionRate))%")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))

                    HStack(spacing: 4) {
                        Capsule()
                            .fill(Color.green)
                            .frame(width: geometry.size.width * stats.completionRate / 100)

                        Spacer()
                    }
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(stats.completed)/\(stats.total) issues")
                Spacer()
                Text("\(stats.estimatedHours, specifier: "%.1f")h / \(stats.capacity, specifier: "%.0f")h")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var cycleStats: some View {
        HStack(spacing: 16) {
            StatPill(
                title: "To Do",
                value: "\(stats.backlog)",
                color: .blue
            )

            StatPill(
                title: "In Progress",
                value: "\(stats.inProgress)",
                color: .orange
            )

            StatPill(
                title: "In Review",
                value: "\(stats.inReview)",
                color: .purple
            )

            StatPill(
                title: "Done",
                value: "\(stats.completed)",
                color: .green
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func issuesSection(_ issues: [Issue]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Issues in Cycle")
                .font(.headline)

            ForEach(issues) { issue in
                IssueCard(issue: issue) { newStatus in
                    issue.status = newStatus
                    issue.updatedAt = Date()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CyclesView()
        .modelContainer(for: [Cycle.self, Issue.self], inMemory: true)
}
