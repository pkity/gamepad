//
//  Mapping.swift
//  GamePadToKey
//

import Foundation

public struct Mapping {
    public let button: String?
    public let joystick: JoystickType?
    public let action: Action
    public let feedback: MappingFeedback?
    
    public init(button: String? = nil, joystick: JoystickType? = nil, action: Action, feedback: MappingFeedback? = nil) {
        self.button = button
        self.joystick = joystick
        self.action = action
        self.feedback = feedback
    }
    
    public init(from config: MappingConfig) {
        self.button = config.button
        self.joystick = nil
        
        // 根据配置创建动作
        switch config.action {
        case .keyPress:
            if let key = config.key {
                self.action = .keyPress(key: key, modifiers: config.modifiers ?? [])
            } else {
                self.action = .keyPress(key: "", modifiers: [])
            }
        case .keyCombo:
            if let key = config.key {
                self.action = .keyCombo(keys: [key] + (config.modifiers ?? []))
            } else {
                self.action = .keyCombo(keys: [])
            }
        case .mouseMove:
            self.action = .mouseMove(sensitivity: 1.0, acceleration: false)
        case .mouseClick:
            self.action = .mouseClick(button: .left, mode: .click)
        case .mouseScroll:
            self.action = .mouseScroll(axis: .vertical, sensitivity: 1.0)
        case .modifier:
            self.action = .keyPress(key: "", modifiers: [])
        case .macro:
            self.action = .macro(id: config.key ?? "")
        }
        
        self.feedback = config.feedback
    }
}

