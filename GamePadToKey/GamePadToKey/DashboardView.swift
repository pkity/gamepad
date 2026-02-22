//
//  DashboardView.swift
//  GamePadToKey
//

import SwiftUI
import UniformTypeIdentifiers

struct DashboardView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var showImportDialog = false
    @State private var showExportDialog = false
    @State private var showConfigEditor = false
    
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
                        action: { showImportDialog = true }
                    )
                    
                    QuickActionButton(
                        title: "导出配置",
                        icon: "square.and.arrow.up",
                        color: .orange,
                        action: { showExportDialog = true }
                    )
                    
                    QuickActionButton(
                        title: "编辑配置",
                        icon: "pencil",
                        color: .purple,
                        action: { showConfigEditor = true }
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
        .sheet(isPresented: $showConfigEditor) {
            ConfigEditorView()
        }
        // 导入文件选择器
        .fileImporter(
            isPresented: $showImportDialog,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
        // 导出文件选择器
        .fileExporter(
            isPresented: $showExportDialog,
            document: EmptyDocument(),
            contentType: .json,
            defaultFilename: "configuration"
        ) { result in
            handleExportResult(result)
        }
    }
    
    private func handleImportResult(_ result: Result<[URL], Error>) {
        // 处理导入结果
        print("导入结果: \(result)")
    }
    
    private func handleExportResult(_ result: Result<URL, Error>) {
        // 处理导出结果
        print("导出结果: \(result)")
    }
}

