//
//  DebugTools.swift
//  GamePadToKey
//

import Foundation

class DebugTools {
    static func printPartitionMappings(_ partition: PartitionNode, indent: Int = 0) {
        let indentStr = String(repeating: "  ", count: indent)
        
        print("\(indentStr)分区: \(partition.name) (ID: \(partition.id))")
        
        // 打印按钮映射
        if !partition.mappings.isEmpty {
            print("\(indentStr)  按钮映射:")
            for (button, mapping) in partition.mappings {
                print("\(indentStr)    \(button): \(describeMapping(mapping))")
            }
        }
        
        // 打印摇杆映射
        if !partition.joystickMappings.isEmpty {
            print("\(indentStr)  摇杆映射:")
            for (joystick, mapping) in partition.joystickMappings {
                print("\(indentStr)    \(joystick.rawValue): \(describeMapping(mapping))")
            }
        }
        
        // 打印触摸板映射
        if let touchpadMapping = partition.touchpadMapping {
            print("\(indentStr)  触摸板映射: \(describeMapping(touchpadMapping))")
        }
        
        // 打印运动传感器映射
        if let motionMapping = partition.motionMapping {
            print("\(indentStr)  运动传感器映射: \(describeMapping(motionMapping))")
        }
        
        // 递归打印子分区
        for child in partition.children {
            printPartitionMappings(child, indent: indent + 1)
        }
    }
    
    private static func describeMapping(_ mapping: Mapping) -> String {
        switch mapping.action {
        case .keyPress(let key, let modifiers):
            return "按键: \(key) \(modifiers.isEmpty ? "" : "修饰键: \(modifiers.joined(separator: "+"))")"
        case .keyCombo(let keys):
            return "组合键: \(keys.joined(separator: "+"))"
        case .mouseMove(let sensitivity, let acceleration):
            return "鼠标移动 (灵敏度: \(sensitivity), 加速度: \(acceleration ? "开" : "关"))"
        case .mouseClick(let button, let mode):
            return "鼠标点击 (\(button.rawValue), 模式: \(mode.rawValue))"
        case .mouseScroll(let axis, let sensitivity):
            return "鼠标滚动 (\(axis.rawValue), 灵敏度: \(sensitivity))"
        case .macro(let id):
            return "宏: \(id)"
        }
    }
    
    static func checkInputProcessor(_ processor: DualSenseInputProcessor) {
        print("=== 输入处理器状态 ===")
        print("已连接: \(processor.isConnected)")
        print("控制器名称: \(processor.controllerName ?? "无")")
        print("调试日志: \(processor.enableDebugLogging ? "开启" : "关闭")")
    }
    
    static func checkConfiguration(_ config: Configuration) {
        print("=== 配置状态 ===")
        print("配置名称: \(config.name)")
        print("版本: \(config.configVersion)")
        print("分区数量: \(config.partitions.count)")
        
        if let root = config.rootPartition {
            print("根分区: \(root.name)")
            printPartitionMappings(root)
        } else {
            print("警告: 根分区未构建")
        }
    }
}
