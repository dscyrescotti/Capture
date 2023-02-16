//
//  CameraDependency.swift
//  Capture
//
//  Created by Aye Chan on 2/16/23.
//

import Foundation

struct CameraDependency {
    let camera: CameraService

    init(camera: CameraService) {
        self.camera = camera
    }
}

extension CameraDependency {
    static var live: CameraDependency {
        CameraDependency(camera: CameraService())
    }
}
