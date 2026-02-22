//
//  DashboardView.swift
//  GamePadToKey
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 快速操作
                HStack(spacing: 20) {
                    QuickActionButton(
                        title: "新建配置",
                        icon: "plus.circle",
                        color: .blue,
                        action: { viewModel.createNewConfig() }
                    )
                    
                    QuickActionButton(
                        title: "导入配置",
                        icon: "square.and.arrow.down",
                        color: .green,
                        action: { /* 导入配置 */ }
                    )
                    
                    QuickActionButton(
                        title: "导出配置",
                        icon: "square.and.arrow.up",
                        color: .orange,
                        action: { /* 导出配置 */ }
                    )
                    
                    QuickActionButton(
                        title: "编辑配置",
                        icon: "pencil",
                        color: .purple,
                        action: { viewModel.showConfigEditor = true }
                    )
                }
                .padding(.top)
                
                // 状态卡片
                HStack(spacing: 20) {
                    StatusCard(
                        title: "连接状态",
                        value: viewModel.isConnected ? "已连接" : "未连接",
                        icon: viewModel.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill",
                        color: viewModel.isConnected ? .green : .red
                    )
                    
                    StatusCard(
                        title: "当前分区",
                        value: viewModel.currentPartition ?? "无",
                        icon: "square.grid.3x3",
                        color: .blue
                    )
                    
                    StatusCard(
                        title: "电池电量",
                        value: "\(Int(viewModel.batteryLevel * 100))%",
                        icon: viewModel.isCharging ? "battery.100.bolt" : "battery.75",
                        color: viewModel.batteryLevel > 0.2 ? .green : .red
                    )
                }
                
                // 按钮状态显示
                VStack(alignment: .leading, spacing: 12) {
                    Text("按钮状态")
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(["triangle", "circle", "cross", "square", "L1", "R1", "L2", "R2", "up", "down", "left", "right"], id: \.self) { button in
                            ButtonStatusView(
                                name: button,
                                isPressed: viewModel.pressedButtons.contains(button)
                            )
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // 摇杆状态
                HStack(spacing: 20) {
                    JoystickView(
                        title: "左摇杆",
                        position: viewModel.joystickPositions["leftJoystick"] ?? .zero
                    )
                    
                    JoystickView(
                        title: "右摇杆",
                        position: viewModel.joystickPositions["rightJoystick"] ?? .zero
                    )
                }
            }
            .padding()
        }
        // 新建配置对话框
        .sheet(isPresented: $viewModel.showNewConfigDialog) {
            NewConfigDialog(viewModel: viewModel)
        }
        // 配置编辑器
        .sheet(isPresented: $viewModel.showConfigEditor) {
            ConfigEditorView()
        }
    }
}

// 新建配置对话框
struct NewConfigDialog: View {
    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text("新建配置")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("配置名称")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("输入配置名称", text: $viewModel.newConfigName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
            }
            
            HStack(spacing: 20) {
                Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("创建") {
                    viewModel.createNewConfigWithName()
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.newConfigName.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}

// 配置编辑器视图（简化版）
struct ConfigEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("配置编辑器")
                .font(.headline)
                .padding()
            
            Text("配置编辑器功能正在开发中...")
                .foregroundColor(.secondary)
            
            Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .frame(width: 400, height: 300)
    }
}

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
