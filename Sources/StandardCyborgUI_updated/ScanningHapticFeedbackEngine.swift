//
//  ScanningHapticFeedbackEngine.swift
//  Capture
//
//  Copyright © 2018 Standard Cyborg. All rights reserved.
//

import AudioToolbox
import Foundation
import UIKit

/** Manages haptic feedback in response to changes in the scanning state */

public class ScanningHapticFeedbackEngine {
    
    @MainActor public static let shared = ScanningHapticFeedbackEngine()
    
    
    public init() {
        [
            _hapticImpactMedium,
            _hapticSelection,
            _hapticNotification
        ].forEach { thing in
            Task { @MainActor in
                thing.prepare()
            }
        }
    }
    
    
    public func countdownCountedDown() {
        Task { @MainActor in
            _hapticImpactMedium.impactOccurred()
        }
    }
    
    public func scanningBegan() {
        _startScanningTimer()
    }
    
    public func scanningFinished() {
        _stopScanningTimer()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(100)) {
            self._hapticNotification.notificationOccurred(UINotificationFeedbackGenerator.FeedbackType.success)
        }
    }
    
    @MainActor public func scanningCanceled() {
        _stopScanningTimer()
        
        _hapticNotification.notificationOccurred(UINotificationFeedbackGenerator.FeedbackType.error)
    }
    
    // MARK: - Private
    
    @MainActor private let _hapticImpactMedium = UIImpactFeedbackGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle.medium)
    @MainActor private let _hapticSelection = UISelectionFeedbackGenerator()
    @MainActor private let _hapticNotification = UINotificationFeedbackGenerator()
    
    private let _scanningTimerInterval = 1.0 / 8.0
    private var _scanningTimer: Timer?
    
    @MainActor private func _startScanningTimer() {
        _scanningTimer = Timer.scheduledTimer(withTimeInterval: _scanningTimerInterval, repeats: true, block: { [weak self] timer in
            
            self?._hapticSelection.selectionChanged()
           
        })
    }
    
    private func _stopScanningTimer() {
        _scanningTimer?.invalidate()
        _scanningTimer = nil
    }

}
