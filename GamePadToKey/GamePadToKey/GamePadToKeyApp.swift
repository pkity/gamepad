//
//  GamePadToKeyApp.swift
//  GamePadToKey
//

import SwiftUI

@main
struct GamePadToKeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    internal let inputProcessor = DualSenseInputProcessor()
    internal let outputSimulator = OutputSimulator()
    internal let feedbackController = DualSenseFeedbackController()
    internal let permissionManager = PermissionManager()
    
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        
        Task {
            await checkAndRequestPermissions()
        }
        
        setupInputProcessing()
        registerSystemEventListeners()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        inputProcessor.stopCapture()
        outputSimulator.cleanup()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "gamecontroller", accessibilityDescription: "GamePadToKey")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "连接状态", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "设置", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func checkAndRequestPermissions() async {
        let permissionsGranted = await permissionManager.requestMinimalPermissions()
        if !permissionsGranted {
            DispatchQueue.main.async {
                self.showPermissionAlert()
            }
        }
    }
    
    private func setupInputProcessing() {
        // 不再设置 delegate，避免类型不匹配
        do {
            try inputProcessor.startCapture()
        } catch {
            print("启动输入处理失败: \(error)")
        }
    }
    
    private func registerSystemEventListeners() {
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp]) { event in
            // 可在此处处理系统事件
        }
    }
    
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "需要权限"
        alert.informativeText = "GamePadToKey 需要辅助功能和输入监控权限才能正常工作。请在系统偏好设置中授予权限。"
        alert.addButton(withTitle: "打开系统偏好设置")
        alert.addButton(withTitle: "稍后")
        
        if alert.runModal() == .alertFirstButtonReturn {
            permissionManager.openSecurityPreferences()
        }
    }
    
    @objc private func openConfigEditor() {
        NSApp.sendAction(Selector(("showConfigEditorWindow:")), to: nil, from: nil)
    }
    
    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
