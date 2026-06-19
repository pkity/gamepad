import SwiftUI
import Combine
import GameController

class ContentViewModel: ObservableObject {
    
    // MARK: - Connection and status
    @Published var isConnected: Bool = false
    @Published var statusMessage: String = ""
    @Published var batteryLevel: Float = 0.0
    @Published var isCharging: Bool = false
    
    // MARK: - Input state
    @Published var pressedButtons: [String] = []
    @Published var joystickPositions: [String: CGPoint] = [:]
    @Published var touchpadPosition: CGPoint = .zero
    @Published var touchpadTouching: Bool = false
    
    private var gamepad: GCController?
    private var batteryTimer: AnyCancellable?
    
    // Keep previous joystick values to avoid redundant updates
    private var previousLeftStick: CGPoint = .zero
    private var previousRightStick: CGPoint = .zero
    private let joystickDeadzone: CGFloat = 0.05
    
    // MARK: - Lifecycle
    func startMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidConnect),
            name: .GCControllerDidConnect,
            object: nil
        )
        if let current = GCController.controllers().first {
            connectTo(controller: current)
        }
        isConnected = (GCController.controllers().first != nil)
        statusMessage = isConnected ? "已连接" : "等待手柄..."
    }
    
    func stopMonitoring() {
        NotificationCenter.default.removeObserver(self, name: .GCControllerDidConnect, object: nil)
        batteryTimer?.cancel()
    }
    
    @objc private func controllerDidConnect(_ notification: Notification) {
        if let controller = notification.object as? GCController {
            connectTo(controller: controller)
        }
    }
    
    private func connectTo(controller: GCController) {
        self.gamepad = controller
        
        // Battery monitoring
        batteryTimer?.cancel()
        batteryTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let battery = self.gamepad?.battery else { return }
                self.batteryLevel = battery.batteryLevel
                switch battery.batteryState {
                case .charging:
                    self.isCharging = true
                case .full:
                    self.isCharging = false
                case .discharging, .unknown:
                    self.isCharging = false
                @unknown default:
                    self.isCharging = false
                }
            }
        
        guard let extended = controller.extendedGamepad else { return }
        
        // Button mappings
        let buttonMap: [(GCControllerButtonInput, String)] = [
            (extended.buttonA, "cross"),
            (extended.buttonB, "circle"),
            (extended.buttonX, "square"),
            (extended.buttonY, "triangle"),
            (extended.leftShoulder, "L1"),
            (extended.rightShoulder, "R1"),
            (extended.leftTrigger, "L2"),
            (extended.rightTrigger, "R2"),
            (extended.leftThumbstickButton!, "L3"),
            (extended.rightThumbstickButton!, "R3"),
            (extended.dpad.up, "dpadUp"),
            (extended.dpad.down, "dpadDown"),
            (extended.dpad.left, "dpadLeft"),
            (extended.dpad.right, "dpadRight"),
            (extended.buttonMenu, "options"),
            (extended.buttonOptions!, "share")
        ]
        
        for (input, name) in buttonMap {
            input.valueChangedHandler = { [weak self] (_, _, _) in
                self?.updateButton(name: name, pressed: input.isPressed)
            }
        }
        
        // Joysticks – with deadzone filtering to avoid excessive updates
        extended.leftThumbstick.valueChangedHandler = { [weak self] (_, x, y) in
            self?.updateJoystick(name: "left", x: CGFloat(x), y: CGFloat(y))
        }
        extended.rightThumbstick.valueChangedHandler = { [weak self] (_, x, y) in
            self?.updateJoystick(name: "right", x: CGFloat(x), y: CGFloat(y))
        }
        
        // Touchpad support will be added later.
        // For now, touchpadPosition and touchpadTouching remain at zero/false.
        
        isConnected = true
        statusMessage = "手柄已连接"
    }
    
    private func updateButton(name: String, pressed: Bool) {
        if pressed {
            if !pressedButtons.contains(name) {
                pressedButtons.append(name)
            }
        } else {
            pressedButtons.removeAll { $0 == name }
        }
    }
    
    private func updateJoystick(name: String, x: CGFloat, y: CGFloat) {
        let point = CGPoint(x: x, y: y)
        let previous: CGPoint = (name == "left") ? previousLeftStick : previousRightStick
        
        let dx = abs(point.x - previous.x)
        let dy = abs(point.y - previous.y)
        if dx > joystickDeadzone || dy > joystickDeadzone {
            if name == "left" { previousLeftStick = point }
            else { previousRightStick = point }
            joystickPositions[name] = point
        }
    }
}
