//
//  ConfigurationManager.swift
//  GamePadToKey
//

import Foundation
import UniformTypeIdentifiers

enum ConfigError: Error {
    case fileNotFound
    case invalidFormat
    case duplicateActivationCombo(String)
    case invalidMapping
    case saveFailed
    case importFailed
    case exportFailed
}

class ConfigurationManager {
    private var currentConfig: Configuration?
    private let configDirectory: URL
    private let fileManager = FileManager.default
    
    init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory,
                                         in: .userDomainMask).first!
        configDirectory = appSupport.appendingPathComponent("GamePadToKey/Configs")
        createConfigDirectoryIfNeeded()
    }
    
    // MARK: - 配置管理
    
    func loadConfiguration(named: String) throws -> Configuration {
        let configURL = configDirectory.appendingPathComponent("\(named).json")
        
        guard fileManager.fileExists(atPath: configURL.path) else {
            throw ConfigError.fileNotFound
        }
        
        let data = try Data(contentsOf: configURL)
        
        let decoder = JSONDecoder()
        var config = try decoder.decode(Configuration.self, from: data)
        
        // 验证配置
        try validateConfiguration(config)
        
        // 构建分区树
        config.rootPartition = buildPartitionTree(config.partitions)
        
        currentConfig = config
        return config
    }
    
    func saveConfiguration(_ config: Configuration) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(config)
        let configURL = configDirectory
            .appendingPathComponent(config.name)
            .appendingPathExtension("json")
        
        try data.write(to: configURL)
    }
    
    func deleteConfiguration(named: String) throws {
        let configURL = configDirectory.appendingPathComponent("\(named).json")
        
        guard fileManager.fileExists(atPath: configURL.path) else {
            throw ConfigError.fileNotFound
        }
        
        try fileManager.removeItem(at: configURL)
    }
    
    func duplicateConfiguration(named: String, newName: String) throws {
        let sourceURL = configDirectory.appendingPathComponent("\(named).json")
        let destinationURL = configDirectory.appendingPathComponent("\(newName).json")
        
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw ConfigError.fileNotFound
        }
        
        // 检查目标文件是否已存在
        if fileManager.fileExists(atPath: destinationURL.path) {
            throw ConfigError.duplicateActivationCombo("配置名称已存在")
        }
        
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }
    
    func getAvailableConfigs() -> [String] {
        do {
            let files = try fileManager.contentsOfDirectory(at: configDirectory,
                                                           includingPropertiesForKeys: nil)
            return files
                .filter { $0.pathExtension == "json" }
                .map { $0.deletingPathExtension().lastPathComponent }
                .sorted()
        } catch {
            return []
        }
    }
    
    // MARK: - 导入导出
    
    func importConfiguration(from url: URL) throws -> Configuration {
        let data = try Data(contentsOf: url)
        
        let decoder = JSONDecoder()
        let config = try decoder.decode(Configuration.self, from: data)
        
        // 验证配置
        try validateConfiguration(config)
        
        // 保存到配置目录
        let configURL = configDirectory
            .appendingPathComponent(config.name)
            .appendingPathExtension("json")
        
        // 如果已存在，添加时间戳
        var finalURL = configURL
        if fileManager.fileExists(atPath: configURL.path) {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
            let newName = "\(config.name)_导入_\(timestamp)"
            finalURL = configDirectory
                .appendingPathComponent(newName)
                .appendingPathExtension("json")
        }
        
        try data.write(to: finalURL)
        return config
    }
    
    func exportConfiguration(_ config: Configuration, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(config)
        try data.write(to: url)
    }
    
    func getExportURL(for configName: String) -> URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent("\(configName).json")
    }
    
    // MARK: - 配置验证
    
    private func validateConfiguration(_ config: Configuration) throws {
        // 检查激活组合键冲突
        var combos: Set<Set<String>> = []
        
        func checkPartition(_ partition: Partition) throws {
            let comboSet = Set(partition.activationCombo)
            if combos.contains(comboSet) {
                throw ConfigError.duplicateActivationCombo(partition.name)
            }
            combos.insert(comboSet)
            
            for child in partition.children {
                try checkPartition(child)
            }
        }
        
        for partition in config.partitions {
            try checkPartition(partition)
        }
    }
    
    // MARK: - 辅助方法
    
    private func createConfigDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: configDirectory.path) {
            try? fileManager.createDirectory(at: configDirectory,
                                           withIntermediateDirectories: true)
        }
    }
    
    private func buildPartitionTree(_ partitions: [Partition]) -> PartitionNode {
        let root = PartitionNode(id: "root", name: "Root", type: .root)
        
        for partition in partitions {
            let node = buildNode(partition, parent: root)
            root.children.append(node)
        }
        
        return root
    }
    
    private func buildNode(_ partition: Partition, parent: PartitionNode) -> PartitionNode {
        let node = PartitionNode(id: partition.id,
                                name: partition.name,
                                type: partition.type)
        node.parent = parent
        node.activationCombo = Set(partition.activationCombo)
        node.bounds = partition.bounds
        node.feedback = partition.feedback
        
        // 处理所有映射配置
        for mappingConfig in partition.mappings {
            let mapping = Mapping(from: mappingConfig)
            
            // 根据按钮类型分配到不同的映射表
            switch mappingConfig.button {
            case "left_joystick":
                node.addJoystickMapping(for: .left, mapping: mapping)
            case "right_joystick":
                node.addJoystickMapping(for: .right, mapping: mapping)
            case "touchpad":
                node.setTouchpadMapping(mapping)
            case "motion":
                node.setMotionMapping(mapping)
            default:
                // 普通按钮映射
                if let button = mapping.button {
                    node.mappings[button] = mapping
                }
            }
        }
        
        // 构建子节点
        for child in partition.children {
            let childNode = buildNode(child, parent: node)
            node.children.append(childNode)
        }
        
        return node
    }
    
    // 创建带摇杆支持的默认配置
    public func createDefaultConfigurationWithJoystickSupport() throws {
        let config = Configuration.createCompleteDefault()
        try saveConfiguration(config)
    }
}

