//
//  ViewState.swift
//  CodingFlow
//
//  统一视图状态管理 - 用于 ViewModel
//  Unified view state management for ViewModels
//

import Foundation

/// 视图状态枚举，统一管理加载、成功、错误状态
/// View state enum for unified loading, success, and error state management
enum ViewState<T> {
    case idle
    case loading
    case success(T)
    case error(Error)

    /// 获取成功状态下的数据 (Get data from success state)
    var data: T? {
        if case .success(let data) = self {
            return data
        }
        return nil
    }

    /// 获取错误状态下的错误 (Get error from error state)
    var error: Error? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }

    /// 是否正在加载 (Is loading)
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    /// 是否成功 (Is success)
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    /// 是否错误 (Is error)
    var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }

    /// 是否闲置 (Is idle)
    var isIdle: Bool {
        if case .idle = self {
            return true
        }
        return false
    }
}
