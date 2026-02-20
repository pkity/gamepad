//
//  Types.swift
//  GamePadToKey
//

import Foundation
import CoreGraphics

// MARK: - 基础类型

/// 分区类型
public enum PartitionType: String, Codable {
    case root
    case main
    case sub
    case subSub = "sub_sub"
}

/// 动作类型
public enum ActionType: String, Codable {
    case keyPress
    case keyCombo
    case modifier
    case mouseMove
    case mouseClick
    case mouseScroll
    case macro
}

/// 摇杆类型
public enum JoystickType: String, Codable {
    case left
    case right
}

/// 鼠标按钮
public enum MouseButton: String, Codable {
    case left
    case right
    case middle
}

/// 点击模式
public enum ClickMode: String, Codable {
    case click
    case hold
    case toggle
}

/// 滚动轴
public enum ScrollAxis: String, Codable {
    case horizontal
    case vertical
}

/// 输入事件
public enum InputEvent {
    case buttonPress(button: String, pressed: Bool)
    case joystickMove(joystick: JoystickType, position: CGPoint)
    case touchpadTouch(position: CGPoint, touching: Bool)
    case motion(gyro: (x: Double, y: Double, z: Double), acceleration: (x: Double, y: Double, z: Double))
}

/// 动作
public enum Action {
    case keyPress(key: String, modifiers: [String])
    case keyCombo(keys: [String])
    case mouseMove(sensitivity: Double, acceleration: Bool)
    case mouseClick(button: MouseButton, mode: ClickMode)
    case mouseScroll(axis: ScrollAxis, sensitivity: Double)
    case macro(id: String)
}

/// 反馈
public struct Feedback {
    public var vibration: VibrationPattern?
    public var ledColor: (r: CGFloat, g: CGFloat, b: CGFloat)?
    public var ledPattern: LEDPattern?
    public var triggerEffect: TriggerMode?
    public var audioFile: String?
    
    public init(vibration: VibrationPattern? = nil, 
                ledColor: (r: CGFloat, g: CGFloat, b: CGFloat)? = nil,
                ledPattern: LEDPattern? = nil,
                triggerEffect: TriggerMode? = nil,
                audioFile: String? = nil) {
        self.vibration = vibration
        self.ledColor = ledColor
        self.ledPattern = ledPattern
        self.triggerEffect = triggerEffect
        self.audioFile = audioFile
    }
}

/// 分区反馈
public struct PartitionFeedback: Codable {
    public let ledColor: String?
    public let vibration: String?
    public let triggerEffect: String?
    
    public init(ledColor: String? = nil, vibration: String? = nil, triggerEffect: String? = nil) {
        self.ledColor = ledColor
        self.vibration = vibration
        self.triggerEffect = triggerEffect
    }
    
    public static func defaultFeedback() -> PartitionFeedback {
        return PartitionFeedback(
            ledColor: "#00FF00",
            vibration: "light",
            triggerEffect: "none"
        )
    }
}

/// 映射反馈
public struct MappingFeedback: Codable {
    public let ledFlash: String?
    public let vibration: String?
    
    public init(ledFlash: String? = nil, vibration: String? = nil) {
        self.ledFlash = ledFlash
        self.vibration = vibration
    }
}

/// 振动模式
public enum VibrationPattern {
    case none
    case light
    case medium
    case heavy
    case click
    case warning
    case continuous
}

/// LED模式
public enum LEDPattern {
    case solid
    case pulse
    case blink(onDuration: TimeInterval, offDuration: TimeInterval)
    case rainbow
}

/// 扳机模式
public enum TriggerMode {
    case off
    case resistance(startPosition: Float, endPosition: Float, strength: Float)
    case feedback(startPosition: Float, endPosition: Float, strength: Float, frequency: Float)
    case weapon(startPosition: Float, endPosition: Float, strength: Float)
    case vibration(startPosition: Float, endPosition: Float, amplitude: Float, frequency: Float)
}
