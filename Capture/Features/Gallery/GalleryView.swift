//
//  GalleryView.swift
//  Capture
//
//  Created by Aye Chan on 2/21/23.
//

import Photos
import SwiftUI

struct GalleryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: GalleryViewModel

    init(dependency: GalleryDependency) {
        let viewModel = GalleryViewModel(dependency: dependency)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var columns: [GridItem] = [GridItem](repeating: GridItem(.flexible(), spacing: 5, alignment: .center), count: 3)

    var body: some View {
        GeometryReader { proxy in
            NavigationStack {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 5) {
                        ForEach(0..<viewModel.results.count, id: \.self) { index in
                            PhotoThumbnail(assetId: viewModel.results[index].localIdentifier) { id, size in
                                await viewModel.loadImage(for: id, targetSize: size)
                            }
                            .frame(height: (proxy.size.width - 5 * 3) / 3)
                        }
                    }
                }
                .navigationTitle("Gallery")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            dismiss()
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
        .preferredColorScheme(.dark)
    }
}
