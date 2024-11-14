//
//  KiwiScanner.swift
//  KiwiScanner
//
//  Created by agora on 2024-11-09.
//

import StandardCyborgFusion
import StandardCyborgUI
import Combine
import SwiftUI

public enum KiwiScannerState {
    case ready, scanning, viewing
}

public class KiwiScannerManager : ObservableObject {

    @Published public var state : KiwiScannerState {
        didSet {
            switch state {
                case .ready: break
                case .scanning: break
                case .viewing: break
            }
        }
    }
    
    var scanningViewController : ScanningViewController?
    var viewingViewController : ScenePreviewViewController?
    var onDismissScanner: (() -> Void)?
    var onDismissViewer: (() -> Void)?
    
    @Published var pointCloud : SCPointCloud?
    
    public var scannerView : KiwiScannerView?
    public var viewerView : KiwiViewerView?


    public init() {
        self.state = .ready
    }
    
    @MainActor public func startScanning() {
        scanningViewController = ScanningViewController()
        scanningViewController?.generatesTexturedMeshes = true
        scannerView = KiwiScannerView(manager: self)
        scanningViewController?.delegate = self
        self.state = .scanning
    }
    
    @MainActor public func showViewer() {
        guard let pointCloud = self.pointCloud else { print("No point cloud for viewer"); return }
        viewingViewController = ScenePreviewViewController(pointCloud: pointCloud, meshTexturing: scanningViewController?.meshTexturing, landmarks: nil)
        viewerView = KiwiViewerView(manager: self)
        scanningViewController?.delegate = self
    }
        
    public func sayHello() {
        print("Hello!")
    }
    
    @MainActor public func onScanningFinished(pointCloud: SCPointCloud) {
        self.pointCloud = pointCloud
        showViewer()
        state = .viewing
    }
    
    public func onScanningCancelled() {
        dismissScannerView()
        state = .ready
    }
    
    @MainActor func showViewer(pointCloud: SCPointCloud) {
        viewingViewController = ScenePreviewViewController(pointCloud: pointCloud, meshTexturing: scanningViewController!.meshTexturing, landmarks: nil)
    }
    
    func dismissScannerView() {
        onDismissScanner?()
        scanningViewController = nil
    }
    
    
}

extension KiwiScannerManager : @preconcurrency ScanningViewControllerDelegate {
        
    public func scanningViewControllerDidCancel(_ controller: ScanningViewController) {
        print("scanningViewControllerDidCancel")
        onScanningCancelled()
    }
    
    @MainActor public func scanningViewController(_ controller: ScanningViewController, didScan pointCloud: SCPointCloud) {
        print("scanningViewControllerDidScan \(pointCloud)")
        onScanningFinished(pointCloud: pointCloud)
    }
}

public struct KiwiScannerView : UIViewControllerRepresentable {
    
    @Environment(\.presentationMode) var presentationMode

    var manager : KiwiScannerManager
    
    public func makeUIViewController(context: Context) -> ScanningViewController {
        // Return MyViewController instance
        manager.onDismissScanner = { presentationMode.wrappedValue.dismiss() }
        return manager.scanningViewController!
    }
    
    public func updateUIViewController(_ uiViewController: ScanningViewController, context: Context) {
        // Updates the state of the specified view controller with new information from SwiftUI.
    }
    
}

public struct KiwiViewerView : UIViewControllerRepresentable {
    
    @Environment(\.presentationMode) var presentationMode
    
    var manager : KiwiScannerManager
    
    public func makeUIViewController(context: Context) -> ScenePreviewViewController {
        // Return MyViewController instance
        manager.onDismissViewer = { presentationMode.wrappedValue.dismiss() }
        return manager.viewingViewController!
    }
    
    public func updateUIViewController(_ uiViewController: ScenePreviewViewController, context: Context) {
        // Updates the state of the specified view controller with new information from SwiftUI.
    }
    
}
