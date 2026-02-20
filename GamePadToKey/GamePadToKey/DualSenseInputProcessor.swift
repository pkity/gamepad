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
    
    public func startCapture() throws {
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
        
        // 查找已连接的手柄
        if let controller = GCController.controllers().first(where: { $0.productCategory == "DualSense" }) {
            setupController(controller)
        }
        
        // 开始处理循环
        startProcessingLoop()
    }
    
    public func stopCapture() {
        isProcessing = false
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func controllerDidConnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        if controller.productCategory == "DualSense" {
            setupController(controller)
        }
    }
    
    @objc private func controllerDidDisconnect(_ notification: Notification) {
        controller = nil
        dualSense = nil
        motion = nil
    }
    
    private func setupController(_ controller: GCController) {
        self.controller = controller
        self.dualSense = controller.physicalInputProfile as? GCDualSenseGamepad
        self.motion = controller.motion
        
        setupButtonHandlers()
        setupJoystickHandlers()
        setupTouchpadHandler()
        setupMotionHandler()
    }
    
    private func setupButtonHandlers() {
        guard let gamepad = dualSense else { return }
        
        let buttonMappings: [(String, GCControllerButtonInput?)] = [
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
            ("ps", gamepad.buttonMenu)
        ]
        
        for (name, button) in buttonMappings {
            guard let button = button else { continue }
            
            button.pressedChangedHandler = { [weak self] _, value, pressed in
                self?.processingQueue.async {
                    self?.delegate?.buttonStateChanged(name: name, pressed: pressed)
                }
            }
        }
    }
    
    private func setupJoystickHandlers() {
        guard let gamepad = dualSense else { return }
        
        gamepad.leftThumbstick.valueChangedHandler = { [weak self] _, xValue, yValue in
            self?.processingQueue.async {
                let position = CGPoint(x: Double(xValue), y: Double(yValue))
                self?.delegate?.joystickMoved(joystick: .left, position: position)
            }
        }
        
        gamepad.rightThumbstick.valueChangedHandler = { [weak self] _, xValue, yValue in
            self?.processingQueue.async {
                let position = CGPoint(x: Double(xValue), y: Double(yValue))
                self?.delegate?.joystickMoved(joystick: .right, position: position)
            }
        }
    }
    
    private func setupTouchpadHandler() {
        guard let gamepad = dualSense else { return }
        
        // 直接访问 touchpadPrimary，它不是可选类型
        // 但我们需要检查它是否真的支持触摸板功能
        gamepad.touchpadPrimary.valueChangedHandler = { [weak self] _, xValue, yValue in
            self?.processingQueue.async {
                let position = CGPoint(x: Double(xValue), y: Double(yValue))
                // 假设当有值时就是触摸状态
                let touching = xValue != 0 || yValue != 0
                self?.delegate?.touchpadTouched(position: position, touching: touching)
            }
        }
        
        // 直接访问 touchpadButton，它不是可选类型
        gamepad.touchpadButton.pressedChangedHandler = { [weak self] _, value, pressed in
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
        motion?.valueChangedHandler = { [weak self] motion in
            self?.processingQueue.async {
                let gyro = (x: motion.rotationRate.x, y: motion.rotationRate.y, z: motion.rotationRate.z)
                let acceleration = (x: motion.userAcceleration.x, y: motion.userAcceleration.y, z: motion.userAcceleration.z)
                self?.delegate?.motionUpdated(gyro: gyro, acceleration: acceleration)
            }
        }
    }
    
    private func startProcessingLoop() {
        isProcessing = true
        processingQueue.async { [weak self] in
            self?.processingLoop()
        }
    }
    
    private func processingLoop() {
        while isProcessing {
            // 这里可以添加额外的轮询逻辑
            // 例如检查死区、滤波等
            
            Thread.sleep(forTimeInterval: 0.01) // 100Hz
        }
    }
}
