//
//  ContentView.swift
//
//  GamePadToKey
//
//  Created by 苹果 on 2026/2/15.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Image(systemName: "gamecontroller")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("GamePadToKey")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // 连接状态
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(viewModel.isConnected ? "已连接" : "未连接")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 主内容区
            TabView(selection: $selectedTab) {
                // 仪表板
                DashboardView(viewModel: viewModel)
                    .tabItem {
                        Label("仪表板", systemImage: "gauge")
                    }
                    .tag(0)
                
                // 配置管理
                ConfigManagementView(viewModel: viewModel)
                    .tabItem {
                        Label("配置", systemImage: "list.bullet")
                    }
                    .tag(1)
                
                // 输入监控
                InputMonitorView(viewModel: viewModel)
                    .tabItem {
                        Label("监控", systemImage: "waveform.path.ecg")
                    }
                    .tag(2)
                
                // 分区预览
                PartitionPreviewView(viewModel: viewModel)
                    .tabItem {
                        Label("分区", systemImage: "square.grid.3x3")
                    }
                    .tag(3)
                
                // 测试页面
                JoystickTestView(viewModel: viewModel)
                    .tabItem {
                        Label("测试", systemImage: "testtube.2")
                    }
                    .tag(4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 状态栏
            Divider()
            
            HStack {
                Text(viewModel.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let currentPartition = viewModel.currentPartition {
                    Text("当前分区: \(currentPartition)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                if viewModel.batteryLevel > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isCharging ? "battery.100.bolt" : "battery.\(Int(viewModel.batteryLevel * 100))")
                        Text("\(Int(viewModel.batteryLevel * 100))%")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
}
