//
//  GamePadToKeyApp+Joystick.swift
//  GamePadToKey
//

import Foundation

extension AppDelegate {
    // 使用不同的方法名避免冲突
    func loadCompleteDefaultConfiguration() {
        do {
            // 尝试加载现有配置
            let configs = configManager.getAvailableConfigs()
            if configs.contains("完整默认配置") {
                let config = try configManager.loadConfiguration(named: "完整默认配置")
                partitionEngine.loadConfiguration(config)
                print("已加载完整默认配置")
                
                // 调试输出
                DebugTools.checkConfiguration(config)
            } else {
                // 创建完整默认配置
                try createDefaultConfigurationWithJoystickSupport()
                let config = try configManager.loadConfiguration(named: "完整默认配置")
                partitionEngine.loadConfiguration(config)
                print("已创建并加载完整默认配置")
                
                // 调试输出
                DebugTools.checkConfiguration(config)
            }
        } catch {
            print("加载配置失败: \(error)")
            // 创建最基本的配置
            createBasicConfiguration()
        }
    }
    
    private func createBasicConfiguration() {
        let config = Configuration.createCompleteDefault()
        do {
            try configManager.saveConfiguration(config)
            partitionEngine.loadConfiguration(config)
            print("已创建基本配置")
        } catch {
            print("创建基本配置失败: \(error)")
        }
    }
    
    private func createDefaultConfigurationWithJoystickSupport() throws {
        let config = Configuration.createCompleteDefault()
        try configManager.saveConfiguration(config)
    }
}
