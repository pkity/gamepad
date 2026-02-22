//
//  ContentViewModel.swift
//  GamePadToKey
//

import Foundation
import SwiftUI
import Combine
import GameController

class ContentViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var statusMessage = "等待手柄连接..."
    @Published var currentPartition: String?
    @Published var batteryLevel: Double = 0
    @Published var isCharging = false
    @Published var pressedButtons: Set<String> = []
    @Published var joystickPositions: [String: CGPoint] = [:]
    @Published var showConfigEditor = false // 新增：控制配置编辑器显示
    @Published var newConfigName = "" // 新增：新配置名称
    @Published var showNewConfigDialog = false // 新增：显示新建配置对话框
    
    private var cancellables = Set<AnyCancellable>()
    private let inputProcessor = DualSenseInputProcessor()
    private let partitionEngine = PartitionEngine()
    private let configManager = ConfigurationManager()
    
    init() {
        setupObservers()
        setupInputProcessor()
    }
    
    func startMonitoring() {
        do {
            try inputProcessor.startCapture()
            statusMessage = "监控已启动"
        } catch {
            statusMessage = "启动监控失败: \(error.localizedDescription)"
        }
    }
    
    func stopMonitoring() {
        inputProcessor.stopCapture()
        statusMessage = "监控已停止"
    }
    
    func createNewConfig() {
        // 显示新建配置对话框
        showNewConfigDialog = true
        newConfigName = ""
    }
    
    func createNewConfigWithName() {
        guard !newConfigName.isEmpty else {
            statusMessage = "配置名称不能为空"
            return
        }
        
        // 创建新配置
        let newConfig = Configuration.createDefault()
        let updatedConfig = Configuration(
            configVersion: newConfig.configVersion,
            name: newConfigName,
            author: "用户",
            description: "新建的配置",
            globalSettings: newConfig.globalSettings,
            keyboardLayout: newConfig.keyboardLayout,
            partitions: newConfig.partitions
        )
        
        do {
            try configManager.saveConfiguration(updatedConfig)
            statusMessage = "已创建新配置: \(newConfigName)"
            
            // 加载新配置
            loadConfig(newConfigName)
            
            // 关闭对话框
            showNewConfigDialog = false
            
            // 显示成功消息
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.statusMessage = "已切换到配置: \(self.newConfigName)"
            }
        } catch {
            statusMessage = "创建配置失败: \(error.localizedDescription)"
        }
    }
    
    func loadConfig(_ name: String) {
        do {
            let config = try configManager.loadConfiguration(named: name)
            partitionEngine.loadConfiguration(config)
            statusMessage = "已加载配置: \(name)"
            
            // 更新当前分区显示
            if let rootPartition = config.rootPartition {
                currentPartition = rootPartition.name
            }
        } catch {
            statusMessage = "加载配置失败: \(error.localizedDescription)"
        }
    }
    
    private func setupObservers() {
        // 监听分区激活
        NotificationCenter.default.publisher(for: NSNotification.Name("partitionActivated"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let partition = notification.object as? PartitionNode {
                    self?.currentPartition = partition.name
                }
            }
            .store(in: &cancellables)
        
        // 监听分区导航
        NotificationCenter.default.publisher(for: NSNotification.Name("partitionNavigated"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let partition = notification.object as? PartitionNode {
                    self?.currentPartition = partition.name
                }
            }
            .store(in: &cancellables)
        
        // 监听手柄连接状态
        NotificationCenter.default.publisher(for: .GCControllerDidConnect)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isConnected = true
                self?.statusMessage = "手柄已连接"
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .GCControllerDidDisconnect)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isConnected = false
                self?.statusMessage = "手柄已断开"
            }
            .store(in: &cancellables)
    }
    
    private func setupInputProcessor() {
        inputProcessor.delegate = self
    }
}

extension ContentViewModel: InputProcessorDelegate {
    func buttonStateChanged(name: String, pressed: Bool) {
        DispatchQueue.main.async {
            if pressed {
                self.pressedButtons.insert(name)
            } else {
                self.pressedButtons.remove(name)
            }
            
            // 创建输入事件
            let event = InputEvent.buttonPress(button: name, pressed: pressed)
            self.partitionEngine.handleInput(event)
        }
    }
    
    func joystickMoved(joystick: JoystickType, position: CGPoint) {
        DispatchQueue.main.async {
            let key = joystick == .left ? "leftJoystick" : "rightJoystick"
            self.joystickPositions[key] = position
            
            // 创建输入事件
            let event = InputEvent.joystickMove(joystick: joystick, position: position)
            self.partitionEngine.handleInput(event)
        }
    }
    
    func touchpadTouched(position: CGPoint, touching: Bool) {
        DispatchQueue.main.async {
            // 创建输入事件
            let event = InputEvent.touchpadTouch(position: position, touching: touching)
            self.partitionEngine.handleInput(event)
        }
    }
    
    func motionUpdated(gyro: (x: Double, y: Double, z: Double), acceleration: (x: Double, y: Double, z: Double)) {
        DispatchQueue.main.async {
            // 创建输入事件
            let event = InputEvent.motion(gyro: gyro, acceleration: acceleration)
            self.partitionEngine.handleInput(event)
        }
    }
}
