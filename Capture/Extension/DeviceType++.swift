//
//  DeviceType++.swift
//  Capture
//
//  Created by Aye Chan on 2/17/23.
//

import AVFoundation

extension AVCaptureDevice.DeviceType {
    var deviceName: String {
        switch self {
        case .builtInTrueDepthCamera:
            return "True Depth"
        case .builtInDualCamera:
            return "Dual"
        case .builtInDualWideCamera:
            return "Dual Wide"
        case .builtInTripleCamera:
            return "Triple"
        case .builtInWideAngleCamera:
            return "Wide Angle"
        case .builtInUltraWideCamera:
            return "Ultra Wide"
        case .builtInLiDARDepthCamera:
            return "LiDAR Depth"
        case .builtInTelephotoCamera:
            return "Telephoto"
        default:
            return "Unknown"
        }
    }
}
