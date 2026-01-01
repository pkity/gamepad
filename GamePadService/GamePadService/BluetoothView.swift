//
//  BluetoothView.swift
//  GamePadService
//
//  Created by 苹果 on 2025/11/23.
//

import SwiftUI

class BluetoothViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardUI()
    }
    
    private func setupKeyboardUI() {
        // 启动蓝牙键盘
        // BluetoothKeyboardManager.shared.startAdvertising()
        
        // 创建一些测试按钮
        createButton(title: "开始广播", y: 100) {
            BluetoothKeyboardManager.shared.startAdvertising()
        }
        
        createButton(title: "输入 Hello", y: 160) {
            self.typeText("Hello")
        }
        
        createButton(title: "Cmd+C", y: 220) {
            BluetoothKeyboardManager.shared.copy()
        }
        
        createButton(title: "音量+", y: 280) {
            BluetoothKeyboardManager.shared.volumeUp()
        }
    }
    
    private func createButton(title: String, y: CGFloat, action: @escaping () -> Void) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.frame = CGRect(x: 50, y: y, width: 200, height: 44)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        view.addSubview(button)
    }
    
    private func typeText(_ text: String) {
        for char in text.lowercased() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(text.distance(from: text.startIndex, to: text.firstIndex(of: char)!)) * 0.1) {
                if let keyCode = self.keyCodeForCharacter(char) {
                    BluetoothKeyboardManager.shared.sendKeyPress(keyCode)
                }
            }
        }
    }
    
    private func keyCodeForCharacter(_ char: Character) -> UInt8? {
        let mapping: [Character: UInt8] = [
            "a": 4, "b": 5, "c": 6, "d": 7, "e": 8,
            "f": 9, "g": 10, "h": 11, "i": 12, "j": 13,
            "k": 14, "l": 15, "m": 16, "n": 17, "o": 18,
            "p": 19, "q": 20, "r": 21, "s": 22, "t": 23,
            "u": 24, "v": 25, "w": 26, "x": 27, "y": 28, "z": 29,
            " ": 44
        ]
        return mapping[char]
    }
}
