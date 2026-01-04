# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Test Commands

### Building
```bash
# Build the project
xcodebuild -scheme CodingFlow -configuration Debug build

# Build for testing
xcodebuild -scheme CodingFlow -configuration Debug build-for-testing
```

### Testing
```bash
# Run all tests
xcodebuild test -scheme CodingFlow -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test
xcodebuild test -scheme CodingFlow -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:CodingFlowTests/CodingFlowTests/testExample
```

### Running
Open `CodingFlow.xcodeproj` in Xcode and run the CodingFlow scheme.

## Architecture Overview

CodingFlow is a SwiftUI + SwiftData project management application designed for solo developers in the AI era. The app tracks projects, issues, development cycles, and AI tool usage.

### Core Architecture Pattern

The app follows **MVVM architecture**:
- **Models** (`CodingFlow/Models/`): SwiftData models with `@Model` macro
- **Views** (`CodingFlow/Views/`): SwiftUI views organized by feature
- **ViewModels** (`CodingFlow/ViewModels/`): `@Observable` classes managing business logic

All ViewModels are marked `@MainActor` and use the `@Observable` macro (not `ObservableObject`).

### Data Layer (SwiftData)

The app uses **SwiftData** for persistence with the following schema hierarchy:

**Core Schema** (defined in `CodingFlowApp.swift:16-27`):
```
Project
├── Issue (cascade delete)
│   ├── Comment (cascade delete)
│   └── Issue (subtasks, cascade delete)
├── IssueLabel (cascade delete)
└── Cycle (nullify delete)

AITrackingEvent (independent)
ContextSnapshot (independent)
```

**Key Model Relationships**:
- `Project` → `Issue`: One-to-many with cascade delete
- `Issue` → `Issue`: Self-referencing parent-child for subtasks
- `Issue` → `Cycle`: Many-to-one, nullified on delete
- `Issue` → `IssueLabel`: Many-to-many through optional array (one-directional to avoid circular references)

**Important**: The `Issue.labels` relationship is **one-directional** (no inverse `IssueLabel.issues`) to prevent SwiftData circular reference issues.

### Navigation Structure

Main app entry: `CodingFlowApp.swift` → `MainTabView.swift`

**5 Main Tabs**:
1. **Issues** (`IssuesView`) - Issue management with filtering/sorting
2. **Projects** (`ProjectsView`) - Project overview and management
3. **AI Assistant** (`AIAssistantView`) - AI usage tracking and natural language issue creation
4. **Cycles** (`CyclesView`) - Sprint/iteration management
5. **Settings** (`SettingsView`) - Embedded in `MainTabView.swift`

### AI Tracking System

The app has a unique **AI development tracking** feature that monitors AI tool usage:

- `AITrackingEvent`: Records each AI interaction (tool used, tokens, prompt summary, files changed)
- `ContextSnapshot`: Captures development state at a point in time (completion %, key files, pending items)
- `Issue.isAIGenerated`: Boolean flag tracking AI-generated issues
- `Issue.aiGenerationCount`: Counter for AI interactions per issue
- `Issue.aiContextTokens`: Token usage tracking per issue

**Supported AI Tools** (from `AITool` enum):
- Claude Code, Cursor, Antigravity, Codex CLI, Gemini CLI, ChatGPT

### ViewModel Patterns

All ViewModels follow these conventions:

1. **Initialization**: Accept `ModelContext` as parameter
   ```swift
   init(modelContext: ModelContext) {
       self.modelContext = modelContext
   }
   ```

2. **Data Fetching**: Use `FetchDescriptor` with predicates/sorting
   ```swift
   let descriptor = FetchDescriptor<Issue>(
       sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
   )
   let issues = try modelContext.fetch(descriptor)
   ```

3. **Filtering**: Apply filters in-memory after fetch (see `IssuesViewModel.fetchIssues()`)

4. **CRUD Operations**: Always call `modelContext.save()` after modifications

### Issue Numbering System

Issues have a **project-scoped auto-incrementing number** (`Issue.issueNumber`):
- Generated in `IssuesViewModel.generateNextIssueNumber(for:)`
- Unique within each project (not globally unique)
- Calculated by finding max number in project and adding 1

### Color and Icon System

Models use **hex color strings** (not Color objects):
- `Project.colorHex`: String like "007AFF"
- `IssueLabel.colorHex`: String like "FF9500"

Enums provide display metadata:
- `IssueStatus`: Has `displayName`, `icon`, `color` properties
- `IssuePriority`: Comparable enum (urgent < high < medium < low)
- `IssueType`: Epic, Story, Task, Bug, Subtask

### Settings and AppStorage

Settings are stored using `@AppStorage` (in `SettingsView`):
- `appTheme`: "system" | "light" | "dark"
- `defaultProjectId`: UUID string of default project
- `showAIWarnings`: Toggle for AI generation warnings
- `hapticFeedback`: Haptic feedback preference

### SwiftData Model Conventions

When working with SwiftData models:
- Use `@Attribute(.unique)` for `id: UUID` fields
- Use `@Relationship(deleteRule: .cascade)` for parent-child relationships
- Use `@Relationship(inverse: \Child.parent)` to define bidirectional relationships
- Avoid circular inverse relationships (use one-directional when needed)
- JSON arrays stored as strings (see `AITrackingEvent.codeFilesChanged`)

### File Organization

```
CodingFlow/
├── Models/
│   └── Project.swift         # All models and enums in one file
├── ViewModels/
│   ├── IssuesViewModel.swift
│   ├── ProjectsViewModel.swift
│   ├── CyclesViewModel.swift
│   └── AIAssistantViewModel.swift
├── Views/
│   ├── Issues/
│   ├── Projects/
│   ├── Cycles/
│   ├── AI/
│   ├── Components/           # Reusable UI components
│   └── MainTabView.swift     # Includes SettingsView, AIUsageStatsView, etc.
├── CodingFlowApp.swift       # App entry point with schema definition
└── Assets.xcassets/
```

### Important Implementation Notes

1. **No CloudKit**: CloudKit is explicitly disabled (`cloudKitDatabase: .none`) to simplify sync logic
2. **Chinese Comments**: Code includes Chinese comments - preserve this convention when editing
3. **Observable vs ObservableObject**: Use `@Observable` macro (not `@Published` properties)
4. **Date Handling**: Use `Calendar.current.startOfDay(for:)` for date comparisons
5. **Natural Language Parsing**: `AIAssistantViewModel.createIssueFromNaturalLanguage(_:)` provides basic keyword detection for priority/type
