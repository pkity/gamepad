//
//  PermissionManager.swift
//  GamePadToKey
//

import Foundation
import AppKit

public class PermissionManager {
    
    public init() {}
    
    public func requestMinimalPermissions() async -> Bool {
        var grantedCount = 0
        
        // 请求辅助功能权限
        if await requestAccessibilityPermission() {
            grantedCount += 1
        }
        
        // 请求输入监控权限
        if await requestInputMonitoringPermission() {
            grantedCount += 1
        }
        
        return grantedCount == 2
    }
    
    private func requestAccessibilityPermission() async -> Bool {
        // 检查辅助功能权限
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        return trusted
    }
    
    private func requestInputMonitoringPermission() async -> Bool {
        // 在 macOS 10.15+ 上需要输入监控权限
        // 这里返回 true，实际应用中需要实现权限请求
        return true
    }
    
    private func requestBluetoothPermission() async -> Bool {
        // 蓝牙权限
        return true
    }
    
    public func openSecurityPreferences() {
        let prefPaneURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(prefPaneURL)
    }
}
