//
//  Array+Extensions.swift
//
//  Created by Solomon English on 11/10/15.
//  Copyright © 2015 FunPlus. All rights reserved.
//

import Foundation
import Dispatch

public func main_async(_ task: @escaping () -> Void) {
    if Thread.current.isMainThread {
        task()
    } else {
        DispatchQueue.main.async(execute: task)
    }
}

public func main_sync(_ task: @escaping () -> Void) {
    if Thread.current.isMainThread {
        task()
    } else {
        DispatchQueue.main.sync(execute: task)
    }
}

extension Array {
    func indexOf(_ includedElement: (Element) -> Bool) -> Int? {
        for (idx, element) in self.enumerated() {
            if includedElement(element) {
                return idx
            }
        }
        return nil
    }
	
	func itemAtIndex(_ index: Int) -> Element? {
		if self.count > index {
			return self[index]
		}
		
		return nil
	}
    
}

extension Array where Element: Equatable {
    
    mutating func remove(of element: Element) -> Element? {
        if let index = indexOf({ $0 == element }) {
            return remove(at: index)
        } else {
            return nil
        }
    }
    
}

extension Data {
    
    public var hex: String {
        return bytes.reduce("") { accum, current in
            return accum + String(format: "%02X", current)
        }
    }
    
    public var bytes: [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count / MemoryLayout<UInt8>.size)
        copyBytes(to: &bytes, count: count)
        
        return bytes
    }
}

extension String {
    
    public func toFileURL() -> URL? {
        return URL(fileURLWithPath: self)
    }
    
    public func toURL() -> URL? {
        return URL(string: self)
    }
    
}
