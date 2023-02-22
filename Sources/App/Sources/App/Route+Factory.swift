//
//  Route+Factory.swift
//  Capture
//
//  Created by Aye Chan on 2/22/23.
//

import Core
import Photo
import Camera
import Gallery
import Routing
import SwiftUI

extension Route: Factory {
    @ViewBuilder
    public func contentView() -> some View {
        switch self {
        case let .photo(photo, assetId, fileName):
            PhotoView(dependency: environment.photoDependency(photo: photo, assetId: assetId, fileName: fileName))
        case .camera:
            CameraView(dependency: environment.cameraDependency)
        case .gallery:
            GalleryView(dependency: environment.galleryDependency)
        }
    }

    private var environment: AppEnvironment { .live }
}
