//
//  AppEnvironment.swift
//  Capture
//
//  Created by Aye Chan on 2/21/23.
//

import Foundation

public class AppEnvironment {
    public let camera: CameraService
    public let photoLibrary: PhotoLibraryService

    public init(
        camera: CameraService,
        photoLibrary: PhotoLibraryService
    ) {
        self.camera = camera
        self.photoLibrary = photoLibrary
    }
}

public extension AppEnvironment {
    static var live: AppEnvironment {
        return AppEnvironment(
            camera: CameraService(),
            photoLibrary: PhotoLibraryService()
        )
    }
}
