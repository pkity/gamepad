//
//  PartitionNode.swift
//  GamePadToKey
//

import Foundation
import CoreGraphics

public class PartitionNode: Codable {
    public let id: String
    public let name: String
    public let type: PartitionType
    public var activationCombo: Set<String>
    
    // 层级关系 - 需要特殊处理循环引用
    public weak var parent: PartitionNode?
    public var children: [PartitionNode] = []
    
    // 映射表
    public var mappings: [String: Mapping] = [:]
    public var joystickMappings: [JoystickType: Mapping] = [:]
    public var touchpadMapping: Mapping?
    public var motionMapping: Mapping?
    
    // 区域定义
    public var bounds: CGRect?
    
    // 反馈配置
    public var feedback: PartitionFeedback?
    
    public init(id: String, name: String, type: PartitionType) {
        self.id = id
        self.name = name
        self.type = type
        self.activationCombo = []
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case id, name, type, activationCombo, bounds, feedback
        // 不编码 parent 和 children 以避免循环引用
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(PartitionType.self, forKey: .type)
        activationCombo = try container.decode(Set<String>.self, forKey: .activationCombo)
        bounds = try container.decodeIfPresent(CGRect.self, forKey: .bounds)
        feedback = try container.decodeIfPresent(PartitionFeedback.self, forKey: .feedback)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(activationCombo, forKey: .activationCombo)
        try container.encodeIfPresent(bounds, forKey: .bounds)
        try container.encodeIfPresent(feedback, forKey: .feedback)
    }
    
    // MARK: - 查找方法
    
    public func findMapping(for button: String) -> Mapping? {
        return mappings[button]
    }
    
    public func findJoystickMapping(for joystick: JoystickType) -> Mapping? {
        return joystickMappings[joystick]
    }
    
    public func findTouchpadMapping() -> Mapping? {
        return touchpadMapping
    }
    
    public func findMotionMapping() -> Mapping? {
        return motionMapping
    }
    
    public func addMapping(for button: String, mapping: Mapping) {
        mappings[button] = mapping
    }
    
    public func addJoystickMapping(for joystick: JoystickType, mapping: Mapping) {
        joystickMappings[joystick] = mapping
    }
    
    public func setTouchpadMapping(_ mapping: Mapping) {
        touchpadMapping = mapping
    }
    
    public func setMotionMapping(_ mapping: Mapping) {
        motionMapping = mapping
    }
}

