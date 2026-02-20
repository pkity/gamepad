//
//  PartitionEngine.swift
//  GamePadToKey
//

import Foundation
import CoreGraphics
import AppKit // 添加 AppKit 导入

public class PartitionEngine {
    private var rootPartition: PartitionNode?
    private var currentPartition: PartitionNode?
    private var navigationStack: [PartitionNode] = []
    
    private var pressedButtons: Set<String> = []
    private var activationTimer: Timer?
    
    private let lookupTable = PartitionLookupTable()
    private let outputSimulator = OutputSimulator()
    private let feedbackController = DualSenseFeedbackController()
    
    private var isProcessing = false
    private let processingQueue = DispatchQueue(label: "com.gamepadtokey.partition", qos: .userInteractive)
    
    public func loadConfiguration(_ config: Configuration) {
        processingQueue.async { [weak self] in
            self?.rootPartition = config.rootPartition
            self?.currentPartition = config.rootPartition
            if let rootPartition = config.rootPartition {
                self?.lookupTable.buildIndex(from: rootPartition)
            }
        }
    }
    
    public func handleInput(_ event: InputEvent) {
        processingQueue.async { [weak self] in
            self?.processInput(event)
        }
    }
    
    private func processInput(_ event: InputEvent) {
        switch event {
        case .buttonPress(let button, let pressed):
            handleButtonPress(button, pressed: pressed)
        case .joystickMove(let joystick, let position):
            handleJoystickMove(joystick, position: position)
        case .touchpadTouch(let position, let touching):
            handleTouchpadTouch(position, touching: touching)
        case .motion(let gyro, let acceleration):
            handleMotion(gyro, acceleration: acceleration)
        }
    }
    
    private func handleButtonPress(_ button: String, pressed: Bool) {
        if pressed {
            pressedButtons.insert(button)
            
            // 检查激活组合
            if let partition = lookupTable.findPartition(for: pressedButtons) {
                activatePartition(partition)
            } else {
                // 在当前分区中查找映射
                if let mapping = currentPartition?.findMapping(for: button) {
                    executeMapping(mapping)
                }
            }
        } else {
            pressedButtons.remove(button)
            
            // 检查是否需要退出分区
            if pressedButtons.isEmpty && !isSamePartition(currentPartition, rootPartition) {
                // 启动退出计时器
                startExitTimer()
            } else {
                activationTimer?.invalidate()
            }
        }
    }
    
    private func isSamePartition(_ p1: PartitionNode?, _ p2: PartitionNode?) -> Bool {
        // 比较分区ID来判断是否相同
        return p1?.id == p2?.id
    }
    
    private func handleJoystickMove(_ joystick: JoystickType, position: CGPoint) {
        // 检查死区
        let magnitude = sqrt(position.x * position.x + position.y * position.y)
        guard magnitude > 0.15 else { return }
        
        // 在当前分区中查找摇杆映射
        if let mapping = currentPartition?.findJoystickMapping(for: joystick) {
            executeJoystickMapping(mapping, position: position)
        }
    }
    
    private func handleTouchpadTouch(_ position: CGPoint, touching: Bool) {
        if touching {
            // 处理触摸板触摸
            if let mapping = currentPartition?.findTouchpadMapping() {
                executeTouchpadMapping(mapping, position: position)
            }
        }
    }
    
    private func handleMotion(_ gyro: (x: Double, y: Double, z: Double), acceleration: (x: Double, y: Double, z: Double)) {
        // 处理陀螺仪数据
        if let mapping = currentPartition?.findMotionMapping() {
            executeMotionMapping(mapping, gyro: gyro, acceleration: acceleration)
        }
    }
    
    private func activatePartition(_ partition: PartitionNode) {
        // 清除激活计时器
        activationTimer?.invalidate()
        
        // 更新当前分区
        if let current = currentPartition {
            navigationStack.append(current)
        }
        currentPartition = partition
        
        // 发送激活反馈
        if let feedback = partition.feedback {
            feedbackController.applyFeedback(Feedback(
                vibration: .light,
                ledColor: (r: 0.0, g: 1.0, b: 0.0),
                ledPattern: .pulse
            ))
        }
        
        // 发送通知
        NotificationCenter.default.post(
            name: NSNotification.Name("partitionActivated"),
            object: partition
        )
        
        // 重置按下的按钮
        pressedButtons.removeAll()
    }
    
    private func navigateBack() {
        guard !navigationStack.isEmpty else { return }
        
        let previousPartition = navigationStack.removeLast()
        currentPartition = previousPartition
        
        // 发送导航反馈
        feedbackController.playNavigationFeedback()
        
        NotificationCenter.default.post(
            name: NSNotification.Name("partitionNavigated"),
            object: previousPartition
        )
    }
    
    private func startExitTimer() {
        activationTimer?.invalidate()
        activationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.navigateBack()
        }
    }
    
    private func executeMapping(_ mapping: Mapping) {
        switch mapping.action {
        case .keyPress(let key, let modifiers):
            outputSimulator.simulateKeyPress(key: key, modifiers: modifiers)
        case .keyCombo(let keys):
            outputSimulator.simulateKeyCombo(keys: keys)
        case .mouseMove(let sensitivity, let acceleration):
            // 摇杆映射会单独处理
            break
        case .mouseClick(let button, let mode):
            outputSimulator.simulateMouseClick(button: button, clickCount: 1)
        case .mouseScroll(let axis, let sensitivity):
            // 滚动映射
            break
        case .macro(let id):
            // 执行宏
            executeMacro(id)
        }
    }
    
    private func executeJoystickMapping(_ mapping: Mapping, position: CGPoint) {
        switch mapping.action {
        case .mouseMove(let sensitivity, let acceleration):
            // 计算鼠标移动
            let deltaX = position.x * sensitivity
            let deltaY = position.y * sensitivity
            outputSimulator.simulateMouseMove(deltaX: deltaX, deltaY: deltaY, sensitivity: 1.0)
        case .mouseScroll(let axis, let sensitivity):
            // 计算滚动
            let scrollX = axis == .horizontal ? position.x * sensitivity : 0
            let scrollY = axis == .vertical ? position.y * sensitivity : 0
            outputSimulator.simulateMouseScroll(deltaY: scrollY, deltaX: scrollX)
        default:
            break
        }
    }
    
    private func executeTouchpadMapping(_ mapping: Mapping, position: CGPoint) {
        switch mapping.action {
        case .mouseMove(let sensitivity, let acceleration):
            // 触摸板绝对位置映射
            let screenFrame = NSScreen.main?.frame ?? .zero
            let screenX = position.x * screenFrame.width
            let screenY = (1 - position.y) * screenFrame.height // 翻转Y轴
            
            // 使用 OutputSimulator 移动鼠标
            outputSimulator.simulateMouseMove(
                deltaX: screenX - (NSEvent.mouseLocation.x),
                deltaY: (NSEvent.mouseLocation.y) - screenY, // 注意Y轴方向
                sensitivity: 1.0
            )
        default:
            break
        }
    }
    
    private func executeMotionMapping(_ mapping: Mapping, gyro: (x: Double, y: Double, z: Double), acceleration: (x: Double, y: Double, z: Double)) {
        switch mapping.action {
        case .mouseMove(let sensitivity, let accelerationEnabled):
            if accelerationEnabled {
                // 使用加速度计控制鼠标
                let deltaX = acceleration.x * sensitivity
                let deltaY = acceleration.y * sensitivity
                outputSimulator.simulateMouseMove(deltaX: deltaX, deltaY: deltaY, sensitivity: 1.0)
            } else {
                // 使用陀螺仪控制鼠标
                let deltaX = gyro.z * sensitivity // 使用Z轴旋转
                let deltaY = gyro.x * sensitivity // 使用X轴旋转
                outputSimulator.simulateMouseMove(deltaX: deltaX, deltaY: deltaY, sensitivity: 1.0)
            }
        default:
            break
        }
    }
    
    private func executeMacro(_ id: String) {
        // 执行宏命令
        print("执行宏: \(id)")
        // 这里需要实现宏执行逻辑
    }
}
