//
//  ContentView.swift
//  GamePadService
//
//  Created by 苹果 on 2025/11/23.
//

import SwiftUI

// 连接状态组件
struct ConnectionStatusView: View {
    @ObservedObject var controllerManager: GameControllerManager
    
    var body: some View {
        HStack {
            Circle()
                .fill(controllerManager.dualSenseController != nil ? Color.green : Color.red)
                .frame(width: 12, height: 12)
            
            Text(controllerManager.dualSenseController != nil ?
                 "DualSense 已连接" : "等待控制器连接...")
                .font(.headline)
        }
    }
}

// 按钮状态网格组件
struct ButtonStatusGridView: View {
    @ObservedObject var controllerManager: GameControllerManager
    
    let buttonColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("按钮状态")
                .font(.title2)
                .bold()
            
            LazyVGrid(columns: buttonColumns, spacing: 15) {
                ForEach(getSortedButtonStates(), id: \.0) { name, isPressed in
                    ButtonIndicatorView(name: name, isPressed: isPressed)
                }
            }
        }
    }
    
    private func getSortedButtonStates() -> [(String, Bool)] {
        let commonOrder = ["A", "B", "X", "Y", "L1", "R1", "L2", "R2"]
        var result: [(String, Bool)] = []
        
        for buttonName in commonOrder {
            if let isPressed = controllerManager.buttonStates[buttonName] {
                result.append((buttonName, isPressed))
            }
        }
        
        // 添加其他按钮
        let otherButtons = controllerManager.buttonStates.keys
            .filter { !commonOrder.contains($0) }
            .sorted()
        
        for buttonName in otherButtons {
            if let isPressed = controllerManager.buttonStates[buttonName] {
                result.append((buttonName, isPressed))
            }
        }
        
        return result
    }
}

// 按钮指示器组件
struct ButtonIndicatorView: View {
    let name: String
    let isPressed: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isPressed ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Circle()
                    .stroke(isPressed ? Color.blue : Color.gray, lineWidth: 2)
                    .frame(width: 60, height: 60)
                
                Text(name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isPressed ? .white : .primary)
            }
            
            Text(isPressed ? "按下" : "释放")
                .font(.caption)
                .foregroundColor(isPressed ? .blue : .secondary)
        }
    }
}

// 摇杆数据显示组件
struct ThumbstickDisplayView: View {
    @ObservedObject var controllerManager: GameControllerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("摇杆数据")
                .font(.title2)
                .bold()
            
            HStack(spacing: 30) {
                ThumbstickDataView(title: "左摇杆", x: controllerManager.leftThumbstick.x, y: controllerManager.leftThumbstick.y) // 这里需要从 manager 获取真实数据
                ThumbstickDataView(title: "右摇杆", x: controllerManager.rightThumbstick.x, y: controllerManager.rightThumbstick.y) // 这里需要从 manager 获取真实数据
            }
        }
    }
}

struct ThumbstickDataView: View {
    let title: String
    let x: Float
    let y: Float
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack {
                VStack {
                    Text("X轴")
                    Text(String(format: "%.2f", x))
                        .font(.system(.body, design: .monospaced))
                }
                
                VStack {
                    Text("Y轴")
                    Text(String(format: "%.2f", y))
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct BluetoothViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> BluetoothViewController {
        return BluetoothViewController()
    }
    
    func updateUIViewController(_ uiViewController: BluetoothViewController, context: Context) {
        // 如果需要更新视图控制器，在这里实现
    }
}

struct ContentView: View {
    let controllerManager = GameControllerManager()
    let bluetoothController = BluetoothViewController()
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            
            // 连接状态
            ConnectionStatusView(controllerManager: controllerManager)
            
            // 按钮状态显示
            ButtonStatusGridView(controllerManager: controllerManager)
            
            // 摇杆数据显示
            ThumbstickDisplayView(controllerManager: controllerManager)
            
            // 使用包装后的 BluetoothViewController
            BluetoothViewControllerRepresentable()
                            .frame(height: 200)
                            .cornerRadius(10)
                            .padding()
        }
        .padding()
        .navigationTitle("DualSense 控制器")
    }
}

#Preview {
    ContentView()
}
