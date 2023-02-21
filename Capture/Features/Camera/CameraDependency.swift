//
//  CameraDependency.swift
//  Capture
//
//  Created by Aye Chan on 2/16/23.
//

import Foundation

struct CameraDependency {
    let camera: CameraService
    let photoLibrary: PhotoLibraryService

    init(
        camera: CameraService,
        photoLibrary: PhotoLibraryService
    ) {
        self.camera = camera
        self.photoLibrary = photoLibrary
    }
}
