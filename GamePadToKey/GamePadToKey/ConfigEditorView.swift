//
//  ConfigEditorView.swift
//  GamePadToKey
//

import SwiftUI
import Combine

struct ConfigEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ConfigEditorViewModel
    @State private var selectedTab = 0
    
    init(config: Configuration? = nil) {
        self.viewModel = ConfigEditorViewModel(config: config)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(viewModel.config.name)
                    .font(.headline)
                
                Spacer()
                
                Button("保存") {
                    saveConfiguration()
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("关闭") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 主编辑区
            TabView(selection: $selectedTab) {
                // 基本信息
                ConfigBasicInfoView(viewModel: viewModel)
                    .tabItem {
                        Label("基本信息", systemImage: "info.circle")
                    }
                    .tag(0)
                
                // 分区管理
                PartitionEditorView(viewModel: viewModel)
                    .tabItem {
                        Label("分区", systemImage: "square.grid.3x3")
                    }
                    .tag(1)
                
                // 映射编辑
                MappingEditorView(viewModel: viewModel)
                    .tabItem {
                        Label("映射", systemImage: "keyboard")
                    }
                    .tag(2)
                
                // 反馈设置
                FeedbackEditorView(viewModel: viewModel)
                    .tabItem {
                        Label("反馈", systemImage: "waveform")
                    }
                    .tag(3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private func saveConfiguration() {
        do {
            try viewModel.saveConfiguration()
            presentationMode.wrappedValue.dismiss()
        } catch {
            // 显示错误提示
            print("保存配置失败: \(error)")
        }
    }
}

// MARK: - 配置编辑器ViewModel

class ConfigEditorViewModel: ObservableObject {
    @Published var config: MutableConfiguration
    @Published var selectedPartition: PartitionNode?
    @Published var selectedMapping: Mapping?
    
    private let configManager = ConfigurationManager()
    
    init(config: Configuration? = nil) {
        if let config = config {
            self.config = MutableConfiguration(from: config)
        } else {
            self.config = MutableConfiguration(from: Configuration.createDefault())
        }
    }
    
    func saveConfiguration() throws {
        let immutableConfig = config.toConfiguration()
        try configManager.saveConfiguration(immutableConfig)
    }
    
    func addPartition() {
        let newPartition = Partition(
            id: UUID().uuidString,
            name: "新分区",
            type: .main,
            activationCombo: [],
            children: [],
            mappings: []
        )
        config.partitions.append(newPartition)
    }
    
    func deletePartition(_ partition: Partition) {
        config.partitions.removeAll { $0.id == partition.id }
    }
    
    func addMapping(to partition: Partition) {
        // 创建可变的分区副本
        var updatedPartition = partition
        let newMapping = MappingConfig(
            button: "triangle",
            action: .keyPress,
            key: "a",
            modifiers: []
        )
        
        // 由于 mappings 是 let，我们需要创建一个新的数组
        var newMappings = updatedPartition.mappings
        newMappings.append(newMapping)
        
        // 创建新的分区实例
        let newPartition = Partition(
            id: updatedPartition.id,
            name: updatedPartition.name,
            type: updatedPartition.type,
            activationCombo: updatedPartition.activationCombo,
            bounds: updatedPartition.bounds,
            feedback: updatedPartition.feedback,
            children: updatedPartition.children,
            mappings: newMappings
        )
        
        // 更新配置中的分区
        if let index = config.partitions.firstIndex(where: { $0.id == partition.id }) {
            config.partitions[index] = newPartition
        }
    }
}

// MARK: - 可变的配置结构体
struct MutableConfiguration {
    var configVersion: String
    var name: String
    var author: String
    var description: String
    var globalSettings: MutableGlobalSettings
    var keyboardLayout: KeyboardLayout
    var partitions: [Partition]
    var rootPartition: PartitionNode?
    
    init(from config: Configuration) {
        self.configVersion = config.configVersion
        self.name = config.name
        self.author = config.author
        self.description = config.description
        self.globalSettings = MutableGlobalSettings(from: config.globalSettings)
        self.keyboardLayout = config.keyboardLayout
        self.partitions = config.partitions
        self.rootPartition = config.rootPartition
    }
    
    func toConfiguration() -> Configuration {
        return Configuration(
            configVersion: configVersion,
            name: name,
            author: author,
            description: description,
            globalSettings: globalSettings.toGlobalSettings(),
            keyboardLayout: keyboardLayout,
            partitions: partitions
        )
    }
}

struct MutableGlobalSettings {
    var timeoutSeconds: Double
    var defaultDeadzone: Double
    var mouseSensitivity: Double
    var vibrationEnabled: Bool
    
    init(from settings: GlobalSettings) {
        self.timeoutSeconds = settings.timeoutSeconds
        self.defaultDeadzone = settings.defaultDeadzone
        self.mouseSensitivity = settings.mouseSensitivity
        self.vibrationEnabled = settings.vibrationEnabled
    }
    
    func toGlobalSettings() -> GlobalSettings {
        return GlobalSettings(
            timeoutSeconds: timeoutSeconds,
            defaultDeadzone: defaultDeadzone,
            mouseSensitivity: mouseSensitivity,
            vibrationEnabled: vibrationEnabled
        )
    }
}

// MARK: - 基本信息编辑视图

struct ConfigBasicInfoView: View {
    @ObservedObject var viewModel: ConfigEditorViewModel
    
    var body: some View {
        Form {
            Section("配置信息") {
                TextField("配置名称", text: $viewModel.config.name)
                
                TextField("作者", text: $viewModel.config.author)
                
                TextField("描述", text: $viewModel.config.description)
            }
            
            Section("全局设置") {
                VStack(alignment: .leading) {
                    Text("超时时间: \(viewModel.config.globalSettings.timeoutSeconds, specifier: "%.1f") 秒")
                    Slider(value: $viewModel.config.globalSettings.timeoutSeconds, in: 1...10, step: 0.5)
                }
                
                VStack(alignment: .leading) {
                    Text("默认死区: \(viewModel.config.globalSettings.defaultDeadzone, specifier: "%.2f")")
                    Slider(value: $viewModel.config.globalSettings.defaultDeadzone, in: 0...0.5, step: 0.05)
                }
                
                VStack(alignment: .leading) {
                    Text("鼠标灵敏度: \(viewModel.config.globalSettings.mouseSensitivity, specifier: "%.1f")")
                    Slider(value: $viewModel.config.globalSettings.mouseSensitivity, in: 0.1...3.0, step: 0.1)
                }
                
                Toggle("启用振动反馈", isOn: $viewModel.config.globalSettings.vibrationEnabled)
            }
        }
        .padding()
    }
}

// MARK: - 分区编辑器视图

struct PartitionEditorView: View {
    @ObservedObject var viewModel: ConfigEditorViewModel
    @State private var expandedPartitions: Set<String> = []
    
    var body: some View {
        HSplitView {
            // 左侧：分区树
            VStack {
                HStack {
                    Text("分区结构")
                        .font(.headline)
                    Spacer()
                    Button(action: { viewModel.addPartition() }) {
                        Image(systemName: "plus")
                    }
                }
                .padding()
                
                List {
                    ForEach(viewModel.config.partitions, id: \.id) { partition in
                        PartitionTreeNode(
                            partition: partition,
                            expandedPartitions: $expandedPartitions,
                            onDelete: { viewModel.deletePartition(partition) }
                        )
                    }
                }
            }
            .frame(minWidth: 250)
            
            // 右侧：分区详情
            if let selectedPartition = viewModel.selectedPartition {
                PartitionDetailEditor(partition: selectedPartition)
            } else {
                Text("选择分区以编辑")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct PartitionTreeNode: View {
    let partition: Partition
    @Binding var expandedPartitions: Set<String>
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: expandedPartitions.contains(partition.id) ? "chevron.down" : "chevron.right")
                    .onTapGesture {
                        if expandedPartitions.contains(partition.id) {
                            expandedPartitions.remove(partition.id)
                        } else {
                            expandedPartitions.insert(partition.id)
                        }
                    }
                
                Text(partition.name)
                    .font(.body)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
            if expandedPartitions.contains(partition.id) && !partition.children.isEmpty {
                ForEach(partition.children, id: \.id) { child in
                    PartitionTreeNode(
                        partition: child,
                        expandedPartitions: $expandedPartitions,
                        onDelete: { /* 需要实现删除子分区 */ }
                    )
                    .padding(.leading, 20)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct PartitionDetailEditor: View {
    let partition: PartitionNode
    
    var body: some View {
        Form {
            Section("分区信息") {
                TextField("分区名称", text: .constant(partition.name))
                Picker("分区类型", selection: .constant(partition.type)) {
                    Text("根分区").tag(PartitionType.root)
                    Text("主分区").tag(PartitionType.main)
                    Text("子分区").tag(PartitionType.sub)
                    Text("子子分区").tag(PartitionType.subSub)
                }
            }
            
            Section("激活组合") {
                // 激活组合键选择器
                Text("组合键: \(partition.activationCombo.joined(separator: "+"))")
            }
            
            Section("区域范围") {
                if let bounds = partition.bounds {
                    HStack {
                        Text("X: \(bounds.origin.x, specifier: "%.0f")")
                        Text("Y: \(bounds.origin.y, specifier: "%.0f")")
                        Text("宽: \(bounds.width, specifier: "%.0f")")
                        Text("高: \(bounds.height, specifier: "%.0f")")
                    }
                } else {
                    Text("未设置区域范围")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

// MARK: - 映射编辑器视图

struct MappingEditorView: View {
    @ObservedObject var viewModel: ConfigEditorViewModel
    
    var body: some View {
        VStack {
            Text("映射编辑器")
                .font(.headline)
                .padding()
            
            Text("选择分区以编辑映射")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 反馈编辑器视图

struct FeedbackEditorView: View {
    @ObservedObject var viewModel: ConfigEditorViewModel
    
    var body: some View {
        VStack {
            Text("反馈设置")
                .font(.headline)
                .padding()
            
            Text("配置触觉、视觉和音频反馈")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
