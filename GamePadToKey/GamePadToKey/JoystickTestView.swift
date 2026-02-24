//
//  JoystickTestView.swift
//  GamePadToKey
//

import SwiftUI

struct JoystickTestView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var leftJoystickPosition = CGPoint.zero
    @State private var rightJoystickPosition = CGPoint.zero
    @State private var touchpadPosition = CGPoint.zero
    @State private var isTouchpadTouching = false
    @State private var testLog: [String] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("摇杆和触摸板测试")
                .font(.title)
                .padding()
            
            HStack(spacing: 30) {
                // 左摇杆测试
                VStack {
                    Text("左摇杆")
                        .font(.headline)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.gray, lineWidth: 2)
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 30, height: 30)
                            .offset(x: leftJoystickPosition.x * 60, 
                                   y: -leftJoystickPosition.y * 60)
                    }
                    .frame(width: 150, height: 150)
                    
                    // 修复 Text 格式化语法
                    Text("X: \(leftJoystickPosition.x, specifier: "%.2f")")
                    Text("Y: \(leftJoystickPosition.y, specifier: "%.2f")")
                }
                
                // 右摇杆测试
                VStack {
                    Text("右摇杆")
                        .font(.headline)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.gray, lineWidth: 2)
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .fill(Color.green)
                            .frame(width: 30, height: 30)
                            .offset(x: rightJoystickPosition.x * 60, 
                                   y: -rightJoystickPosition.y * 60)
                    }
                    .frame(width: 150, height: 150)
                    
                    // 修复 Text 格式化语法
                    Text("X: \(rightJoystickPosition.x, specifier: "%.2f")")
                    Text("Y: \(rightJoystickPosition.y, specifier: "%.2f")")
                }
            }
            
            // 触摸板测试
            VStack {
                Text("触摸板")
                    .font(.headline)
                
                ZStack {
                    Rectangle()
                        .stroke(isTouchpadTouching ? Color.blue : Color.gray, lineWidth: 2)
                        .frame(width: 200, height: 150)
                    
                    if isTouchpadTouching {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                            .offset(x: (touchpadPosition.x - 0.5) * 180, 
                                   y: -(touchpadPosition.y - 0.5) * 130)
                    }
                }
                .frame(width: 200, height: 150)
                
                Text("触摸: \(isTouchpadTouching ? "是" : "否")")
                // 修复 Text 格式化语法
                Text("位置: X: \(touchpadPosition.x, specifier: "%.2f"), Y: \(touchpadPosition.y, specifier: "%.2f")")
            }
            
            // 测试日志
            VStack(alignment: .leading) {
                Text("测试日志")
                    .font(.headline)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(testLog.reversed(), id: \.self) { entry in
                            Text(entry)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 100)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 测试按钮
            HStack {
                Button("开始测试") {
                    startTest()
                }
                
                Button("清空日志") {
                    testLog.removeAll()
                }
                
                Button("激活鼠标分区") {
                    activateMouseZone()
                }
            }
        }
        .padding()
        .onChange(of: viewModel.joystickPositions) { positions in
            updateJoystickPositions(positions)
        }
    }
    
    private func updateJoystickPositions(_ positions: [String: CGPoint]) {
        if let leftPos = positions["leftJoystick"] {
            leftJoystickPosition = leftPos
            // 修复字符串插值语法
            logEvent("左摇杆: X=\(String(format: "%.2f", leftPos.x)), Y=\(String(format: "%.2f", leftPos.y))")
        }
        
        if let rightPos = positions["rightJoystick"] {
            rightJoystickPosition = rightPos
            // 修复字符串插值语法
            logEvent("右摇杆: X=\(String(format: "%.2f", rightPos.x)), Y=\(String(format: "%.2f", rightPos.y))")
        }
    }
    
    private func startTest() {
        testLog.removeAll()
        logEvent("开始摇杆和触摸板测试")
        logEvent("请移动摇杆和触摸触摸板")
    }
    
    private func activateMouseZone() {
        logEvent("尝试激活鼠标控制分区")
        // 这里需要模拟按下 L1 + R1 + touchpad 按钮
        // 在实际应用中，这应该通过输入处理器完成
    }
    
    private func logEvent(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let entry = "[\(timestamp)] \(message)"
        testLog.append(entry)
        
        if testLog.count > 20 {
            testLog.removeFirst()
        }
    }
}
