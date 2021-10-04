//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 27/07/21.
//

import Foundation

extension Dictionary {
  subscript(keyPath keyPath: String) -> Any? {
    get {
      guard let keyPath = Dictionary.keyPathKeys(forKeyPath: keyPath)
        else { return nil }
      return getValue(forKeyPath: keyPath)
    }
    set {
      guard let keyPath = Dictionary.keyPathKeys(forKeyPath: keyPath),
        let newValue = newValue else { return }
      self.setValue(newValue, forKeyPath: keyPath)
    }
  }

  static private func keyPathKeys(forKeyPath: String) -> [Key]? {
    let keys = forKeyPath.components(separatedBy: ".").compactMap({ $0 as? Key })
    return keys.isEmpty ? nil : keys
  }

  // recursively (attempt to) access queried subdictionaries
  // (keyPath will never be empty here; the explicit unwrapping is safe)
  private func getValue(forKeyPath keyPath: [Key]) -> Any? {
    guard let value = self[keyPath.first!] else { return nil }
    return keyPath.count == 1 ? value : (value as? [Key: Any])
      .flatMap { $0.getValue(forKeyPath: Array(keyPath.dropFirst())) }
  }

  // recursively (attempt to) access the queried subdictionaries to
  // finally replace the "inner value", given that the key path is valid
  private mutating func setValue(_ value: Any, forKeyPath keyPath: [Key]) {
    if keyPath.count == 1 {
      self[keyPath.first!] = value as? Value
    } else {
      if self[keyPath.first!] == nil {
        self[keyPath.first!] = ([Key: Value]() as? Value)
      }
      if var subDict = self[keyPath.first!] as? [Key: Value] {
        subDict.setValue(value, forKeyPath: Array(keyPath.dropFirst()))
        self[keyPath.first!] = subDict as? Value
      }
    }
  }
}
