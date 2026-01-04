//
//  Debounce.swift
//  CodingFlow
//
//  防抖工具 - 用于延迟处理频繁变化的值
//  Debounce utility - For debouncing frequently changing values
//

import Foundation
import Combine

/// 防抖类 - 延迟处理值变化，直到值稳定一段时间
/// Debounce class - Delays processing of value changes until value stabilizes for a period
@MainActor
@Observable
final class DebounceObject<T: Equatable> {
    private var debounceTask: Task<Void, Never>?
    let delay: TimeInterval

    private var _value: T
    var value: T {
        _value
    }

    init(initialValue: T, delay: TimeInterval = 0.3) {
        self._value = initialValue
        self.delay = delay
    }

    /// 更新值，防抖处理
    /// Update value with debouncing
    func update(_ newValue: T) {
        _value = newValue

        // 取消之前的任务
        // Cancel previous task
        debounceTask?.cancel()

        // 创建新任务
        // Create new task
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            // 检查是否被取消
            // Check if cancelled
            if !Task.isCancelled {
                _value = newValue
            }
        }
    }

    /// 立即更新值，不防抖
    /// Update value immediately without debouncing
    func updateImmediately(_ newValue: T) {
        debounceTask?.cancel()
        _value = newValue
    }
}

/// SwiftUI 防抖文本字段包装器
/// SwiftUI debounced text field wrapper
struct DebouncedTextField: View {
    @Binding var text: String
    let prompt: Text
    let debouncedText: DebounceObject<String>

    init(
        text: Binding<String>,
        prompt: Text = Text(""),
        delay: TimeInterval = 0.3
    ) {
        self._text = text
        self.prompt = prompt
        self.debouncedText = DebounceObject(initialValue: text.wrappedValue, delay: delay)
    }

    var body: some View {
        TextField(
            "",
            text: Binding(
                get: { text },
                set: { newValue in
                    text = newValue
                    debouncedText.update(newValue)
                }
            ),
            prompt: prompt
        )
    }
}
