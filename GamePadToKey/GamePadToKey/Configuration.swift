//
//  Configuration.swift
//  GamePadToKey
//

import Foundation
import CoreGraphics

public struct Configuration: Codable {
    public let configVersion: String
    public let name: String
    public let author: String
    public let description: String
    public let globalSettings: GlobalSettings
    public let keyboardLayout: KeyboardLayout
    public let partitions: [Partition]
    
    // 运行时构建的树结构 - 不参与编码/解码
    public var rootPartition: PartitionNode?
    
    public init(configVersion: String, name: String, author: String, description: String, 
                globalSettings: GlobalSettings, keyboardLayout: KeyboardLayout, partitions: [Partition]) {
        self.configVersion = configVersion
        self.name = name
        self.author = author
        self.description = description
        self.globalSettings = globalSettings
        self.keyboardLayout = keyboardLayout
        self.partitions = partitions
    }
    
    // 自定义编码键
    private enum CodingKeys: String, CodingKey {
        case configVersion, name, author, description
        case globalSettings, keyboardLayout, partitions
        // 不包含 rootPartition
    }
    
    public static func createDefault() -> Configuration {
        return Configuration(
            configVersion: "1.0",
            name: "默认配置",
            author: "系统",
            description: "默认键盘映射配置",
            globalSettings: GlobalSettings.defaultSettings(),
            keyboardLayout: KeyboardLayout.defaultLayout(),
            partitions: Partition.defaultPartitions()
        )
    }
}

public struct GlobalSettings: Codable {
    public let timeoutSeconds: Double
    public let defaultDeadzone: Double
    public let mouseSensitivity: Double
    public let vibrationEnabled: Bool
    
    public init(timeoutSeconds: Double, defaultDeadzone: Double, mouseSensitivity: Double, vibrationEnabled: Bool) {
        self.timeoutSeconds = timeoutSeconds
        self.defaultDeadzone = defaultDeadzone
        self.mouseSensitivity = mouseSensitivity
        self.vibrationEnabled = vibrationEnabled
    }
    
    public static func defaultSettings() -> GlobalSettings {
        return GlobalSettings(
            timeoutSeconds: 5.0,
            defaultDeadzone: 0.15,
            mouseSensitivity: 1.0,
            vibrationEnabled: true
        )
    }
}

public struct KeyboardLayout: Codable {
    public let name: String
    public let width: Int
    public let height: Int
    public let keys: [KeyboardKey]
    
    public init(name: String, width: Int, height: Int, keys: [KeyboardKey]) {
        self.name = name
        self.width = width
        self.height = height
        self.keys = keys
    }
    
    public static func defaultLayout() -> KeyboardLayout {
        return KeyboardLayout(
            name: "标准104键键盘",
            width: 104,
            height: 40,
            keys: []
        )
    }
}

public struct KeyboardKey: Codable {
    public let id: String
    public let x: Int
    public let y: Int
    public let width: Int
    public let height: Int
    
    public init(id: String, x: Int, y: Int, width: Int, height: Int) {
        self.id = id
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct Partition: Codable {
    public let id: String
    public let name: String
    public let type: PartitionType
    public let activationCombo: [String]
    public let bounds: CGRect?
    public let feedback: PartitionFeedback?
    public let children: [Partition]
    public let mappings: [MappingConfig]
    
    public init(id: String, name: String, type: PartitionType, activationCombo: [String], 
                bounds: CGRect? = nil, feedback: PartitionFeedback? = nil, 
                children: [Partition] = [], mappings: [MappingConfig] = []) {
        self.id = id
        self.name = name
        self.type = type
        self.activationCombo = activationCombo
        self.bounds = bounds
        self.feedback = feedback
        self.children = children
        self.mappings = mappings
    }
    
    public static func defaultPartitions() -> [Partition] {
        return [
            Partition(
                id: "letter_zone",
                name: "字母区",
                type: .main,
                activationCombo: ["L1", "R1", "triangle"],
                bounds: nil,
                feedback: PartitionFeedback.defaultFeedback(),
                children: [
                    Partition(
                        id: "left_hand",
                        name: "左手区",
                        type: .sub,
                        activationCombo: ["L1", "R1", "cross"],
                        bounds: CGRect(x: 0, y: 2, width: 30, height: 20),
                        feedback: nil,
                        children: [
                            Partition(
                                id: "home_row_left",
                                name: "左手基准行",
                                type: .subSub,
                                activationCombo: ["L1", "square"],
                                bounds: CGRect(x: 0, y: 4, width: 15, height: 4),
                                feedback: nil,
                                children: [],
                                mappings: [
                                    MappingConfig(
                                        button: "triangle",
                                        action: .keyPress,
                                        key: "a",
                                        modifiers: [],
                                        feedback: nil
                                    ),
                                    MappingConfig(
                                        button: "circle",
                                        action: .keyPress,
                                        key: "s",
                                        modifiers: [],
                                        feedback: nil
                                    ),
                                    MappingConfig(
                                        button: "cross",
                                        action: .keyPress,
                                        key: "d",
                                        modifiers: [],
                                        feedback: nil
                                    )
                                ]
                            )
                        ],
                        mappings: []
                    )
                ],
                mappings: []
            )
        ]
    }
}

public struct MappingConfig: Codable {
    public let button: String
    public let action: ActionType
    public let key: String?
    public let modifiers: [String]?
    public let feedback: MappingFeedback?
    
    public init(button: String, action: ActionType, key: String? = nil, 
                modifiers: [String]? = nil, feedback: MappingFeedback? = nil) {
        self.button = button
        self.action = action
        self.key = key
        self.modifiers = modifiers
        self.feedback = feedback
    }
}

