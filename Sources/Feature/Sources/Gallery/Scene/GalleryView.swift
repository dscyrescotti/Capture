//
//  GalleryView.swift
//  Capture
//
//  Created by Aye Chan on 2/21/23.
//

import Photos
import SwiftUI
import Routing

public struct GalleryView: View {
    @Coordinator var coordinator
    @StateObject var viewModel: GalleryViewModel

    public init(dependency: GalleryDependency) {
        let viewModel = GalleryViewModel(dependency: dependency)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var columns: [GridItem] = [GridItem](repeating: GridItem(.flexible(), spacing: 5, alignment: .center), count: 3)

    public var body: some View {
        GeometryReader { proxy in
            NavigationStack {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 5) {
                        ForEach(0..<viewModel.results.count, id: \.self) { index in
                            let asset = viewModel.results[index]
                            PhotoThumbnail(assetId: asset.localIdentifier) { id, size in
                                await viewModel.loadImage(for: id, targetSize: size)
                            } onTap: { photo, assetId in
                                let resource = PHAssetResource.assetResources(for: asset)
                                let fileName = resource.first?.originalFilename ?? ""
                                $coordinator.fullScreen(.photo(photo: photo, assetId: assetId, fileName: fileName))
                            }
                            .frame(height: (proxy.size.width - 5 * 3) / 3)
                            .id(asset.localIdentifier)
                        }
                    }
                }
                .navigationTitle("Gallery")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            $coordinator.dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .tint(.white)
                    }
                }
            }
        }
        .task {
            await viewModel.loadAllPhotos()
        }
        .task {
            await viewModel.bindLibraryUpdateChannel()
        }
        .preferredColorScheme(.dark)
        .coordinated($coordinator)
    }
}
