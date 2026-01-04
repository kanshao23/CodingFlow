//
//  CodingFlowApp.swift
//  CodingFlow
//
//  AI 时代独立开发者项目管理应用
//

import SwiftUI
import SwiftData

@main
struct CodingFlowApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // 项目模型
            Project.self,
            IssueLabel.self,
            Issue.self,
            Comment.self,
            Cycle.self,

            // AI 追踪模型
            AITrackingEvent.self,
            ContextSnapshot.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none // 暂时禁用 CloudKit，简化同步逻辑
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // 保存数据
            saveContext()
        case .inactive:
            // 准备保存
            break
        case .active:
            // 刷新数据
            break
        @unknown default:
            break
        }
    }

    private func saveContext() {
        // SwiftData 会自动保存，无需手动保存
    }
}
