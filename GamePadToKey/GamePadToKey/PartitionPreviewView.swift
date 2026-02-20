//
//  PartitionPreviewView.swift
//  GamePadToKey
//

import SwiftUI

struct PartitionPreviewView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var selectedPartition: String?
    @State private var partitionTree: [PartitionNode] = []
    
    var body: some View {
        HSplitView {
            // 左侧：分区树
            PartitionTreeView(partitions: partitionTree, selectedPartition: $selectedPartition)
                .frame(minWidth: 200, maxWidth: 300)
            
            // 右侧：分区详情
            if let partitionName = selectedPartition {
                PartitionDetailView(partitionName: partitionName)
            } else {
                VStack {
                    Image(systemName: "square.grid.3x3")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("选择分区以查看详情")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            loadPartitionTree()
        }
        .onChange(of: viewModel.currentPartition) { newValue in
            selectedPartition = newValue
        }
    }
    
    private func loadPartitionTree() {
        // 这里应该从配置管理器加载分区树
        // 暂时使用示例数据
        partitionTree = createSamplePartitionTree()
    }
    
    private func createSamplePartitionTree() -> [PartitionNode] {
        let root = PartitionNode(id: "root", name: "根分区", type: .root)
        
        let main1 = PartitionNode(id: "main1", name: "主分区1", type: .main)
        main1.parent = root
        main1.activationCombo = ["L1", "R1"]
        
        let sub1 = PartitionNode(id: "sub1", name: "子分区1", type: .sub)
        sub1.parent = main1
        sub1.activationCombo = ["triangle"]
        
        let sub2 = PartitionNode(id: "sub2", name: "子分区2", type: .sub)
        sub2.parent = main1
        sub2.activationCombo = ["circle"]
        
        main1.children = [sub1, sub2]
        
        let main2 = PartitionNode(id: "main2", name: "主分区2", type: .main)
        main2.parent = root
        main2.activationCombo = ["L2", "R2"]
        
        root.children = [main1, main2]
        
        return [root]
    }
}
// 分区树视图
struct PartitionTreeView: View {
    let partitions: [PartitionNode]
    @Binding var selectedPartition: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Text("分区树")
                    .font(.headline)
                Spacer()
                Button(action: refreshTree) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // 分区列表
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(partitions, id: \.id) { partition in
                        PartitionTreeNodeView(node: partition, selectedPartition: $selectedPartition, level: 0)
                    }
                }
                .padding()
            }
        }
    }
    
    private func refreshTree() {
        // 刷新分区树
    }
}

// 分区树节点视图
struct PartitionTreeNodeView: View {
    let node: PartitionNode
    @Binding var selectedPartition: String?
    let level: Int
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // 节点本身
            HStack {
                // 缩进
                ForEach(0..<level, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .padding(.leading, 4)
                }
                
                // 展开/折叠按钮
                if !node.children.isEmpty {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .frame(width: 16)
                } else {
                    Spacer()
                        .frame(width: 16)
                }
                
                // 分区图标
                Image(systemName: iconForPartitionType(node.type))
                    .foregroundColor(colorForPartitionType(node.type))
                    .frame(width: 16)
                
                // 分区名称
                Text(node.name)
                    .font(.body)
                    .lineLimit(1)
                
                Spacer()
                
                // 激活组合键
                if !node.activationCombo.isEmpty {
                    Text(node.activationCombo.joined(separator: "+"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
                
                // 选中指示器
                if selectedPartition == node.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(selectedPartition == node.id ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            .onTapGesture {
                selectedPartition = node.id
            }
            
            // 子节点
            if isExpanded && !node.children.isEmpty {
                ForEach(node.children, id: \.id) { child in
                    PartitionTreeNodeView(node: child, selectedPartition: $selectedPartition, level: level + 1)
                }
            }
        }
    }
    
    private func iconForPartitionType(_ type: PartitionType) -> String {
        switch type {
        case .root: return "square.grid.3x3"
        case .main: return "square.grid.2x2"
        case .sub: return "square.grid.1x2"
        case .subSub: return "square"
        }
    }
    
    private func colorForPartitionType(_ type: PartitionType) -> Color {
        switch type {
        case .root: return .blue
        case .main: return .green
        case .sub: return .orange
        case .subSub: return .purple
        }
    }
}

// 分区详情视图
struct PartitionDetailView: View {
    let partitionName: String
    @State private var partitionInfo: PartitionNode?
    @State private var mappings: [String: Mapping] = [:]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 分区基本信息
                VStack(alignment: .leading, spacing: 12) {
                    Text(partitionName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let partition = partitionInfo {
                        HStack(spacing: 20) {
                            InfoRow(label: "类型:", value: stringForPartitionType(partition.type))
                            InfoRow(label: "激活组合:", value: partition.activationCombo.joined(separator: "+"))
                            InfoRow(label: "子分区数:", value: "\(partition.children.count)")
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // 按钮映射
                VStack(alignment: .leading, spacing: 12) {
                    Text("按钮映射")
                        .font(.headline)
                    
                    if mappings.isEmpty {
                        Text("暂无映射配置")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(Array(mappings.keys.sorted()), id: \.self) { button in
                                if let mapping = mappings[button] {
                                    MappingCard(button: button, mapping: mapping)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // 摇杆映射
                VStack(alignment: .leading, spacing: 12) {
                    Text("摇杆映射")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        JoystickMappingCard(joystick: "左摇杆", mapping: partitionInfo?.joystickMappings[.left])
                        JoystickMappingCard(joystick: "右摇杆", mapping: partitionInfo?.joystickMappings[.right])
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
            .padding()
        }
        .onAppear {
            loadPartitionInfo()
        }
    }
    
    private func loadPartitionInfo() {
        // 这里应该从配置管理器加载分区信息
        // 暂时使用示例数据
        partitionInfo = createSamplePartitionInfo()
        if let partition = partitionInfo {
            mappings = partition.mappings
        }
    }
    
    private func createSamplePartitionInfo() -> PartitionNode {
        let partition = PartitionNode(id: "sample", name: partitionName, type: .main)
        partition.activationCombo = ["L1", "R1"]
        
        // 添加示例映射
        partition.mappings["triangle"] = Mapping(button: "triangle", action: .keyPress(key: "A", modifiers: []))
        partition.mappings["circle"] = Mapping(button: "circle", action: .keyPress(key: "B", modifiers: []))
        partition.mappings["cross"] = Mapping(button: "cross", action: .keyPress(key: "C", modifiers: []))
        partition.mappings["square"] = Mapping(button: "square", action: .keyPress(key: "D", modifiers: []))
        
        return partition
    }
    
    private func stringForPartitionType(_ type: PartitionType) -> String {
        switch type {
        case .root: return "根分区"
        case .main: return "主分区"
        case .sub: return "子分区"
        case .subSub: return "子子分区"
        }
    }
}

// 信息行组件
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

// 映射卡片组件
struct MappingCard: View {
    let button: String
    let mapping: Mapping
    
    var buttonDisplayName: String {
        switch button {
        case "triangle": return "△"
        case "circle": return "○"
        case "cross": return "×"
        case "square": return "□"
        default: return button.uppercased()
        }
    }
    
    var actionDescription: String {
        switch mapping.action {
        case .keyPress(let key, let modifiers):
            if modifiers.isEmpty {
                return "按键: \(key)"
            } else {
                return "按键: \(modifiers.joined(separator: "+"))+\(key)"
            }
        case .keyCombo(let keys):
            return "组合键: \(keys.joined(separator: "+"))"
        case .mouseMove(let sensitivity, let acceleration):
            return "鼠标移动 (灵敏度: \(sensitivity))"
        case .mouseClick(let button, let mode):
            return "鼠标点击: \(button)"
        case .mouseScroll(let axis, let sensitivity):
            return "鼠标滚动 (\(axis))"
        case .macro(let id):
            return "宏: \(id)"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(buttonDisplayName)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(actionDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// 摇杆映射卡片组件
struct JoystickMappingCard: View {
    let joystick: String
    let mapping: Mapping?
    
    var body: some View {
        VStack(spacing: 12) {
            Text(joystick)
                .font(.headline)
            
            if let mapping = mapping {
                switch mapping.action {
                case .mouseMove(let sensitivity, let acceleration):
                    VStack(spacing: 4) {
                        Text("鼠标移动")
                            .fontWeight(.medium)
                        Text("灵敏度: \(sensitivity, specifier: "%.1f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("加速度: \(acceleration ? "开启" : "关闭")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                case .mouseScroll(let axis, let sensitivity):
                    VStack(spacing: 4) {
                        Text("鼠标滚动")
                            .fontWeight(.medium)
                        Text("方向: \(axis == .horizontal ? "水平" : "垂直")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("灵敏度: \(sensitivity, specifier: "%.1f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                default:
                    Text("其他映射")
                        .foregroundColor(.secondary)
                }
            } else {
                Text("未配置")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

