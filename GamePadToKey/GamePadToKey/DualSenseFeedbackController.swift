//
//  DualSenseFeedbackController.swift
//  GamePadToKey
//

import Foundation
import GameController

public class DualSenseFeedbackController {
    private var dualSense: GCDualSenseGamepad?
    
    public init() {
        setupController()
    }
    
    private func setupController() {
        // 查找已连接的 DualSense 手柄
        if let controller = GCController.controllers().first(where: { $0.productCategory == "DualSense" }) {
            dualSense = controller.physicalInputProfile as? GCDualSenseGamepad
        }
        
        // 监听手柄连接
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidConnect),
            name: .GCControllerDidConnect,
            object: nil
        )
    }
    
    @objc private func controllerDidConnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        if controller.productCategory == "DualSense" {
            dualSense = controller.physicalInputProfile as? GCDualSenseGamepad
        }
    }
    
    public func applyFeedback(_ feedback: Feedback) {
        guard let dualSense = dualSense else { return }
        
        // 应用 LED 反馈
        if let ledColor = feedback.ledColor {
            setLED(color: ledColor, pattern: feedback.ledPattern ?? .solid)
        }
        
        // 应用振动反馈
        if let vibration = feedback.vibration {
            playVibration(pattern: vibration)
        }
        
        // 应用扳机反馈
        if let triggerEffect = feedback.triggerEffect {
            setTriggerEffect(mode: triggerEffect)
        }
    }
    
    public func setLED(color: (r: CGFloat, g: CGFloat, b: CGFloat), pattern: LEDPattern = .solid) {
        guard let dualSense = dualSense else { return }
        
        // 设置 LED 颜色
        setLightColorRed(color.r, green: color.g, blue: color.b)
        
        switch pattern {
        case .solid:
            // 常亮模式
            break
        case .pulse:
            // 脉冲效果 - 需要定时器实现
            startPulseEffect(color: color)
        case .blink(let onDuration, let offDuration):
            // 闪烁效果 - 需要定时器实现
            startBlinkEffect(color: color, onDuration: onDuration, offDuration: offDuration)
        case .rainbow:
            // 彩虹效果
            startRainbowEffect()
        }
    }
    
    public func playVibration(pattern: VibrationPattern) {
        guard let dualSense = dualSense else { return }
        
        // 使用 Core Haptics 或自定义振动模式
        switch pattern {
        case .none:
            // 停止振动
            stopVibration()
        case .light:
            playVibrationWithIntensity(0.3, duration: 0.1)
        case .medium:
            playVibrationWithIntensity(0.6, duration: 0.2)
        case .heavy:
            playVibrationWithIntensity(1.0, duration: 0.3)
        case .click:
            playVibrationWithIntensity(0.5, duration: 0.05)
        case .warning:
            // 警告模式：三次短振动
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                    self.playVibrationWithIntensity(0.8, duration: 0.1)
                }
            }
        case .continuous:
            playContinuousVibration(intensity: 0.4)
        }
    }
    
    public func setTriggerEffect(mode: TriggerMode) {
        guard let dualSense = dualSense else { return }
        
        let leftTrigger = dualSense.leftTrigger
        let rightTrigger = dualSense.rightTrigger
        
        switch mode {
        case .off:
            // 关闭扳机效果
            setTriggerModeOff(leftTrigger)
            setTriggerModeOff(rightTrigger)
            
        case .resistance(let startPosition, let endPosition, let strength):
            // 设置阻力模式
            setTriggerModeResistance(leftTrigger, startPosition: startPosition, endPosition: endPosition, strength: strength)
            setTriggerModeResistance(rightTrigger, startPosition: startPosition, endPosition: endPosition, strength: strength)
            
        case .feedback(let startPosition, let endPosition, let strength, let frequency):
            // 设置反馈模式
            setTriggerModeFeedback(leftTrigger, startPosition: startPosition, endPosition: endPosition, strength: strength, frequency: frequency)
            setTriggerModeFeedback(rightTrigger, startPosition: startPosition, endPosition: endPosition, strength: strength, frequency: frequency)
            
        case .weapon(let startPosition, let endPosition, let strength):
            // 设置武器模式
            setTriggerModeWeapon(leftTrigger, startPosition: startPosition, endPosition: endPosition, strength: strength)
            setTriggerModeWeapon(rightTrigger, startPosition: startPosition, endPosition: endPosition, strength: strength)
            
        case .vibration(let startPosition, let endPosition, let amplitude, let frequency):
            // 设置振动模式
            setTriggerModeVibration(leftTrigger, startPosition: startPosition, endPosition: endPosition, amplitude: amplitude, frequency: frequency)
            setTriggerModeVibration(rightTrigger, startPosition: startPosition, endPosition: endPosition, amplitude: amplitude, frequency: frequency)
        }
    }
    
    public func playNavigationFeedback() {
        let feedback = Feedback(
            vibration: .click,
            ledColor: (r: 0.0, g: 0.5, b: 1.0),
            ledPattern: .pulse
        )
        applyFeedback(feedback)
    }
    
    // MARK: - 私有方法
    
    private func setLightColorRed(_ red: CGFloat, green: CGFloat, blue: CGFloat) {
        // 设置 LED 颜色
        // 注意：GCDualSenseGamepad 可能没有直接的 API 设置颜色
        // 这里可能需要使用其他方法或框架
        print("设置 LED 颜色: R:\(red), G:\(green), B:\(blue)")
    }
    
    private func playVibrationWithIntensity(_ intensity: Float, duration: TimeInterval) {
        // 使用 Core Haptics 实现振动
        // 这里需要实现具体的振动逻辑
        print("播放振动: 强度 \(intensity), 持续时间 \(duration)")
    }
    
    private func playContinuousVibration(intensity: Float) {
        // 持续振动
        print("持续振动: 强度 \(intensity)")
    }
    
    private func stopVibration() {
        // 停止振动
        print("停止振动")
    }
    
    private func startPulseEffect(color: (r: CGFloat, g: CGFloat, b: CGFloat)) {
        // 脉冲效果实现
        var brightness: CGFloat = 0.5
        var increasing = true
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if increasing {
                brightness += 0.05
                if brightness >= 1.0 {
                    brightness = 1.0
                    increasing = false
                }
            } else {
                brightness -= 0.05
                if brightness <= 0.5 {
                    brightness = 0.5
                    increasing = true
                }
            }
            
            let adjustedColor = (r: color.r * brightness, g: color.g * brightness, b: color.b * brightness)
            self.setLightColorRed(adjustedColor.r, green: adjustedColor.g, blue: adjustedColor.b)
        }
    }
    
    private func startBlinkEffect(color: (r: CGFloat, g: CGFloat, b: CGFloat), onDuration: TimeInterval, offDuration: TimeInterval) {
        // 闪烁效果实现
        var isOn = true
        
        Timer.scheduledTimer(withTimeInterval: isOn ? onDuration : offDuration, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if isOn {
                // 关闭
                self.setLightColorRed(0, green: 0, blue: 0)
                timer.fireDate = Date().addingTimeInterval(offDuration)
            } else {
                // 开启
                self.setLightColorRed(color.r, green: color.g, blue: color.b)
                timer.fireDate = Date().addingTimeInterval(onDuration)
            }
            
            isOn.toggle()
        }
    }
    
    private func startRainbowEffect() {
        // 彩虹效果实现
        var hue: CGFloat = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let color = self.hsvToRgb(h: hue, s: 1.0, v: 1.0)
            self.setLightColorRed(color.r, green: color.g, blue: color.b)
            
            hue += 0.01
            if hue > 1.0 {
                hue = 0
            }
        }
    }
    
    private func hsvToRgb(h: CGFloat, s: CGFloat, v: CGFloat) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        let i = Int(h * 6)
        let f = h * 6 - CGFloat(i)
        let p = v * (1 - s)
        let q = v * (1 - f * s)
        let t = v * (1 - (1 - f) * s)
        
        switch i % 6 {
        case 0: return (v, t, p)
        case 1: return (q, v, p)
        case 2: return (p, v, t)
        case 3: return (p, q, v)
        case 4: return (t, p, v)
        case 5: return (v, p, q)
        default: return (0, 0, 0)
        }
    }
    
    // MARK: - 扳机效果私有方法
    
    private func setTriggerModeOff(_ trigger: GCDualSenseAdaptiveTrigger) {
        // 关闭扳机效果
        print("关闭扳机效果")
    }
    
    private func setTriggerModeResistance(_ trigger: GCDualSenseAdaptiveTrigger, startPosition: Float, endPosition: Float, strength: Float) {
        // 设置阻力模式
        print("设置阻力模式: 开始位置 \(startPosition), 结束位置 \(endPosition), 强度 \(strength)")
    }
    
    private func setTriggerModeFeedback(_ trigger: GCDualSenseAdaptiveTrigger, startPosition: Float, endPosition: Float, strength: Float, frequency: Float) {
        // 设置反馈模式
        print("设置反馈模式: 开始位置 \(startPosition), 结束位置 \(endPosition), 强度 \(strength), 频率 \(frequency)")
    }
    
    private func setTriggerModeWeapon(_ trigger: GCDualSenseAdaptiveTrigger, startPosition: Float, endPosition: Float, strength: Float) {
        // 设置武器模式
        print("设置武器模式: 开始位置 \(startPosition), 结束位置 \(endPosition), 强度 \(strength)")
    }
    
    private func setTriggerModeVibration(_ trigger: GCDualSenseAdaptiveTrigger, startPosition: Float, endPosition: Float, amplitude: Float, frequency: Float) {
        // 设置振动模式
        print("设置振动模式: 开始位置 \(startPosition), 结束位置 \(endPosition), 振幅 \(amplitude), 频率 \(frequency)")
    }
}
