//
//  InputMonitorView.swift
//  GamePadToKey
//

import SwiftUI

struct InputMonitorView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var showRawData = false
    @State private var logEntries: [String] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // 控制栏
            HStack {
                Toggle("显示原始数据", isOn: $showRawData)
                
                Spacer()
                
                Button("清空日志") {
                    logEntries.removeAll()
                }
                
                Button("开始录制") {
                    startRecording()
                }
                
                Button("停止录制") {
                    stopRecording()
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            if showRawData {
                // 原始数据视图
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(logEntries, id: \.self) { entry in
                            Text(entry)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
            } else {
                // 可视化视图
                InputVisualizationView(viewModel: viewModel)
            }
        }
        .onChange(of: viewModel.pressedButtons) { _ in
            logInputEvent()
        }
    }
    
    private func logInputEvent() {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let buttons = viewModel.pressedButtons.sorted().joined(separator: ", ")
        let entry = "[\(timestamp)] 按钮: \(buttons)"
        logEntries.append(entry)
        
        // 限制日志数量
        if logEntries.count > 100 {
            logEntries.removeFirst()
        }
    }
    
    private func startRecording() {
        // 开始录制输入
    }
    
    private func stopRecording() {
        // 停止录制输入
    }
}

struct InputVisualizationView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // 手柄示意图
            GamepadDiagramView(viewModel: viewModel)
            
            // 实时数据
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("实时数据")
                        .font(.headline)
                    
                    DataRow(label: "活动按钮:", value: "\(viewModel.pressedButtons.count)")
                    DataRow(label: "左摇杆:", value: String(format: "X: %.2f, Y: %.2f", 
                        viewModel.joystickPositions["leftJoystick"]?.x ?? 0,
                        viewModel.joystickPositions["leftJoystick"]?.y ?? 0))
                    DataRow(label: "右摇杆:", value: String(format: "X: %.2f, Y: %.2f",
                        viewModel.joystickPositions["rightJoystick"]?.x ?? 0,
                        viewModel.joystickPositions["rightJoystick"]?.y ?? 0))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("系统状态")
                        .font(.headline)
                    
                    DataRow(label: "连接状态:", value: viewModel.isConnected ? "已连接" : "未连接")
                    DataRow(label: "当前分区:", value: viewModel.currentPartition ?? "无")
                    DataRow(label: "电池电量:", value: "\(Int(viewModel.batteryLevel * 100))%")
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
        .padding()
    }
}

struct GamepadDiagramView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack {
            Text("DualSense 手柄示意图")
                .font(.headline)
            
            ZStack {
                // 手柄主体
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 300, height: 150)
                
                // 按钮
                GamepadButtonView(name: "triangle", isPressed: viewModel.pressedButtons.contains("triangle"), x: 100, y: 30)
                GamepadButtonView(name: "circle", isPressed: viewModel.pressedButtons.contains("circle"), x: 130, y: 60)
                GamepadButtonView(name: "cross", isPressed: viewModel.pressedButtons.contains("cross"), x: 100, y: 90)
                GamepadButtonView(name: "square", isPressed: viewModel.pressedButtons.contains("square"), x: 70, y: 60)
                
                // 肩键
                GamepadButtonView(name: "L1", isPressed: viewModel.pressedButtons.contains("L1"), x: 30, y: 30)
                GamepadButtonView(name: "R1", isPressed: viewModel.pressedButtons.contains("R1"), x: 270, y: 30)
                
                // 摇杆
                JoystickIndicator(position: viewModel.joystickPositions["leftJoystick"] ?? .zero, x: 60, y: 120)
                JoystickIndicator(position: viewModel.joystickPositions["rightJoystick"] ?? .zero, x: 240, y: 120)
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

