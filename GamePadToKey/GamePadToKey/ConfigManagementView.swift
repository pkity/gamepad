//
//  ConfigManagementView.swift
//  GamePadToKey
//

import SwiftUI
import UniformTypeIdentifiers

struct ConfigManagementView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var configs: [String] = []
    @State private var selectedConfig: String?
    @State private var showImportDialog = false
    @State private var showExportDialog = false
    @State private var showDeleteAlert = false
    @State private var configToDelete: String?
    @State private var showDuplicateDialog = false
    @State private var duplicateName = ""
    @State private var configToDuplicate: String?
    @State private var showConfigEditor = false
    @State private var selectedConfigForEdit: String?
    
    private let configManager = ConfigurationManager()
    private let jsonType = UTType.json
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack {
                Button(action: { viewModel.createNewConfig() }) {
                    Label("新建", systemImage: "plus")
                }
                
                Button(action: { showImportDialog = true }) {
                    Label("导入", systemImage: "square.and.arrow.down")
                }
                
                Button(action: { 
                    if let selected = selectedConfig {
                        configToDuplicate = selected
                        duplicateName = "\(selected)_副本"
                        showDuplicateDialog = true
                    }
                }) {
                    Label("复制", systemImage: "doc.on.doc")
                }
                .disabled(selectedConfig == nil)
                
                Button(action: { 
                    if let selected = selectedConfig {
                        selectedConfigForEdit = selected
                        showConfigEditor = true
                    }
                }) {
                    Label("编辑", systemImage: "pencil")
                }
                .disabled(selectedConfig == nil)
                
                Button(action: { 
                    if let selected = selectedConfig {
                        showExportDialog = true
                    }
                }) {
                    Label("导出", systemImage: "square.and.arrow.up")
                }
                .disabled(selectedConfig == nil)
                
                Spacer()
                
                Button(action: refreshConfigs) {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                
                Button(action: { 
                    if let selected = selectedConfig {
                        configToDelete = selected
                        showDeleteAlert = true
                    }
                }) {
                    Label("删除", systemImage: "trash")
                }
                .disabled(selectedConfig == nil)
                .foregroundColor(.red)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // 配置列表
            if configs.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("暂无配置")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("点击上方的新建按钮创建第一个配置")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
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
                    .contextMenu {
                        Button("编辑") {
                            selectedConfigForEdit = config
                            showConfigEditor = true
                        }
                        
                        Button("复制") {
                            configToDuplicate = config
                            duplicateName = "\(config)_副本"
                            showDuplicateDialog = true
                        }
                        
                        Button("导出") {
                            selectedConfig = config
                            showExportDialog = true
                        }
                        
                        Divider()
                        
                        Button("删除") {
                            configToDelete = config
                            showDeleteAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
                .listStyle(SidebarListStyle())
            }
        }
        .onAppear {
            refreshConfigs()
        }
        // 新建配置对话框
        .sheet(isPresented: $viewModel.showNewConfigDialog) {
            NewConfigDialog(viewModel: viewModel)
        }
        // 配置编辑器
        .sheet(isPresented: $showConfigEditor) {
            if let configName = selectedConfigForEdit {
                ConfigEditorWrapper(configName: configName, isPresented: $showConfigEditor)
            }
        }
        // 导入文件选择器
        .fileImporter(
            isPresented: $showImportDialog,
            allowedContentTypes: [jsonType],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
        // 导出文件选择器
        .fileExporter(
            isPresented: $showExportDialog,
            document: ConfigDocument(configName: selectedConfig ?? ""),
            contentType: jsonType,
            defaultFilename: selectedConfig ?? "configuration"
        ) { result in
            handleExportResult(result)
        }
        // 删除确认对话框
        .alert("删除配置", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteSelectedConfig()
            }
        } message: {
            Text("确定要删除配置 \"\(configToDelete ?? "")\" 吗？此操作无法撤销。")
        }
        // 复制配置对话框
        .alert("复制配置", isPresented: $showDuplicateDialog) {
            TextField("新配置名称", text: $duplicateName)
            
            Button("取消", role: .cancel) { 
                duplicateName = ""
                configToDuplicate = nil
            }
            Button("复制") {
                duplicateSelectedConfig()
            }
        } message: {
            Text("为新配置输入一个名称")
        }
    }
    
    private func refreshConfigs() {
        configs = configManager.getAvailableConfigs()
        if selectedConfig == nil && !configs.isEmpty {
            selectedConfig = configs.first
            if let firstConfig = configs.first {
                viewModel.loadConfig(firstConfig)
            }
        }
    }
    
    private func handleImportResult(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }
            
            // 导入配置
            let importedConfig = try configManager.importConfiguration(from: url)
            
            // 刷新列表
            refreshConfigs()
            
            // 选中并加载新配置
            selectedConfig = importedConfig.name
            viewModel.loadConfig(importedConfig.name)
            
            // 显示成功消息
            viewModel.statusMessage = "已导入配置: \(importedConfig.name)"
            
        } catch {
            viewModel.statusMessage = "导入失败: \(error.localizedDescription)"
        }
    }
    
    private func handleExportResult(_ result: Result<URL, Error>) {
        guard let configName = selectedConfig else { return }
        
        do {
            let url = try result.get()
            
            // 加载配置
            let config = try configManager.loadConfiguration(named: configName)
            
            // 导出配置
            try configManager.exportConfiguration(config, to: url)
            
            viewModel.statusMessage = "已导出配置到: \(url.lastPathComponent)"
            
        } catch {
            viewModel.statusMessage = "导出失败: \(error.localizedDescription)"
        }
    }
    
    private func deleteSelectedConfig() {
        guard let configName = configToDelete else { return }
        
        do {
            try configManager.deleteConfiguration(named: configName)
            
            // 刷新列表
            refreshConfigs()
            
            // 清除选择
            selectedConfig = nil
            configToDelete = nil
            
            viewModel.statusMessage = "已删除配置: \(configName)"
            
        } catch {
            viewModel.statusMessage = "删除失败: \(error.localizedDescription)"
        }
    }
    
    private func duplicateSelectedConfig() {
        guard let sourceName = configToDuplicate else { return }
        
        do {
            try configManager.duplicateConfiguration(named: sourceName, newName: duplicateName)
            
            // 刷新列表
            refreshConfigs()
            
            // 选中新配置
            selectedConfig = duplicateName
            viewModel.loadConfig(duplicateName)
            
            // 重置状态
            duplicateName = ""
            configToDuplicate = nil
            
            viewModel.statusMessage = "已复制配置为: \(duplicateName)"
            
        } catch {
            viewModel.statusMessage = "复制失败: \(error.localizedDescription)"
        }
    }
}
// MARK: - 配置文档（用于导出）
struct ConfigDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    let configName: String
    
    init(configName: String) {
        self.configName = configName
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.configName = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let configManager = ConfigurationManager()
        let config = try configManager.loadConfiguration(named: configName)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(config)
        
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - 配置编辑器包装器
struct ConfigEditorWrapper: View {
    let configName: String
    @Binding var isPresented: Bool
    @State private var config: Configuration?
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("加载配置...")
                    .frame(width: 400, height: 300)
            } else if let error = error {
                VStack {
                    Text("加载失败")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .foregroundColor(.secondary)
                    Button("关闭") {
                        isPresented = false
                    }
                    .padding()
                }
                .frame(width: 400, height: 300)
            } else if let config = config {
                ConfigEditorView(config: config)
            }
        }
        .onAppear {
            loadConfiguration()
        }
    }
    
    private func loadConfiguration() {
        let configManager = ConfigurationManager()
        
        do {
            config = try configManager.loadConfiguration(named: configName)
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
}

// MARK: - 新建配置对话框
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

