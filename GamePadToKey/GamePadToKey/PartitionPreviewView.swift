//
//  PartitionPreviewView.swift
//  GamePadToKey
//

import SwiftUI

struct PartitionPreviewView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var selectedPartitionId: String?
    @State private var partitionTree: [PartitionNode] = []
    @State private var selectedPartitionNode: PartitionNode?
    
    var body: some View {
        HSplitView {
            // 左侧：分区树
            PartitionTreeView(
                partitions: partitionTree,
                selectedPartitionId: $selectedPartitionId,
                selectedPartitionNode: $selectedPartitionNode
            )
            .frame(minWidth: 200, maxWidth: 300)
            
            // 右侧：分区详情
            if let partitionNode = selectedPartitionNode {
                PartitionDetailContentView(partition: partitionNode)
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
            selectedPartitionId = newValue
            // 根据ID查找对应的节点
            selectedPartitionNode = findPartitionNode(by: newValue, in: partitionTree)
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
    
    private func findPartitionNode(by id: String?, in nodes: [PartitionNode]) -> PartitionNode? {
        guard let id = id else { return nil }
        
        for node in nodes {
            if node.id == id {
                return node
            }
            if let found = findPartitionNode(by: id, in: node.children) {
                return found
            }
        }
        return nil
    }
}

// 分区树视图
struct PartitionTreeView: View {
    let partitions: [PartitionNode]
    @Binding var selectedPartitionId: String?
    @Binding var selectedPartitionNode: PartitionNode?
    
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
                        PartitionTreeNodeContentView(
                            node: partition,
                            selectedPartitionId: $selectedPartitionId,
                            selectedPartitionNode: $selectedPartitionNode,
                            level: 0
                        )
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

// 分区树节点视图（重命名以避免冲突）
struct PartitionTreeNodeContentView: View {
    let node: PartitionNode
    @Binding var selectedPartitionId: String?
    @Binding var selectedPartitionNode: PartitionNode?
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
                if selectedPartitionId == node.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(selectedPartitionId == node.id ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            .onTapGesture {
                selectedPartitionId = node.id
                selectedPartitionNode = node
            }
            
            // 子节点
            if isExpanded && !node.children.isEmpty {
                ForEach(node.children, id: \.id) { child in
                    PartitionTreeNodeContentView(
                        node: child,
                        selectedPartitionId: $selectedPartitionId,
                        selectedPartitionNode: $selectedPartitionNode,
                        level: level + 1
                    )
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

// 分区详情内容视图（重命名以避免冲突）
struct PartitionDetailContentView: View {
    let partition: PartitionNode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 分区基本信息
                VStack(alignment: .leading, spacing: 12) {
                    Text(partition.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 20) {
                        InfoRow(label: "类型:", value: stringForPartitionType(partition.type))
                        InfoRow(label: "激活组合:", value: partition.activationCombo.joined(separator: "+"))
                        InfoRow(label: "子分区数:", value: "\(partition.children.count)")
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // 按钮映射
                if !partition.mappings.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("按钮映射")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(Array(partition.mappings.keys.sorted()), id: \.self) { button in
                                if let mapping = partition.mappings[button] {
                                    MappingCard(button: button, mapping: mapping)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // 摇杆映射
                if !partition.joystickMappings.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("摇杆映射")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            JoystickMappingCard(
                                joystick: "左摇杆",
                                mapping: partition.joystickMappings[.left]
                            )
                            JoystickMappingCard(
                                joystick: "右摇杆",
                                mapping: partition.joystickMappings[.right]
                            )
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // 触摸板映射
                if partition.touchpadMapping != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("触摸板映射")
                            .font(.headline)
                        
                        Text("已配置触摸板映射")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // 运动传感器映射
                if partition.motionMapping != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("运动传感器映射")
                            .font(.headline)
                        
                        Text("已配置运动传感器映射")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
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
