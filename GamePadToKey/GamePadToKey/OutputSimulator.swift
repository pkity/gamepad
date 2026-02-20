//
//  OutputSimulator.swift
//  GamePadToKey
//

import Foundation
import CoreGraphics
import AppKit

public class OutputSimulator {
    private let eventSource: CGEventSource?
    
    public init() {
        eventSource = CGEventSource(stateID: .combinedSessionState)
    }
    
    public func cleanup() {
        // 清理资源
    }
    
    public func simulateKeyPress(key: String, modifiers: [String] = []) {
        guard let keyCode = KeyCodeMapper.getCode(for: key) else {
            print("未知按键: \(key)")
            return
        }
        
        let flags = modifiers.reduce(into: CGEventFlags()) { flags, mod in
            if let cgFlag = ModifierMapper.getCGFlag(for: mod) {
                flags.insert(cgFlag)
            }
        }
        
        // 按下事件
        let keyDownEvent = CGEvent(keyboardEventSource: eventSource,
                                   virtualKey: keyCode,
                                   keyDown: true)
        keyDownEvent?.flags = flags
        keyDownEvent?.post(tap: .cghidEventTap)
        
        // 释放事件（延迟50ms）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let keyUpEvent = CGEvent(keyboardEventSource: self.eventSource,
                                     virtualKey: keyCode,
                                     keyDown: false)
            keyUpEvent?.flags = flags
            keyUpEvent?.post(tap: .cghidEventTap)
        }
    }
    
    public func simulateKeyCombo(keys: [String]) {
        guard keys.count >= 2 else {
            if let first = keys.first {
                simulateKeyPress(key: first)
            }
            return
        }
        
        // 按下所有修饰键
        let modifiers = Array(keys.dropLast())
        let mainKey = keys.last!
        
        for mod in modifiers {
            pressModifier(mod)
        }
        
        // 按下主键
        simulateKeyPress(key: mainKey)
        
        // 释放所有修饰键
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for mod in modifiers.reversed() {
                self.releaseModifier(mod)
            }
        }
    }
    
    public func simulateMouseMove(deltaX: CGFloat, deltaY: CGFloat, sensitivity: Double = 1.0) {
        let currentPos = NSEvent.mouseLocation
        let newX = currentPos.x + deltaX * sensitivity
        let newY = currentPos.y - deltaY * sensitivity // 坐标系转换
        
        // 边界检查
        let screenFrame = NSScreen.main?.frame ?? .zero
        let clampedX = min(max(newX, 0), screenFrame.width)
        let clampedY = min(max(newY, 0), screenFrame.height)
        
        let moveEvent = CGEvent(mouseEventSource: eventSource,
                               mouseType: .mouseMoved,
                               mouseCursorPosition: CGPoint(x: clampedX, y: clampedY),
                               mouseButton: .left)
        moveEvent?.post(tap: .cghidEventTap)
    }
    
    public func simulateMouseClick(button: MouseButton, clickCount: Int = 1) {
        let location = NSEvent.mouseLocation
        
        for i in 0..<clickCount {
            // 按下
            let downType: CGEventType
            let upType: CGEventType
            let cgButton: CGMouseButton
            
            switch button {
            case .left:
                downType = .leftMouseDown
                upType = .leftMouseUp
                cgButton = .left
            case .right:
                downType = .rightMouseDown
                upType = .rightMouseUp
                cgButton = .right
            case .middle:
                downType = .otherMouseDown
                upType = .otherMouseUp
                cgButton = .center
            }
            
            let downEvent = CGEvent(mouseEventSource: eventSource,
                                   mouseType: downType,
                                   mouseCursorPosition: location,
                                   mouseButton: cgButton)
            downEvent?.post(tap: .cghidEventTap)
            
            // 释放
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let upEvent = CGEvent(mouseEventSource: self.eventSource,
                                     mouseType: upType,
                                     mouseCursorPosition: location,
                                     mouseButton: cgButton)
                upEvent?.post(tap: .cghidEventTap)
            }
            
            // 双击间隔
            if i < clickCount - 1 {
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
    
    public func simulateMouseScroll(deltaY: CGFloat, deltaX: CGFloat = 0) {
        let scrollEvent = CGEvent(scrollWheelEvent2Source: eventSource,
                                 units: .line,
                                 wheelCount: 2,
                                 wheel1: Int32(deltaY),
                                 wheel2: Int32(deltaX),
                                 wheel3: 0)
        scrollEvent?.post(tap: .cghidEventTap)
    }
    
    private func pressModifier(_ modifier: String) {
        guard let keyCode = KeyCodeMapper.getCode(for: modifier) else { return }
        let event = CGEvent(keyboardEventSource: eventSource,
                           virtualKey: keyCode,
                           keyDown: true)
        event?.post(tap: .cghidEventTap)
    }
    
    private func releaseModifier(_ modifier: String) {
        guard let keyCode = KeyCodeMapper.getCode(for: modifier) else { return }
        let event = CGEvent(keyboardEventSource: eventSource,
                           virtualKey: keyCode,
                           keyDown: false)
        event?.post(tap: .cghidEventTap)
    }
}

// 辅助类
public class KeyCodeMapper {
    public static func getCode(for key: String) -> CGKeyCode? {
        let mapping: [String: CGKeyCode] = [
            "a": 0x00, "s": 0x01, "d": 0x02, "f": 0x03,
            "h": 0x04, "g": 0x05, "z": 0x06, "x": 0x07,
            "c": 0x08, "v": 0x09, "b": 0x0B, "q": 0x0C,
            "w": 0x0D, "e": 0x0E, "r": 0x0F, "y": 0x10,
            "t": 0x11, "1": 0x12, "2": 0x13, "3": 0x14,
            "4": 0x15, "6": 0x16, "5": 0x17, "=": 0x18,
            "9": 0x19, "7": 0x1A, "-": 0x1B, "8": 0x1C,
            "0": 0x1D, "]": 0x1E, "o": 0x1F, "u": 0x20,
            "[": 0x21, "i": 0x22, "p": 0x23, "l": 0x25,
            "j": 0x26, "'": 0x27, "k": 0x28, ";": 0x29,
            "\\": 0x2A, ",": 0x2B, "/": 0x2C, "n": 0x2D,
            "m": 0x2E, ".": 0x2F, "`": 0x32, "space": 0x31,
            "return": 0x24, "tab": 0x30, "delete": 0x33,
            "escape": 0x35, "command": 0x37, "shift": 0x38,
            "capslock": 0x39, "option": 0x3A, "control": 0x3B,
            "fn": 0x3F, "f1": 0x7A, "f2": 0x78, "f3": 0x63,
            "f4": 0x76, "f5": 0x60, "f6": 0x61, "f7": 0x62,
            "f8": 0x64, "f9": 0x65, "f10": 0x6D, "f11": 0x67,
            "f12": 0x6F, "home": 0x73, "pageup": 0x74,
            "pagedown": 0x79, "end": 0x77, "left": 0x7B,
            "right": 0x7C, "down": 0x7D, "up": 0x7E
        ]
        
        return mapping[key.lowercased()]
    }
}
public class ModifierMapper {
    public static func getCGFlag(for modifier: String) -> CGEventFlags? {
        switch modifier.lowercased() {
        case "shift":
            return .maskShift
        case "control":
            return .maskControl
        case "option", "alt":
            return .maskAlternate
        case "command":
            return .maskCommand
        case "fn":
            return .maskSecondaryFn
        default:
            return nil
        }
    }
}

