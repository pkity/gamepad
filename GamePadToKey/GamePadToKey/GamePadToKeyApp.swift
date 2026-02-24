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
    // 将私有属性改为 internal
    internal let inputProcessor = DualSenseInputProcessor()
    internal let partitionEngine = PartitionEngine()
    internal let outputSimulator = OutputSimulator()
    internal let feedbackController = DualSenseFeedbackController()
    internal let configManager = ConfigurationManager()
    internal let permissionManager = PermissionManager()
    
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置菜单栏图标
        setupMenuBar()
        
        // 检查并请求权限
        Task {
            await checkAndRequestPermissions()
        }
        
        // 加载默认配置
        loadDefaultConfiguration()
        
        // 启动输入处理
        setupInputProcessing()
        
        // 注册系统事件监听
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
        
        menu.addItem(NSMenuItem(title: "配置编辑器", action: #selector(openConfigEditor), keyEquivalent: "e"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "连接状态", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "当前分区", action: nil, keyEquivalent: ""))
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
    
    private func loadDefaultConfiguration() {
        do {
            // 尝试加载现有配置
            let configs = configManager.getAvailableConfigs()
            if configs.contains("完整默认配置") {
                let config = try configManager.loadConfiguration(named: "完整默认配置")
                partitionEngine.loadConfiguration(config)
                print("已加载完整默认配置")
                
                // 调试输出
                DebugTools.checkConfiguration(config)
            } else {
                // 创建完整默认配置
                try configManager.createDefaultConfigurationWithJoystickSupport()
                let config = try configManager.loadConfiguration(named: "完整默认配置")
                partitionEngine.loadConfiguration(config)
                print("已创建并加载完整默认配置")
                
                // 调试输出
                DebugTools.checkConfiguration(config)
            }
        } catch {
            print("加载配置失败: \(error)")
            // 创建最基本的配置
            createBasicConfiguration()
        }
    }
    
    private func createBasicConfiguration() {
        let config = Configuration.createCompleteDefault()
        do {
            try configManager.saveConfiguration(config)
            partitionEngine.loadConfiguration(config)
            print("已创建基本配置")
        } catch {
            print("创建基本配置失败: \(error)")
        }
    }
    
    private func setupInputProcessing() {
        inputProcessor.delegate = self
        
        // 添加调试
        DebugTools.checkInputProcessor(inputProcessor)
        
        do {
            try inputProcessor.startCapture()
        } catch {
            print("启动输入处理失败: \(error)")
        }
    }
    
    private func registerSystemEventListeners() {
        // 注册系统事件监听
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp]) { event in
            // 可以在这里添加系统事件处理
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
        // 打开配置编辑器窗口
        NSApp.sendAction(Selector(("showConfigEditorWindow:")), to: nil, from: nil)
    }
    
    @objc private func openSettings() {
        // 打开设置窗口
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}

extension AppDelegate: InputProcessorDelegate {
    func buttonStateChanged(name: String, pressed: Bool) {
        let event = InputEvent.buttonPress(button: name, pressed: pressed)
        partitionEngine.handleInput(event)
    }
    
    func joystickMoved(joystick: JoystickType, position: CGPoint) {
        let event = InputEvent.joystickMove(joystick: joystick, position: position)
        partitionEngine.handleInput(event)
    }
    
    func touchpadTouched(position: CGPoint, touching: Bool) {
        let event = InputEvent.touchpadTouch(position: position, touching: touching)
        partitionEngine.handleInput(event)
    }
    
    func motionUpdated(gyro: (x: Double, y: Double, z: Double), acceleration: (x: Double, y: Double, z: Double)) {
        let event = InputEvent.motion(gyro: gyro, acceleration: acceleration)
        partitionEngine.handleInput(event)
    }
}

