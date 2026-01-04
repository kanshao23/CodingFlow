//
//  ProjectsView.swift
//  CodingFlow
//
//  项目列表视图
//

import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ProjectsViewModel?
    @State private var selectedProject: Project?
    @State private var showingCreateProject = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    projectListView(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateProject = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search projects")
            .onChange(of: searchText) { _, newValue in
                viewModel?.searchText = newValue
            }
            .sheet(isPresented: $showingCreateProject) {
                CreateProjectSheet()
            }
            .navigationDestination(item: $selectedProject) { project in
                ProjectDetailView(project: project)
            }
            .onAppear {
                viewModel = ProjectsViewModel(modelContext: modelContext)
            }
        }
    }

    private func projectListView(viewModel: ProjectsViewModel) -> some View {
        let projects = viewModel.fetchProjects()

        return Group {
            if projects.isEmpty {
                ContentUnavailableView(
                    "No Projects",
                    systemImage: "folder.badge.plus",
                    description: Text("Create your first project to start organizing issues")
                )
            } else {
                List(projects) { project in
                    ProjectRow(
                        project: project,
                        stats: viewModel.getProjectStats(project)
                    )
                    .onTapGesture {
                        selectedProject = project
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteProject(project)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            // 归档
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(.orange)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

// MARK: - Project Row

struct ProjectRow: View {
    let project: Project
    let stats: ProjectStats

    var body: some View {
        HStack(spacing: 12) {
            // 项目图标
            ZStack {
                Circle()
                    .fill(Color(hex: project.colorHex).opacity(0.2))
                Image(systemName: project.icon)
                    .foregroundStyle(Color(hex: project.colorHex))
            }
            .frame(width: 44, height: 44)

            // 项目信息
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)

                if !project.projectDescription.isEmpty {
                    Text(project.projectDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    Label("\(stats.total)", systemImage: "list.bullet")
                    Label("\(stats.completed)", systemImage: "checkmark.circle")
                    if stats.aiGenerated > 0 {
                        Label("\(stats.aiGenerated)", systemImage: "sparkles")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // 进度环
            ProgressRing(progress: stats.completionRate, color: Color(hex: project.colorHex), lineWidth: 4)
                .frame(width: 44, height: 44)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Project Sheet

struct CreateProjectSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColor = "007AFF"

    private let icons = [
        "folder.fill", "star.fill", "heart.fill", "bolt.fill",
        "flame.fill", "leaf.fill", "drop.fill", "moon.fill",
        "sun.max.fill", "cloud.fill", "gearshape.fill", "wrench.fill"
    ]

    private let colors = [
        "007AFF", "34C759", "FF9500", "FF3B30",
        "5856D6", "AF52DE", "FF2D55", "00C7BE",
        "FFD60A", "8E8E93"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Name") {
                    TextField("Project name", text: $name)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
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
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
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

                // 预览
                Section("Preview") {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColor).opacity(0.2))
                            Image(systemName: selectedIcon)
                                .foregroundStyle(Color(hex: selectedColor))
                        }
                        .frame(width: 44, height: 44)

                        VStack(alignment: .leading) {
                            Text(name.isEmpty ? "Project Name" : name)
                                .font(.headline)
                            if !description.isEmpty {
                                Text(description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createProject()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func createProject() {
        let viewModel = ProjectsViewModel(modelContext: modelContext)
        let _ = viewModel.createProject(
            name: name,
            description: description,
            icon: selectedIcon,
            colorHex: selectedColor
        )
        dismiss()
    }
}

#Preview {
    ProjectsView()
        .modelContainer(for: [Project.self, Issue.self], inMemory: true)
}
