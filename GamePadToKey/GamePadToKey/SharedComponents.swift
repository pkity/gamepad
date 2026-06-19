//
//  SharedComponents.swift
//  GamePadToKey
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - 文件文档

/// 空文档用于导出
struct EmptyDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    init() {}
    
    init(configuration: ReadConfiguration) throws {
        // 空实现
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - 状态显示组件

/// 状态卡片组件
struct StatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

/// 按钮状态视图组件
struct ButtonStatusView: View {
    let name: String
    let isPressed: Bool
    
    var displayName: String {
        switch name {
        case "triangle": return "△"
        case "circle": return "○"
        case "cross": return "×"
        case "square": return "□"
        default: return name.uppercased()
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(displayName)
                .font(.caption)
                .fontWeight(.medium)
            
            Circle()
                .fill(isPressed ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(isPressed ? Color.green : Color.gray, lineWidth: 1)
                )
        }
        .frame(height: 60)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
}

/// 摇杆视图组件
struct JoystickView: View {
    let title: String
    let position: CGPoint
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
            
            ZStack {
                // 背景圆
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 100, height: 100)
                
                // 死区圆
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    .frame(width: 30, height: 30)
                
                // 摇杆位置
                Circle()
                    .fill(Color.blue)
                    .frame(width: 20, height: 20)
                    .offset(x: position.x * 40, y: -position.y * 40)
            }
            
            Text("X: \(position.x, specifier: "%.2f"), Y: \(position.y, specifier: "%.2f")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

/// 数据行组件
struct DataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - 游戏手柄可视化组件

/// 游戏手柄按钮视图
struct GamepadButtonView: View {
    let name: String
    let isPressed: Bool
    let x: CGFloat
    let y: CGFloat
    
    var displayName: String {
        switch name {
        case "triangle": return "△"
        case "circle": return "○"
        case "cross": return "×"
        case "square": return "□"
        default: return name
        }
    }
    
    var body: some View {
        Circle()
            .fill(isPressed ? Color.blue : Color.gray.opacity(0.5))
            .frame(width: 30, height: 30)
            .overlay(
                Text(displayName)
                    .font(.caption)
                    .foregroundColor(.white)
            )
            .position(x: x, y: y)
    }
}

/// 摇杆指示器组件
struct JoystickIndicator: View {
    let position: CGPoint
    let x: CGFloat
    let y: CGFloat
    
    var body: some View {
        ZStack {
            // 摇杆底座
            Circle()
                .stroke(Color.gray, lineWidth: 2)
                .frame(width: 40, height: 40)
            
            // 摇杆位置
            Circle()
                .fill(Color.blue)
                .frame(width: 20, height: 20)
                .offset(x: position.x * 15, y: -position.y * 15)
        }
        .position(x: x, y: y)
    }
}

// MARK: - 分区相关组件（基础组件）

/// 信息行组件
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}
