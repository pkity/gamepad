//
//  GameController.swift
//  NanoBrowser
//
//  Created by 苹果 on 2025/4/4.
//

import Foundation
import GameController
import CoreHaptics
import UIKit
import OSLog

extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // 获取颜色分量
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red, green, blue, alpha)
    }
}

class GameControllerManager: ObservableObject {
    @Published var dualSenseController: GCController?
    @Published var buttonStates: [String: Bool] = [:]
    @Published var leftThumbstick: (x: Float, y: Float) = (0.0, 0.0)
    @Published var rightThumbstick: (x: Float, y: Float) = (0.0, 0.0)
    @Published var leftTrigger: Float = 0.0
    @Published var rightTrigger: Float = 0.0
    private static var hapticsTimes: Int? = 0
    let ahapFiles = [
        "AHAP/Hit",
        "AHAP/Hit",
        "AHAP/Hit",
        "AHAP/Hit",
        "AHAP/Triple",
        "AHAP/Rumble",
        "AHAP/Recharge",
        "AHAP/Heartbeats"
    ]
    let ahapLocalities = [
        GCHapticsLocality.default,
        GCHapticsLocality.all,
        GCHapticsLocality.leftHandle,
        GCHapticsLocality.rightHandle,
        GCHapticsLocality.default,
        GCHapticsLocality.default,
        GCHapticsLocality.default,
        GCHapticsLocality.default
    ]
    
    // A haptic engine manages the connection to the haptic server.
    private var engineMap = [GCHapticsLocality: CHHapticEngine]()

    init() {
        setupControllerObservers()
    }

    private func setupControllerObservers() {
        print("GameControllerManager::setupControllerObservers")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidConnect(_:)),
            name: .GCControllerDidConnect,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidDisconnect(_:)),
            name: .GCControllerDidDisconnect,
            object: nil
        )
    }
    
    @objc private func controllerDidConnect(_ notification: Notification) {
        print("GameControllerManager::controllerDidConnect")
        guard let controller = notification.object as? GCController else { return }
    
        print("Connected \(controller.productCategory) game controller.")

        // Configure the event handlers for the controller buttons.
        self.dualSenseController = controller
        setupController(controller)
    }

    @objc private func controllerDidDisconnect(_ notification: Notification) {
        print("GameControllerManager::controllerDidDisconnect")
        self.dualSenseController = nil
    }
    
    private func setupController(_ controller: GCController) {
        print("GameControllerManager::setupController")
        if controller.productCategory == "DualSense" {
            dualSenseController = controller
            print("GameControllerManager::DualSense connected!")
            setupInputHandling()
            batteryStateChanged()
            startBreathingEffect()
        }
    }

    private func setupInputHandling() {
        print("GameControllerManager::setupInputHandling")
        
        if GCController.shouldMonitorBackgroundEvents {
            print("the app needs to respond to controller events when it isn’t the frontmost app.")
        } else {
            print("the app needs to respond to controller events when it is the frontmost app.")
        }

        // 获取扩展控制器（DualSense 是扩展控制器）
        guard let extendedGamepad = dualSenseController?.extendedGamepad else { return }
        
        // 触摸板（DualSense 触摸板可作为按钮）
        if let dualSenseGamepad = extendedGamepad as? GCDualSenseGamepad {
            setupTouchpadInput(for: dualSenseGamepad)
        } else {
            print("控制器不是 DualSense 或未连接")
        }
        
        // 监听按钮事件
        extendedGamepad.buttonA.pressedChangedHandler = { (button, value, isPressed) in
            print("× Button pressed: \(isPressed)")
            self.buttonStates["×"] = isPressed
            if isPressed {
                GameControllerManager.hapticsTimes? += 1
                GameControllerManager.hapticsTimes? %= 8
                if let index = GameControllerManager.hapticsTimes {
                    self.playHapticsFile(named: self.ahapFiles[index], locality: self.ahapLocalities[index])
                }
            }
        }
        
        extendedGamepad.buttonB.pressedChangedHandler = { (button, value, isPressed) in
            print("○ Button pressed: \(isPressed)")
            self.buttonStates["○"] = isPressed
        }
        
        
        extendedGamepad.buttonX.pressedChangedHandler = { (button, value, isPressed) in
            print("◻︎ Button pressed: \(isPressed)")
            self.buttonStates["◻︎"] = isPressed
        }
        
        extendedGamepad.buttonY.pressedChangedHandler = { (button, value, isPressed) in
            print("△ Button pressed: \(isPressed)")
            self.buttonStates["△"] = isPressed
        }
        
        if let buttonHome = extendedGamepad.buttonHome {
            buttonHome.pressedChangedHandler = { (button, value, isPressed) in
                print("Home Button pressed: \(isPressed)")
                self.buttonStates["Home"] = isPressed
            }
        }
        
        if let buttonOptions = extendedGamepad.buttonOptions {
            buttonOptions.pressedChangedHandler = { (button, value, isPressed) in
                print("Options Button pressed: \(isPressed)")
                self.buttonStates["Options"] = isPressed
            }
        }
        
        extendedGamepad.buttonMenu.pressedChangedHandler = { (button, value, isPressed) in
            print("Menu Button pressed: \(isPressed)")
            self.buttonStates["Menu"] = isPressed
        }
        
        extendedGamepad.dpad.valueChangedHandler = { (dpad: GCControllerDirectionPad, xValue: Float, yValue: Float) in
            print("D-Pad 输入变化: (x: \(xValue), y: \(yValue))")
            
            if dpad.up.isPressed {
                print("↑ 方向键按下")
            }
            if dpad.down.isPressed {
                print("↓ 方向键按下")
            }
            if dpad.left.isPressed {
                print("← 方向键按下")
            }
            if dpad.right.isPressed {
                print("→ 方向键按下")
            }
        }
        
        extendedGamepad.leftShoulder.pressedChangedHandler = { (button, value, isPressed) in
            print("L2 Shoulder: \(value)") // 0.0 ~ 1.0
        }
        
        extendedGamepad.rightShoulder.pressedChangedHandler = { (button, value, isPressed) in
            print("R2 Shoulder: \(value)")
        }
        
        extendedGamepad.leftTrigger.pressedChangedHandler = { (button, value, isPressed) in
            print("L2 Trigger: \(value)") // 0.0 ~ 1.0
            self.leftTrigger = value
            self.buttonStates["L2"] = isPressed
        }
        
        extendedGamepad.rightTrigger.pressedChangedHandler = { (button, value, isPressed) in
            print("R2 Trigger: \(value)")
            self.rightTrigger = value
            self.buttonStates["R2"] = isPressed
        }
        
        // 摇杆输入
        extendedGamepad.leftThumbstick.valueChangedHandler = { (thumbstick, xValue, yValue) in
            print("Left Stick: (\(xValue), \(yValue))")
            self.leftThumbstick = (xValue, yValue)
        }
        
        extendedGamepad.rightThumbstick.valueChangedHandler = { (thumbstick, xValue, yValue) in
            print("Right Stick: (\(xValue), \(yValue))")
            self.rightThumbstick = (xValue, yValue)
        }
        
        if let leftThumbstickButton = extendedGamepad.leftThumbstickButton {
            leftThumbstickButton.pressedChangedHandler = { (button, value, isPressed) in
                print("leftThumbstick Button pressed: \(isPressed)")
            }
        }
        
        if let rightThumbstickButton = extendedGamepad.rightThumbstickButton {
            rightThumbstickButton.pressedChangedHandler = { (button, value, isPressed) in
                print("rightThumbstickButton Button pressed: \(isPressed)")
            }
        }
    }

    func setupMotionSensing() {
        print("GameControllerManager::setupMotionSensing")
        guard let motion = dualSenseController?.motion else { return }
        motion.sensorsActive = true
        
        // 监听运动数据
        motion.valueChangedHandler = { (motion) in
            let gyro = motion.rotationRate // 陀螺仪（x, y, z）
            let accel = motion.userAcceleration // 加速度计
            let gravity = motion.gravity // 重力感应
            
            print("Gyro: \(gyro), Accel: \(accel), Gravity: \(gravity)")
        }
    }
    
    private func triggerHapticFeedback() {
        print("GameControllerManager::triggerHapticFeedback")
//        guard let controller = dualSenseController else { return }
//        
//        let hapticEngine = controller.haptics?.createEngine(withLocality: .default)
//        let pattern = try! CHHapticPattern(
//            events: [
//                GCHapticsEvent(
//                    eventType: .hapticContinuous,
//                    parameters: [
//                        GCHapticsContinuousEventParameter(parameterID: .hapticIntensity, value: 1.0),
//                        GCHapticsContinuousEventParameter(parameterID: .hapticSharpness, value: 0.5)
//                    ],
//                    relativeTime: 0,
//                    duration: 0.5
//                )
//            ]
//        )
//        
//        hapticEngine?.playPattern(pattern)
    }
    
    private func batteryStateChanged() {
        guard let battery = dualSenseController?.battery else { return }
        
        print("电池状态变化：当前电量 \(battery.batteryLevel * 100)%")
        
        switch battery.batteryState {
            case .charging:
                print("电池充电中，当前电量：\(battery.batteryLevel)%")
            case .full:
                print("电池已充满")
            case .discharging:
                print("电池使用中，当前电量：\(battery.batteryLevel)%")
            case .unknown:
                print("电池状态未知")
            @unknown default:
                print("未知状态")
            }
    }
    
    private func startBreathingEffect() {
        var hue: CGFloat = 0.0
        var brightness: CGFloat = 0.5
        var timer: Timer?
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            hue += 0.005
            if hue >= 1.0 { hue = 0.0 }
            
            // 呼吸效果
            brightness = 0.5 + 0.5 * sin(CGFloat(Date().timeIntervalSince1970))
            
            let uiColor = UIColor(hue: hue, saturation: 1.0, brightness: brightness, alpha: 1.0)
            self.dualSenseController?.light?.color = GCColor(red: Float(uiColor.rgba.red),
                                                       green: Float(uiColor.rgba.green),
                                                       blue: Float(uiColor.rgba.blue))
        }
    }
    
//    private func startMicrophone(for dualSense: GCDualSenseGamepad) {
//        guard let microphone = dualSenseController?.microphone else {
//            print("控制器麦克风不可用")
//            return
//        }
//        
//        // 开关麦克风 LED（仅支持开关，不支持自定义颜色）
//        microphone.isMuted ? microphone.unmute() : microphone.mute()
//
//        // 监听状态变化
//        microphone.muteChangedHandler = { mic in
//            print("麦克风状态: \(mic.isMuted ? "静音（橙色）" : "开启（白色）")")
//        }
//    }
    
    // ...（其他方法如 configureAdaptiveTrigger、playDualSenseHaptics 等）
    func configureAdaptiveTrigger(for dualSense: GCDualSenseGamepad) {
        print("GameControllerManager::DualSenseManager configureAdaptiveTrigger")
        print(GCDualSenseAdaptiveTrigger.PositionalResistiveStrengths.self)

        // 创建位置阻力强度配置
        let strengthsFeedback = GCDualSenseAdaptiveTrigger.PositionalResistiveStrengths(
            values: (0.1, 0.3, 0.5, 0.7, 0.9, 0.9, 0.7, 0.5, 0.3, 0.1)
        )
        
        // 配置左扳机（L2）效果：渐进阻力// 配置左扳机 (L2)
        dualSense.leftTrigger.setModeFeedback(resistiveStrengths: strengthsFeedback)
//        dualSense.leftTrigger.setModeWeaponWithStartPosition(0.2, endPosition: 0.8, resistiveStrength: 0.7)

        // 配置右扳机
        let strengthsWeapon = GCDualSenseAdaptiveTrigger.PositionalResistiveStrengths(
            values: (0.1, 0.3, 0.5, 0.7, 0.9, 0.9, 0.7, 0.5, 0.3, 0.1)
        )
        // 配置右扳机 (R2) 为武器模式
        dualSense.rightTrigger.setModeFeedback(resistiveStrengths: strengthsWeapon)
    }
    
    func playDualSenseHaptics(for dualSense: GCDualSenseGamepad) {
        print("GameControllerManager::DualSenseManager playDualSenseHaptics")
        guard let haptics = dualSense.controller?.haptics else {
            print("DualSense 触觉反馈不可用")
            return
        }

        let engine = haptics.createEngine(withLocality: .default)
        
        // 先定义参数（这两行必须在创建event之前）
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)  // 强度 0.0-1.0
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5) // 锐度 0.0-1.0
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [sharpness, intensity],
            relativeTime: 0
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("GameControllerManager::触觉反馈播放失败: \(error)")
        }
    }
    
    private func createEngine(for controller: GCController, locality: GCHapticsLocality) -> CHHapticEngine? {
        // Get the controller's haptics (if one exists), and create a
        // new CGHapticEngine for it, using the default locality.
        guard let engine = controller.haptics?.createEngine(withLocality: locality) else {
            print("Failed to create engine.")
            return nil
        }
        
        // The stopped handler alerts you of engine stoppage due to external causes.
        engine.stoppedHandler = { reason in
            print("The engine stopped because \(reason)")
        }
        
        // The reset handler provides an opportunity for your app to restart the engine in case of failure.
        engine.resetHandler = {
            // Try restarting the engine.
            print("The engine reset --> Restarting now!")
            do {
                try engine.start()
            } catch {
                print("Failed to restart the engine: \(error)")
            }
        }
        return engine
    }

    /// - Tag: PlayHapticsFile
    func playHapticsFile(named filename: String, locality: GCHapticsLocality = .default) {
        // Update the engine based on locality.
        var engine: CHHapticEngine!
        if let existingEngine = engineMap[locality] {
            engine = existingEngine
        } else if let newEngine = createEngine(for: dualSenseController!, locality: locality) {
            engine = newEngine
        }

        guard engine != nil else {
            print("Unable to play haptics: no engine available for locality %@", locality)
            return
        }
        
        // Get the AHAP file URL.
        guard let url = Bundle.main.url(forResource: filename,
                                        withExtension: "ahap") else {
            print("Unable to find haptics file named '\(filename)'.")
            return
        }
        
        do {
            // Start the engine in case it's idle.
            try engine.start()
            
            // Tell the engine to play a pattern.
            try engine.playPattern(from: url)
            
        } catch { // Engine startup errors
            print("An error occured playing \(filename): \(error).")
        }
    }

    func setupTouchpadInput(for dualSense: GCDualSenseGamepad) {
        print("DualSenseManager setupTouchpadInput")
        dualSense.touchpadButton.valueChangedHandler = { (button, value, isPressed) in
            print("GameControllerManager::触摸板点击: \(isPressed)")
        }

        dualSense.touchpadPrimary.valueChangedHandler = { [weak self] touchpad, x, y in
            // ✅ 正确的触摸检测方式
            print("GameControllerManager::主触摸板被触摸 - 位置: (\(x), \(y))")
            
            // 或者直接检查 x,y 值
            if x != 0 || y != 0 {
                print("GameControllerManager::触摸板有输入")
            }
            
            // 设置触摸板按钮处理
            dualSense.touchpadButton.valueChangedHandler = { [weak self] _, _, pressed in
                print("GameControllerManager::触摸板按钮状态: \(pressed ? "按下" : "释放")")
            }
        }
        
        dualSense.touchpadSecondary.valueChangedHandler = { [weak self] touchpad, x, y in
            // ✅ 正确的触摸检测方式
            print("GameControllerManager::副触摸板被触摸 - 位置: (\(x), \(y))")
            
            // 或者直接检查 x,y 值
            if x != 0 || y != 0 {
                print("GameControllerManager::触摸板有输入")
            }
            
            // 设置触摸板按钮处理
            dualSense.touchpadButton.valueChangedHandler = { [weak self] _, _, pressed in
                print("GameControllerManager::触摸板按钮状态: \(pressed ? "按下" : "释放")")
            }
        }
    }
}
