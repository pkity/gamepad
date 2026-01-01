//
//  BluetoothKeyboard.swift
//  GamePadService
//
//  Created by 苹果 on 2025/11/23.
//

import CoreBluetooth
import UIKit

class BluetoothKeyboardManager: NSObject {
    static let shared = BluetoothKeyboardManager()
    
    private var peripheralManager: CBPeripheralManager!
    private var connectedCentral: CBCentral?
    
    // HID 服务 UUID
    private let hidServiceUUID = CBUUID(string: "1812")
    private let reportUUID = CBUUID(string: "2A4D")
    private let reportMapUUID = CBUUID(string: "2A4B")
    private let hidInformationUUID = CBUUID(string: "2A4A")
    private let protocolModeUUID = CBUUID(string: "2A4E")
    private let controlPointUUID = CBUUID(string: "2A4C")
    
    // HID 服务特征
    private var reportCharacteristic: CBMutableCharacteristic!
    private var reportMapCharacteristic: CBMutableCharacteristic!
    private var hidInformationCharacteristic: CBMutableCharacteristic!
    private var protocolModeCharacteristic: CBMutableCharacteristic!
    
    // 键盘状态
    private var modifierKeys: UInt8 = 0
    private var keyCodes: [UInt8] = [0, 0, 0, 0, 0, 0]
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func startAdvertising() {
        guard peripheralManager.state == .poweredOn else {
            print("蓝牙未开启")
            return
        }
        
        setupHIDService()
        
        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [hidServiceUUID],
            CBAdvertisementDataLocalNameKey: "iMac Keyboard Pro"
        ]
        
        peripheralManager.startAdvertising(advertisementData)
        print("开始广播键盘服务")
    }
    
    func stopAdvertising() {
        peripheralManager.stopAdvertising()
        print("停止广播")
    }
    
    private func setupHIDService() {
        // HID 信息特征
        let hidInfoData = Data([0x01, 0x01, 0x00, 0x03]) // 版本 1.1，标志位 0x00，国家代码 0x03
        hidInformationCharacteristic = CBMutableCharacteristic(
            type: hidInformationUUID,
            properties: [.read],
            value: hidInfoData,
            permissions: [.readable]
        )
        
        // 报告映射特征 (HID 描述符)
        let reportMapData = createHIDReportMap()
        reportMapCharacteristic = CBMutableCharacteristic(
            type: reportMapUUID,
            properties: [.read],
            value: reportMapData,
            permissions: [.readable]
        )
        
        // 协议模式特征
        let protocolModeData = Data([0x01]) // 报告模式
        protocolModeCharacteristic = CBMutableCharacteristic(
            type: protocolModeUUID,
            properties: [.read, .writeWithoutResponse],
            value: protocolModeData,
            permissions: [.readable, .writeable]
        )
        
        // 控制点特征
        controlPointUUID
        let controlPointCharacteristic = CBMutableCharacteristic(
            type: controlPointUUID,
            properties: [.writeWithoutResponse],
            value: nil,
            permissions: [.writeable]
        )
        
        // 报告特征 (用于发送按键数据)
        reportCharacteristic = CBMutableCharacteristic(
            type: reportUUID,
            properties: [.read, .write, .notify],
            value: nil,
            permissions: [.readable, .writeable]
        )
        
        // 创建 HID 服务
        let hidService = CBMutableService(type: hidServiceUUID, primary: true)
        hidService.characteristics = [
            hidInformationCharacteristic,
            reportMapCharacteristic,
            protocolModeCharacteristic,
            controlPointCharacteristic,
            reportCharacteristic
        ]
        
        peripheralManager.removeAllServices()
        peripheralManager.add(hidService)
    }
    
    private func createHIDReportMap() -> Data {
        // 简化的 HID 报告描述符，包含键盘和多媒体键
        let reportMap: [UInt8] = [
            0x05, 0x01,        // Usage Page (Generic Desktop)
            0x09, 0x06,        // Usage (Keyboard)
            0xA1, 0x01,        // Collection (Application)
            // 修饰键 (Ctrl, Shift, Alt, GUI)
            0x05, 0x07,        // Usage Page (Key Codes)
            0x19, 0xE0,        // Usage Minimum (Left Control)
            0x29, 0xE7,        // Usage Maximum (Right GUI)
            0x15, 0x00,        // Logical Minimum (0)
            0x25, 0x01,        // Logical Maximum (1)
            0x75, 0x01,        // Report Size (1)
            0x95, 0x08,        // Report Count (8)
            0x81, 0x02,        // Input (Data,Var,Abs)
            // 保留字节
            0x95, 0x01,        // Report Count (1)
            0x75, 0x08,        // Report Size (8)
            0x81, 0x01,        // Input (Const,Array,Abs)
            // LED 输出报告
            0x95, 0x05,        // Report Count (5)
            0x75, 0x01,        // Report Size (1)
            0x05, 0x08,        // Usage Page (LEDs)
            0x19, 0x01,        // Usage Minimum (Num Lock)
            0x29, 0x05,        // Usage Maximum (Kana)
            0x91, 0x02,        // Output (Data,Var,Abs)
            // LED 填充
            0x95, 0x01,        // Report Count (1)
            0x75, 0x03,        // Report Size (3)
            0x91, 0x01,        // Output (Const,Array,Abs)
            // 按键数组 (6 键滚轮)
            0x95, 0x06,        // Report Count (6)
            0x75, 0x08,        // Report Size (8)
            0x15, 0x00,        // Logical Minimum (0)
            0x25, 0x65,        // Logical Maximum (101)
            0x05, 0x07,        // Usage Page (Key Codes)
            0x19, 0x00,        // Usage Minimum (0)
            0x29, 0x65,        // Usage Maximum (101)
            0x81, 0x00,        // Input (Data,Array,Abs)
            // 多媒体键集合
            0x05, 0x0C,        // Usage Page (Consumer)
            0x09, 0x01,        // Usage (Consumer Control)
            0xA1, 0x01,        // Collection (Application)
            0x85, 0x02,        // Report ID (2)
            0x05, 0x0C,        // Usage Page (Consumer)
            0x09, 0xE9,        // Usage (Volume Up)
            0x09, 0xEA,        // Usage (Volume Down)
            0x09, 0xE2,        // Usage (Mute)
            0x09, 0xCD,        // Usage (Play/Pause)
            0x09, 0xB5,        // Usage (Next)
            0x09, 0xB6,        // Usage (Previous)
            0x15, 0x00,        // Logical Minimum (0)
            0x25, 0x01,        // Logical Maximum (1)
            0x75, 0x01,        // Report Size (1)
            0x95, 0x06,        // Report Count (6)
            0x81, 0x02,        // Input (Data,Var,Abs)
            0xC0,              // End Collection
            0xC0               // End Collection
        ]
        
        return Data(reportMap)
    }
}

extension BluetoothKeyboardManager {
    // 修饰键位掩码
    struct ModifierKeys {
        static let leftControl: UInt8 = 1 << 0
        static let leftShift: UInt8 = 1 << 1
        static let leftAlt: UInt8 = 1 << 2
        static let leftGUI: UInt8 = 1 << 3
        static let rightControl: UInt8 = 1 << 4
        static let rightShift: UInt8 = 1 << 5
        static let rightAlt: UInt8 = 1 << 6
        static let rightGUI: UInt8 = 1 << 7
    }
    
    // HID 键码 (部分常用键)
    struct KeyCodes {
        static let a: UInt8 = 4
        static let b: UInt8 = 5
        static let c: UInt8 = 6
        static let d: UInt8 = 7
        static let e: UInt8 = 8
        static let f: UInt8 = 9
        static let g: UInt8 = 10
        static let h: UInt8 = 11
        static let i: UInt8 = 12
        static let j: UInt8 = 13
        static let k: UInt8 = 14
        static let l: UInt8 = 15
        static let m: UInt8 = 16
        static let n: UInt8 = 17
        static let o: UInt8 = 18
        static let p: UInt8 = 19
        static let q: UInt8 = 20
        static let r: UInt8 = 21
        static let s: UInt8 = 22
        static let t: UInt8 = 23
        static let u: UInt8 = 24
        static let v: UInt8 = 25
        static let w: UInt8 = 26
        static let x: UInt8 = 27
        static let y: UInt8 = 28
        static let z: UInt8 = 29
        static let returnKey: UInt8 = 40
        static let space: UInt8 = 44
        static let f1: UInt8 = 58
        static let f12: UInt8 = 69
        static let leftArrow: UInt8 = 80
        static let rightArrow: UInt8 = 79
        static let upArrow: UInt8 = 82
        static let downArrow: UInt8 = 81
    }
    
    // 发送单个按键
    func sendKeyPress(_ keyCode: UInt8, modifiers: UInt8 = 0) {
        modifierKeys = modifiers
        keyCodes = [keyCode, 0, 0, 0, 0, 0]
        sendKeyboardReport()
        
        // 发送释放按键
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.keyCodes = [0, 0, 0, 0, 0, 0]
            self.modifierKeys = 0
            self.sendKeyboardReport()
        }
    }
    
    // 发送组合键 (如 Command+C)
    func sendKeyCombination(keyCode: UInt8, modifier: UInt8) {
        sendKeyPress(keyCode, modifiers: modifier)
    }
    
    // 发送多媒体键
    func sendMediaKey(_ mediaKey: UInt16) {
        var reportData = Data([0x02]) // Report ID 2 for media keys
        var keyValue = mediaKey.littleEndian
        reportData.append(Data(bytes: &keyValue, count: MemoryLayout<UInt16>.size))
        sendReport(reportData)
    }
    
    // 发送键盘报告
    private func sendKeyboardReport() {
        var reportData = Data([0x00]) // Report ID 0 for keyboard
        reportData.append(Data([modifierKeys]))
        reportData.append(Data([0x00])) // Reserved
        reportData.append(Data(keyCodes))
        
        sendReport(reportData)
    }
    
    private func sendReport(_ reportData: Data) {
        guard let central = connectedCentral else { return }
        
        let result = peripheralManager.updateValue(
            reportData,
            for: reportCharacteristic,
            onSubscribedCentrals: [central]
        )
        
        if !result {
            print("发送报告失败，队列已满")
        }
    }
    
    // 常用组合键快捷方法
    func copy() {
        sendKeyCombination(keyCode: KeyCodes.c, modifier: ModifierKeys.leftGUI)
    }
    
    func paste() {
        sendKeyCombination(keyCode: KeyCodes.c, modifier: ModifierKeys.leftGUI)
    }
    
    func undo() {
        sendKeyCombination(keyCode: KeyCodes.z, modifier: ModifierKeys.leftGUI)
    }
    
    func volumeUp() {
        sendMediaKey(0x000000E9)
    }
    
    func volumeDown() {
        sendMediaKey(0x000000EA)
    }
    
    func mute() {
        sendMediaKey(0x000000E2)
    }
}

extension BluetoothKeyboardManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("蓝牙已开启，可以开始广播")
        case .poweredOff:
            print("蓝牙已关闭")
        case .resetting:
            print("蓝牙重置中")
        case .unauthorized:
            print("蓝牙未授权")
        case .unsupported:
            print("设备不支持蓝牙")
        case .unknown:
            print("蓝牙状态未知")
        @unknown default:
            print("未知的蓝牙状态")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("添加服务失败: \(error)")
        } else {
            print("HID 服务添加成功")
            startAdvertising()
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("开始广播失败: \(error)")
        } else {
            print("广播开始成功")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("中心设备已连接: \(central)")
        connectedCentral = central
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("中心设备断开连接: \(central)")
        connectedCentral = nil
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("收到读请求: \(request.characteristic.uuid)")
        peripheralManager.respond(to: request, withResult: .success)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            print("收到写请求: \(request.characteristic.uuid)")
            if request.characteristic.uuid == protocolModeUUID,
               let value = request.value {
                print("协议模式设置为: \(value)")
            }
        }
        peripheralManager.respond(to: requests[0], withResult: .success)
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // 当发送队列有空闲时，可以重新发送之前失败的报告
        print("可以更新订阅者")
    }
}
