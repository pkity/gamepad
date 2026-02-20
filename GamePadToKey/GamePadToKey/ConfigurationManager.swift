//
//  ConfigurationManager.swift
//  GamePadToKey
//

import Foundation

enum ConfigError: Error {
    case fileNotFound
    case invalidFormat
    case duplicateActivationCombo(String)
    case invalidMapping
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
    
    func getAvailableConfigs() -> [String] {
        do {
            let files = try fileManager.contentsOfDirectory(at: configDirectory,
                                                           includingPropertiesForKeys: nil)
            return files
                .filter { $0.pathExtension == "json" }
                .map { $0.deletingPathExtension().lastPathComponent }
        } catch {
            return []
        }
    }
    
    private func createConfigDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: configDirectory.path) {
            try? fileManager.createDirectory(at: configDirectory,
                                           withIntermediateDirectories: true)
        }
    }
    
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
        
        // 构建映射
        for mappingConfig in partition.mappings {
            let mapping = Mapping(from: mappingConfig)
            node.mappings[mappingConfig.button] = mapping
        }
        
        // 构建子节点
        for child in partition.children {
            let childNode = buildNode(child, parent: node)
            node.children.append(childNode)
        }
        
        return node
    }
}
