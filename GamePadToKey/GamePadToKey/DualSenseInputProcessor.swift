//
//  DualSenseInputProcessor.swift
//  GamePadToKey
//

import Foundation
import GameController
import CoreGraphics

public protocol InputProcessorDelegate: AnyObject {
    func buttonStateChanged(name: String, pressed: Bool)
    func joystickMoved(joystick: JoystickType, position: CGPoint)
    func touchpadTouched(position: CGPoint, touching: Bool)
    func motionUpdated(gyro: (x: Double, y: Double, z: Double),
                      acceleration: (x: Double, y: Double, z: Double))
}

public class DualSenseInputProcessor {
    public weak var delegate: InputProcessorDelegate?
    
    private var controller: GCController?
    private var dualSense: GCDualSenseGamepad?
    private var motion: GCMotion?
    
    private let processingQueue = DispatchQueue(label: "com.gamepadtokey.input", qos: .userInteractive)
    private var isProcessing = false
    
    private var lastButtonState: [String: Bool] = [:]
    private var lastLeftJoystickState: CGPoint = .zero
    private var lastRightJoystickState: CGPoint = .zero
    
    private let deadzone: Double = 0.15
    private let motionSensitivity: Double = 1.0
    
    private var lastTouchpadPosition: CGPoint?
    private var isTouchpadTouching = false
    
    // 添加调试日志
    private let enableDebugLogging = true
    
    public init() {
        // 初始化时监听手柄连接
        setupControllerObservers()
    }
    
    public func startCapture() throws {
        debugLog("开始捕获输入")
        
        // 查找已连接的手柄
        let controllers = GCController.controllers()
        debugLog("找到 \(controllers.count) 个控制器")
        
        for controller in controllers {
            debugLog("控制器: \(controller.vendorName ?? "未知"), 类别: \(controller.productCategory ?? "未知")")
        }
        
        if let controller = controllers.first(where: { isDualSenseController($0) }) {
            debugLog("找到 DualSense 控制器: \(controller.vendorName ?? "未知")")
            setupController(controller)
        } else {
            debugLog("未找到已连接的 DualSense 手柄")
            // 尝试等待手柄连接
            debugLog("等待手柄连接...")
        }
        
        // 开始处理循环
        startProcessingLoop()
    }
    
    public func stopCapture() {
        debugLog("停止捕获输入")
        isProcessing = false
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupControllerObservers() {
        debugLog("设置控制器观察者")
        
        // 监听手柄连接
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidConnect),
            name: .GCControllerDidConnect,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidDisconnect),
            name: .GCControllerDidDisconnect,
            object: nil
        )
    }
    
    @objc private func controllerDidConnect(_ notification: Notification) {
        debugLog("手柄连接通知")
        guard let controller = notification.object as? GCController else {
            debugLog("无法获取控制器对象")
            return
        }
        
        debugLog("新控制器连接: \(controller.vendorName ?? "未知"), 类别: \(controller.productCategory ?? "未知")")
        
        if isDualSenseController(controller) {
            debugLog("检测到 DualSense 手柄连接")
            setupController(controller)
        } else {
            debugLog("连接的手柄不是 DualSense")
        }
    }
    
    @objc private func controllerDidDisconnect(_ notification: Notification) {
        debugLog("手柄断开连接")
        controller = nil
        dualSense = nil
        motion = nil
        lastButtonState.removeAll()
        
        // 通知代理连接状态变化
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.buttonStateChanged(name: "connection", pressed: false)
        }
    }
    
    private func isDualSenseController(_ controller: GCController) -> Bool {
        // 检查是否是 DualSense 手柄
        let category = controller.productCategory ?? ""
        let vendorName = controller.vendorName ?? ""
        
        debugLog("检查控制器: 类别=\(category), 厂商=\(vendorName)")
        
        // DualSense 可能被识别为不同的名称
        return category.contains("DualSense") || 
               category.contains("PS5") || 
               vendorName.contains("DualSense") ||
               vendorName.contains("PlayStation") ||
               category.contains("Wireless Controller")
    }
    
    private func setupController(_ controller: GCController) {
        debugLog("设置控制器: \(controller.vendorName ?? "未知")")
        self.controller = controller
        
        // 获取物理输入配置
        let physicalInput = controller.physicalInputProfile
        
        // 尝试转换为 GCDualSenseGamepad
        if let dualSenseInput = physicalInput as? GCDualSenseGamepad {
            self.dualSense = dualSenseInput
            debugLog("成功获取 DualSense 游戏手柄")
            
            // 设置输入处理器
            setupInputHandlers()
        } else {
            debugLog("无法转换为 GCDualSenseGamepad，实际类型: \(type(of: physicalInput))")
            // 延迟设置，等待配置就绪
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                let updatedPhysicalInput = controller.physicalInputProfile
                self?.debugLog("延迟获取物理输入配置类型: \(type(of: updatedPhysicalInput))")
                
                if let dualSenseInput = updatedPhysicalInput as? GCDualSenseGamepad {
                    self?.dualSense = dualSenseInput
                    self?.debugLog("延迟成功获取 DualSense 游戏手柄")
                    self?.setupInputHandlers()
                }
            }
        }
        
        self.motion = controller.motion
    }
    
    private func setupInputHandlers() {
        guard let gamepad = dualSense else {
            debugLog("无法获取 DualSense 游戏手柄")
            return
        }
        
        debugLog("开始设置输入处理器")
        
        setupButtonHandlers(gamepad)
        setupJoystickHandlers(gamepad)
        setupTouchpadHandler(gamepad)
        setupMotionHandler()
        
        debugLog("输入处理器设置完成")
        
        // 通知代理连接成功
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.buttonStateChanged(name: "connection", pressed: true)
        }
    }
    
    private func setupButtonHandlers(_ gamepad: GCDualSenseGamepad) {
        debugLog("设置按钮处理器")
        
        // 定义按钮映射 - GCDualSenseGamepad 使用 buttonA/B/X/Y 而不是 buttonTriangle/Circle/Cross/Square
        let buttonMappings: [(String, GCControllerButtonInput?)] = [
            ("triangle", gamepad.buttonA),      // △ 按钮对应 buttonA
            ("circle", gamepad.buttonB),        // ○ 按钮对应 buttonB
            ("cross", gamepad.buttonX),         // × 按钮对应 buttonX
            ("square", gamepad.buttonY),        // □ 按钮对应 buttonY
            ("L1", gamepad.leftShoulder),
            ("R1", gamepad.rightShoulder),
            ("L2", gamepad.leftTrigger),
            ("R2", gamepad.rightTrigger),
            ("L3", gamepad.leftThumbstickButton),
            ("R3", gamepad.rightThumbstickButton),
            ("up", gamepad.dpad.up),
            ("down", gamepad.dpad.down),
            ("left", gamepad.dpad.left),
            ("right", gamepad.dpad.right),
            ("touchpad", gamepad.touchpadButton),
            ("ps", gamepad.buttonOptions)       // PS 按钮
        ]
        
        for (name, button) in buttonMappings {
            guard let button = button else {
                debugLog("按钮 \(name) 不可用")
                continue
            }
            
            debugLog("设置按钮 \(name) 处理器")
            
            // 使用 valueChangedHandler 处理按钮事件
            button.valueChangedHandler = { [weak self] _, value, pressed in
                self?.debugLog("按钮 \(name) 事件: pressed=\(pressed), value=\(value)")
                self?.processingQueue.async {
                    self?.handleButtonEvent(name: name, pressed: pressed, value: value)
                }
            }
        }
    }
    
    private func handleButtonEvent(name: String, pressed: Bool, value: Float) {
        // 检查状态是否变化
        if lastButtonState[name] != pressed {
            debugLog("按钮 \(name) 状态变化: \(pressed ? "按下" : "释放"), 值: \(value)")
            lastButtonState[name] = pressed
            
            // 通知代理
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.buttonStateChanged(name: name, pressed: pressed)
            }
        }
    }
    
    private func setupJoystickHandlers(_ gamepad: GCDualSenseGamepad) {
        debugLog("设置摇杆处理器")
        
        gamepad.leftThumbstick.valueChangedHandler = { [weak self] _, xValue, yValue in
            self?.debugLog("左摇杆: x=\(xValue), y=\(yValue)")
            self?.processingQueue.async {
                let position = CGPoint(x: Double(xValue), y: Double(yValue))
                
                // 应用死区
                let magnitude = sqrt(pow(position.x, 2) + pow(position.y, 2))
                if magnitude < self?.deadzone ?? 0.15 {
                    // 在死区内，发送零位置
                    self?.delegate?.joystickMoved(joystick: .left, position: .zero)
                } else {
                    self?.delegate?.joystickMoved(joystick: .left, position: position)
                }
            }
        }
        
        gamepad.rightThumbstick.valueChangedHandler = { [weak self] _, xValue, yValue in
            self?.debugLog("右摇杆: x=\(xValue), y=\(yValue)")
            self?.processingQueue.async {
                let position = CGPoint(x: Double(xValue), y: Double(yValue))
                
                // 应用死区
                let magnitude = sqrt(pow(position.x, 2) + pow(position.y, 2))
                if magnitude < self?.deadzone ?? 0.15 {
                    // 在死区内，发送零位置
                    self?.delegate?.joystickMoved(joystick: .right, position: .zero)
                } else {
                    self?.delegate?.joystickMoved(joystick: .right, position: position)
                }
            }
        }
    }
    
    private func setupTouchpadHandler(_ gamepad: GCDualSenseGamepad) {
        debugLog("设置触摸板处理器")
        
        // 检查触摸板是否可用
        if gamepad.touchpadPrimary != nil {
            gamepad.touchpadPrimary.valueChangedHandler = { [weak self] _, xValue, yValue in
                self?.debugLog("触摸板: x=\(xValue), y=\(yValue)")
                self?.processingQueue.async {
                    let position = CGPoint(x: Double(xValue), y: Double(yValue))
                    // 假设当有值时就是触摸状态
                    let touching = xValue != 0 || yValue != 0
                    self?.delegate?.touchpadTouched(position: position, touching: touching)
                }
            }
        } else {
            debugLog("触摸板不可用")
        }
        
        // 触摸板按钮
        gamepad.touchpadButton.valueChangedHandler = { [weak self] _, value, pressed in
            self?.debugLog("触摸板按钮: \(pressed ? "按下" : "释放")")
            self?.processingQueue.async {
                // 触摸板按钮按下时发送触摸事件
                if pressed {
                    self?.delegate?.touchpadTouched(position: CGPoint(x: 0.5, y: 0.5), touching: true)
                } else {
                    self?.delegate?.touchpadTouched(position: CGPoint(x: 0.5, y: 0.5), touching: false)
                }
            }
        }
    }
    
    private func setupMotionHandler() {
        guard let motion = motion else {
            debugLog("运动传感器不可用")
            return
        }
        
        debugLog("设置运动处理器")
        
        motion.valueChangedHandler = { [weak self] motion in
            self?.processingQueue.async {
                let gyro = (x: Double(motion.rotationRate.x), 
                           y: Double(motion.rotationRate.y), 
                           z: Double(motion.rotationRate.z))
                let acceleration = (x: Double(motion.userAcceleration.x), 
                                   y: Double(motion.userAcceleration.y), 
                                   z: Double(motion.userAcceleration.z))
                self?.delegate?.motionUpdated(gyro: gyro, acceleration: acceleration)
            }
        }
    }
    
    private func startProcessingLoop() {
        guard !isProcessing else { return }
        
        isProcessing = true
        processingQueue.async { [weak self] in
            self?.processingLoop()
        }
    }
    
    private func processingLoop() {
        while isProcessing {
            // 定期检查按钮状态（轮询作为备用方案）
            checkButtonStates()
            
            Thread.sleep(forTimeInterval: 0.016) // ~60Hz
        }
    }
    
    private func checkButtonStates() {
        guard let gamepad = dualSense else { return }
        
        // 检查所有按钮的当前状态
        let buttons: [(String, GCControllerButtonInput?)] = [
            ("triangle", gamepad.buttonA),
            ("circle", gamepad.buttonB),
            ("cross", gamepad.buttonX),
            ("square", gamepad.buttonY),
            ("L1", gamepad.leftShoulder),
            ("R1", gamepad.rightShoulder),
            ("L2", gamepad.leftTrigger),
            ("R2", gamepad.rightTrigger),
            ("L3", gamepad.leftThumbstickButton),
            ("R3", gamepad.rightThumbstickButton),
            ("up", gamepad.dpad.up),
            ("down", gamepad.dpad.down),
            ("left", gamepad.dpad.left),
            ("right", gamepad.dpad.right),
            ("touchpad", gamepad.touchpadButton),
            ("ps", gamepad.buttonOptions)
        ]
        
        for (name, button) in buttons {
            guard let button = button else { continue }
            
            let currentPressed = button.isPressed
            if lastButtonState[name] != currentPressed {
                debugLog("轮询检测到按钮 \(name) 状态变化: \(currentPressed ? "按下" : "释放")")
                lastButtonState[name] = currentPressed
                
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.buttonStateChanged(name: name, pressed: currentPressed)
                }
            }
        }
    }
    
    private func debugLog(_ message: String) {
        if enableDebugLogging {
            print("[DualSenseInputProcessor] \(message)")
        }
    }
    
    // 添加公共方法检查连接状态
    public var isConnected: Bool {
        return dualSense != nil
    }
    
    public var controllerName: String? {
        return controller?.vendorName
    }
    
    deinit {
        stopCapture()
    }
}
