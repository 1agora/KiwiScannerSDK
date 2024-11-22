//
//  KiwiScannerLog.swift
//  KiwiScannerSDK
//
//  Created by agora on 2024-11-22.
//


public class KiwiScannerLog {
    
    public enum LogLevel : Int {
        case off, activity, verbose, debug
    }
    
    public static var level : LogLevel = .debug
    
    init() {}
    
    static func print(_ object: Any, _ level: LogLevel = .verbose) {
        guard level.rawValue <= self.level.rawValue else { return }
        
        if object is String {
            Swift.print("[KiwiScanner][\(level)]: 🌿 \(object) ")
        } else {
            Swift.print("[KiwiScanner][\(level)]: 🌿 \(String(describing: object)) ")
        }
    }
    
    static func error(_ object: Any, _ level: LogLevel = .verbose) {
        guard level.rawValue <= self.level.rawValue else { return }
        
        if object is String {
            Swift.print("[KiwiScanner][\(level)]: 🌶 \(object) ")
        } else {
            Swift.print("[KiwiScanner][\(level)]: 🌶 \(String(describing: object)) ")
        }
    }
    
    static func warning(_ object: Any, _ level: LogLevel = .verbose) {
        guard level.rawValue <= self.level.rawValue else { return }
        
        if object is String {
            Swift.print("[KiwiScanner][\(level)]: ⚠️ \(object) ")
        } else {
            Swift.print("[KiwiScanner][\(level)]: ⚠️ \(String(describing: object)) ")
        }
    }
}
