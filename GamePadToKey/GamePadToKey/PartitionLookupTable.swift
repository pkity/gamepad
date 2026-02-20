//
//  PartitionLookupTable.swift
//  GamePadToKey
//

import Foundation

class PartitionLookupTable {
    private var lookupCache: [String: PartitionNode] = [:]
    private var trieRoot: TrieNode = TrieNode()
    
    class TrieNode {
        var children: [String: TrieNode] = [:]
        var partition: PartitionNode?
    }
    
    func buildIndex(from root: PartitionNode) {
        // 清空现有索引
        lookupCache.removeAll()
        trieRoot = TrieNode()
        
        // 遍历所有分区，构建查找索引
        func traverse(_ node: PartitionNode, path: [String]) {
            let key = path.sorted().joined(separator: "+")
            lookupCache[key] = node
            
            // 构建 Trie
            var current = trieRoot
            for button in path.sorted() {
                if current.children[button] == nil {
                    current.children[button] = TrieNode()
                }
                current = current.children[button]!
            }
            current.partition = node
            
            // 遍历子节点
            for child in node.children {
                traverse(child, path: path + Array(child.activationCombo))
            }
        }
        
        traverse(root, path: [])
    }
    
    func findPartition(for pressedButtons: Set<String>) -> PartitionNode? {
        // 首先尝试精确匹配
        let key = pressedButtons.sorted().joined(separator: "+")
        if let partition = lookupCache[key] {
            return partition
        }
        
        // 使用 Trie 树查找最匹配的分区
        var current = trieRoot
        let sortedButtons = pressedButtons.sorted()
        
        for button in sortedButtons {
            if let next = current.children[button] {
                current = next
            } else {
                break
            }
        }
        
        return current.partition
    }
    
    func clear() {
        lookupCache.removeAll()
        trieRoot = TrieNode()
    }
}
