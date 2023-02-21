//
//  GalleryView.swift
//  Capture
//
//  Created by Aye Chan on 2/21/23.
//

import SwiftUI

struct GalleryView: View {

    @StateObject var viewModel: GalleryViewModel

    init(dependency: GalleryDependency) {
        let viewModel = GalleryViewModel(dependency: dependency)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Text("Gallery View")
    }
}
