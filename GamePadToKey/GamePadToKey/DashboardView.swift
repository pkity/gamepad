//
//  DashboardView.swift
//  GamePadToKey
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: ContentViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 状态卡片
                HStack(spacing: 20) {
                    StatusCard(
                        title: "连接状态",
                        value: viewModel.isConnected ? "已连接" : "未连接",
                        icon: viewModel.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill",
                        color: viewModel.isConnected ? .green : .red
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
                        position: viewModel.joystickPositions["left"] ?? .zero
                    )

                    JoystickView(
                        title: "右摇杆",
                        position: viewModel.joystickPositions["right"] ?? .zero
                    )
                }
            }
            .padding()
        }
    }
}
