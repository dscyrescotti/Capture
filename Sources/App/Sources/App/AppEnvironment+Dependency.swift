//
//  AppEnvironment+Dependency.swift
//  Capture
//
//  Created by Aye Chan on 2/22/23.
//

import Core
import Camera
import Gallery

public extension AppEnvironment {
    var cameraDependency: CameraDependency { CameraDependency(camera: camera, photoLibrary: photoLibrary) }
    var galleryDependency: GalleryDependency { GalleryDependency(photoLibrary: photoLibrary) }
}
