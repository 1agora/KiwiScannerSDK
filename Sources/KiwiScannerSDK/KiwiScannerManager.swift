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
    
    public var settings : KiwiScannerSettings = KiwiScannerSettings()
        
    var scanningViewController : ScanningViewController?
    var viewingViewController : ScenePreviewViewController?
    var onDismissScanner: (() -> Void)?
    var onDismissViewer: (() -> Void)?
        
    public var scannerView : KiwiScannerView?
    public var viewerView : KiwiViewerView?

    public var reconstructionManagerStatistics = PassthroughSubject<SCReconstructionManagerStatistics,Never>()
    public var pointCloudPublisher : CurrentValueSubject<SCPointCloud?,Never> = CurrentValueSubject(nil)
    public var scanPublisher : CurrentValueSubject<SCScene?,Never> = CurrentValueSubject(nil)
    public var meshPublisher : CurrentValueSubject<SCMesh?,Never> = CurrentValueSubject(nil)

    public var didCancel = PassthroughSubject<Void, Never>()
    
    private var cancellables = Set<AnyCancellable>()

    
    public init() {
        self.state = .ready
        
        meshPublisher.sink { mesh in
            if let mesh = mesh {
                KiwiScannerLog.print("Mesh updated")
                self.objectWillChange.send()
            }
        }.store(in: &cancellables)
        
        pointCloudPublisher.sink { pointCloud in
            if let pointCloud = pointCloud {
                KiwiScannerLog.print("PointCloud updated")
                self.objectWillChange.send()
            }
        }.store(in: &cancellables)
    }
    
    @MainActor public func prepareScanner() {
        if let scanningViewController = scanningViewController {
            self.state = .scanning
        } else {
            scanningViewController = ScanningViewController()
            scanningViewController?.dismissButton.isHidden = true
            scanningViewController?.showsMirrorModeButton = false
            scanningViewController?.generatesTexturedMeshes = true
            scannerView = KiwiScannerView(manager: self)
            scanningViewController?.delegate = self
            self.state = .scanning
        }
    }
    
    @MainActor public func startScanning() {
        scanningViewController?.startScanning()
    }
    
    @MainActor public func finishScanning() {
        scanningViewController?.stopScanning(reason: .finished)
    }
    
    @MainActor public func cancelScanning() {
        scanningViewController?.stopScanning(reason: .canceled)
        self.state = .ready
        self.didCancel.send()
        //dismissScannerView()
        
    }
    
    @MainActor public func onScanningFinished(pointCloud: SCPointCloud) {
        self.pointCloudPublisher.value = pointCloud
        showViewer()
        state = .viewing
    }
    
    @MainActor public func showViewer() {
        guard let pointCloud = self.pointCloudPublisher.value else { KiwiScannerLog.error("No point cloud for viewer"); return }
        viewingViewController = ScenePreviewViewController(pointCloud: pointCloud, meshTexturing: scanningViewController?.meshTexturing, landmarks: nil)
        
        viewingViewController?.sceneView.backgroundColor = .black
        viewingViewController?.sceneView.autoenablesDefaultLighting = true
        
        let meshingParameters = SCMeshingParameters()
        meshingParameters.resolution = settings.meshing.resolution
        meshingParameters.smoothness = settings.meshing.smoothness
        meshingParameters.surfaceTrimmingAmount = settings.meshing.surfaceTrimmingAmount

        
        viewingViewController?.meshingParameters = meshingParameters
        
        viewingViewController?.onTexturedMeshGenerated = { mesh in
            KiwiScannerLog.print("Meshing complete. Faces: \(mesh.faceCount), Vertices: \(mesh.vertexCount)")
            self.meshPublisher.send(mesh)
        }

        viewerView = KiwiViewerView(manager: self)
        scanningViewController?.delegate = self
    }
    
    @MainActor public func finalizeViewer() {
        if let scScene = viewingViewController?.finish() {
            self.scanPublisher.send(scScene)
            viewingViewController = nil
            self.state = .ready
        } else {
            KiwiScannerLog.error("Viewr did not return scan....wth")
        }
    }
    
    @MainActor public func rescan() {
        self.pointCloudPublisher.send(nil)
        self.meshPublisher.send(nil)
        prepareScanner()
    }
    
    @MainActor public func onScanningCancelled() {
        state = .ready
        didCancel.send()
    }
    
    @MainActor func showViewer(pointCloud: SCPointCloud) {
        viewingViewController = ScenePreviewViewController(pointCloud: pointCloud, meshTexturing: scanningViewController!.meshTexturing, landmarks: nil)
    }
    
    
}

extension KiwiScannerManager : @preconcurrency ScanningViewControllerDelegate {
        
    @MainActor public func scanningViewControllerDidCancel(_ controller: ScanningViewController) {
        KiwiScannerLog.print("scanningViewControllerDidCancel", .debug)
        onScanningCancelled()
    }
    
    @MainActor public func scanningViewController(_ controller: ScanningViewController, didScan pointCloud: SCPointCloud) {
        KiwiScannerLog.print("scanningViewController generated \(pointCloud.pointCount)", .debug)
        onScanningFinished(pointCloud: pointCloud)
    }
    
    @MainActor public func scanningViewController(_ controller: ScanningViewController, didProcessFrame: SCReconstructionManagerStatistics) {
        if didProcessFrame.succeededCount >= settings.scanning.stopScanningAfterFrames {
            DispatchQueue.main.async {
                self.finishScanning()
            }
        }
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

extension FileManager {
    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
