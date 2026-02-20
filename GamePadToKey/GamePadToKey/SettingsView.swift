//
//  SettingsView.swift
//  GamePadToKey
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("mouseSensitivity") private var mouseSensitivity = 1.0
    @AppStorage("deadzone") private var deadzone = 0.15
    @AppStorage("vibrationEnabled") private var vibrationEnabled = true
    @AppStorage("ledFeedback") private var ledFeedback = true
    @AppStorage("autoStart") private var autoStart = false
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
            
            InputSettingsView()
                .tabItem {
                    Label("输入", systemImage: "gamecontroller")
                }
            
            FeedbackSettingsView()
                .tabItem {
                    Label("反馈", systemImage: "waveform")
                }
            
            AdvancedSettingsView()
                .tabItem {
                    Label("高级", systemImage: "hammer")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("autoStart") private var autoStart = false
    @AppStorage("startMinimized") private var startMinimized = false
    @AppStorage("checkForUpdates") private var checkForUpdates = true
    
    var body: some View {
        Form {
            Toggle("开机自启动", isOn: $autoStart)
            Toggle("启动时最小化", isOn: $startMinimized)
            Toggle("自动检查更新", isOn: $checkForUpdates)
            
            Divider()
            
            Button("打开系统权限设置") {
                PermissionManager().openSecurityPreferences()
            }
        }
        .padding()
    }
}

struct InputSettingsView: View {
    @AppStorage("mouseSensitivity") private var mouseSensitivity = 1.0
    @AppStorage("deadzone") private var deadzone = 0.15
    @AppStorage("scrollSensitivity") private var scrollSensitivity = 1.0
    
    var body: some View {
        Form {
            VStack(alignment: .leading) {
                Text("鼠标灵敏度: \(mouseSensitivity, specifier: "%.2f")")
                Slider(value: $mouseSensitivity, in: 0.1...3.0, step: 0.1)
            }
            
            VStack(alignment: .leading) {
                Text("摇杆死区: \(deadzone, specifier: "%.2f")")
                Slider(value: $deadzone, in: 0.0...0.5, step: 0.05)
            }
            
            VStack(alignment: .leading) {
                Text("滚动灵敏度: \(scrollSensitivity, specifier: "%.2f")")
                Slider(value: $scrollSensitivity, in: 0.1...3.0, step: 0.1)
            }
        }
        .padding()
    }
}

struct FeedbackSettingsView: View {
    @AppStorage("vibrationEnabled") private var vibrationEnabled = true
    @AppStorage("ledFeedback") private var ledFeedback = true
    @AppStorage("triggerFeedback") private var triggerFeedback = true
    @AppStorage("audioFeedback") private var audioFeedback = false
    
    var body: some View {
        Form {
            Toggle("启用振动反馈", isOn: $vibrationEnabled)
            Toggle("启用LED反馈", isOn: $ledFeedback)
            Toggle("启用扳机反馈", isOn: $triggerFeedback)
            Toggle("启用音频反馈", isOn: $audioFeedback)
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("振动强度")
                Slider(value: .constant(0.5), in: 0.0...1.0)
            }
        }
        .padding()
    }
}

struct AdvancedSettingsView: View {
    @AppStorage("debugLogging") private var debugLogging = false
    @AppStorage("performanceMode") private var performanceMode = false
    @AppStorage("inputLatency") private var inputLatency = 10.0
    
    var body: some View {
        Form {
            Toggle("调试日志", isOn: $debugLogging)
            Toggle("性能模式", isOn: $performanceMode)
            
            VStack(alignment: .leading) {
                Text("输入延迟目标: \(Int(inputLatency))ms")
                Slider(value: $inputLatency, in: 5...50, step: 5)
            }
            
            Divider()
            
            Button("重置所有设置") {
                resetAllSettings()
            }
            .foregroundColor(.red)
        }
        .padding()
    }
    
    private func resetAllSettings() {
        // 重置所有设置
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }
}
