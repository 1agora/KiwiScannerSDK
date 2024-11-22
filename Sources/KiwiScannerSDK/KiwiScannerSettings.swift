//
//  KiwiScannerSettings.swift
//  KiwiScannerSDK
//
//  Created by agora on 2024-11-22.
//

public class KiwiScannerSettings {
    
    public var scanning = ScanningSettings()
    public var meshing = MeshingSettings()
    
    public struct ScanningSettings {
        public var stopScanningAfterFrames : Int = 50
    }
    
    public struct MeshingSettings {
        /**
         The resolution of the reconstructed mesh vertices.
         Higher values will result in more vertices per meshes,
         and also take longer to reconstruct.
         Range is 1-10, default is 5.
         */
        public var resolution : Int32 = 10
        
        /**
         The smoothness of the reconstructed mesh vertex positions.
         Range is 1-10, default is 2.
         */
        public var smoothness : Int32 = 2
        
        /**
         The amount of surface trimming for low-density mesh regions.
         Range is 0-10, default is 5. Higher numbers trim more away.
         0 = don't trim.
         */
        public var surfaceTrimmingAmount : Int32 = 5
    }
    
    
}
