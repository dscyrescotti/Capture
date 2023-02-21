//
//  AppEnvironment.swift
//  Capture
//
//  Created by Aye Chan on 2/21/23.
//

import Foundation

class AppEnvironment {
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

extension AppEnvironment {
    var cameraDependency: CameraDependency { CameraDependency(camera: camera, photoLibrary: photoLibrary) }
    var galleryDependency: GalleryDependency { GalleryDependency(photoLibrary: photoLibrary) }
}

extension AppEnvironment {
    static var live: AppEnvironment {
        let photoLibrary = PhotoLibraryService()
        return AppEnvironment(
            camera: CameraService(photoLibrary: photoLibrary),
            photoLibrary: photoLibrary
        )
    }
}
