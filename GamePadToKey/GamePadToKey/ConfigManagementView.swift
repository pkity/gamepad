//
//  ConfigManagementView.swift
//  GamePadToKey
//

import SwiftUI

struct ConfigManagementView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var configs: [String] = []
    @State private var selectedConfig: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack {
                Button(action: { viewModel.createNewConfig() }) {
                    Label("新建", systemImage: "plus")
                }
                
                Button(action: importConfig) {
                    Label("导入", systemImage: "square.and.arrow.down")
                }
                
                Button(action: exportConfig) {
                    Label("导出", systemImage: "square.and.arrow.up")
                }
                
                Spacer()
                
                Button(action: refreshConfigs) {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // 配置列表
            List(configs, id: \.self, selection: $selectedConfig) { config in
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(config)
                            .font(.body)
                        
                        Text("最后修改: 今天")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if selectedConfig == config {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedConfig = config
                    viewModel.loadConfig(config)
                }
            }
            .listStyle(SidebarListStyle())
        }
        .onAppear {
            refreshConfigs()
        }
        // 新建配置对话框
        .sheet(isPresented: $viewModel.showNewConfigDialog) {
            NewConfigDialog(viewModel: viewModel)
        }
    }
    
    private func refreshConfigs() {
        let configManager = ConfigurationManager()
        configs = configManager.getAvailableConfigs()
    }
    
    private func importConfig() {
        // 实现导入配置逻辑
    }
    
    private func exportConfig() {
        // 实现导出配置逻辑
    }
}
