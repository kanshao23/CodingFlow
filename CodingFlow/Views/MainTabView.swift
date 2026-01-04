//
//  MainTabView.swift
//  CodingFlow
//
//  主标签页视图
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Issues Tab
            IssuesView()
                .tabItem {
                    Label("Issues", systemImage: "list.bullet.rectangle")
                }
                .tag(0)

            // Projects Tab
            ProjectsView()
                .tabItem {
                    Label("Projects", systemImage: "folder.fill")
                }
                .tag(1)

            // AI Assistant Tab
            AIAssistantView()
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }
                .tag(2)

            // Cycles Tab
            CyclesView()
                .tabItem {
                    Label("Cycles", systemImage: "arrow.triangle.2.circlepath")
                }
                .tag(3)

            // Settings placeholder
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(.blue)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("defaultProjectId") private var defaultProjectId: String?
    @AppStorage("showAIWarnings") private var showAIWarnings = true
    @AppStorage("hapticFeedback") private var hapticFeedback = true

    @Query private var projects: [Project]

    var body: some View {
        NavigationStack {
            Form {
                // 默认项目
                Section("General") {
                    Picker("Default Project", selection: $defaultProjectId) {
                        Text("None").tag(String?.none)
                        ForEach(projects) { project in
                            Label(project.name, systemImage: project.icon)
                                .tag(project.id.uuidString as String?)
                        }
                    }
                }

                // 外观
                Section("Appearance") {
                    Picker("Theme", selection: $appTheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }

                // AI 设置
                Section("AI Features") {
                    Toggle("Show AI Generation Warnings", isOn: $showAIWarnings)

                    NavigationLink {
                        AIUsageStatsView()
                    } label: {
                        Label("AI Usage Statistics", systemImage: "chart.bar")
                    }
                }

                // 反馈
                Section("Feedback") {
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)

                    NavigationLink {
                        Text("Feedback form placeholder")
                            .navigationTitle("Send Feedback")
                    } label: {
                        Label("Send Feedback", systemImage: "envelope")
                    }
                }

                // 关于
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink {
                        Text("Privacy policy placeholder")
                            .navigationTitle("Privacy Policy")
                    } label: {
                        Text("Privacy Policy")
                    }

                    NavigationLink {
                        Text("Terms of service placeholder")
                            .navigationTitle("Terms of Service")
                    } label: {
                        Text("Terms of Service")
                    }
                }

                // 数据管理
                Section("Data") {
                    NavigationLink {
                        ExportDataView()
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        // 清空数据
                    } label: {
                        Label("Delete All Data", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - AI Usage Stats View

struct AIUsageStatsView: View {
    @Environment(\.modelContext) var modelContext

    @Query(sort: \AITrackingEvent.timestamp, order: .reverse) var aiEvents: [AITrackingEvent]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 总统计
                HStack(spacing: 16) {
                    StatBox(
                        title: "Total Events",
                        value: "\(aiEvents.count)",
                        icon: "bolt.fill",
                        color: .blue
                    )

                    let totalTokens = aiEvents.reduce(0) { $0 + $1.tokensUsed }
                    StatBox(
                        title: "Total Tokens",
                        value: formatNumber(totalTokens),
                        icon: "text.alignleft",
                        color: .purple
                    )
                }

                // 按工具分布
                let toolStats = Dictionary(grouping: aiEvents, by: { $0.aiTool })
                    .mapValues { $0.count }
                    .sorted { $0.value > $1.value }

                VStack(alignment: .leading, spacing: 12) {
                    Text("By AI Tool")
                        .font(.headline)

                    ForEach(toolStats, id: \.key) { tool, count in
                        HStack {
                            Text(tool.replacingOccurrences(of: "_", with: " ").capitalized)
                            Spacer()
                            Text("\(count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // 按事件类型
                let typeStats = Dictionary(grouping: aiEvents, by: { $0.eventType })
                    .mapValues { $0.count }
                    .sorted { $0.value > $1.value }

                VStack(alignment: .leading, spacing: 12) {
                    Text("By Event Type")
                        .font(.headline)

                    ForEach(typeStats, id: \.key) { type, count in
                        HStack {
                            Text(type.capitalized)
                            Spacer()
                            Text("\(count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("AI Usage")
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

// MARK: - Stat Box

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Export Data View

struct ExportDataView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var projects: [Project]
    @Query private var issues: [Issue]
    @Query private var cycles: [Cycle]

    var body: some View {
        List {
            Section("Export Options") {
                Button {
                    exportAsJSON()
                } label: {
                    Label("Export as JSON", systemImage: "doc.text")
                }

                Button {
                    exportAsCSV()
                } label: {
                    Label("Export as CSV", systemImage: "tablecells")
                }
            }

            Section("Data Summary") {
                HStack {
                    Text("Projects")
                    Spacer()
                    Text("\(projects.count)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Issues")
                    Spacer()
                    Text("\(issues.count)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Cycles")
                    Spacer()
                    Text("\(cycles.count)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Export Data")
    }

    private func exportAsJSON() {
        // TODO: 实现 JSON 导出
    }

    private func exportAsCSV() {
        // TODO: 实现 CSV 导出
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Project.self, Issue.self, Cycle.self, AITrackingEvent.self], inMemory: true)
}
