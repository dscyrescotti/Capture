//
//  GalleryViewModel.swift
//  Capture
//
//  Created by Aye Chan on 2/21/23.
//

import Photos
import Foundation

class GalleryViewModel: ObservableObject {
    let dependency: GalleryDependency

    @Published var results = PHFetchResult<PHAsset>()

    init(dependency: GalleryDependency) {
        self.dependency = dependency
    }
}
