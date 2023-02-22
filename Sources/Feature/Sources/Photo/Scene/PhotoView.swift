//
//  PhotoView.swift
//  Capture
//
//  Created by Aye Chan on 2/22/23.
//

import Routing
import SwiftUI
import Utility

public struct PhotoView: View {
    @Coordinator var coordinator
    @StateObject var viewModel: PhotoViewModel

    public init(dependency: PhotoDependency) {
        let viewModel = PhotoViewModel(dependency: dependency)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    if let photo = viewModel.photo {
                        ScrollView([.vertical, .horizontal], showsIndicators: false) {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFit()
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .scaleEffect(viewModel.scale, anchor: .center)
                                .frame(width: viewModel.scale * proxy.size.width, height: proxy.size.height * viewModel.scale)
                        }
                    } else {
                        ProgressView()
                    }
                }
                .highPriorityGesture(magnificationGesture(size: proxy.size))
                .task {
                    await viewModel.loadImage(targetSize: proxy.size)
                }
            }
            .ignoresSafeArea(.all)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(viewModel.dependency.fileName)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        $coordinator.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .bold()
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .tint(.white)
                }
            }
        }
        .errorAlert($viewModel.photoLibraryError) { _, completion in
            Button("Cancel", role: .cancel) {
                completion()
            }
        }
    }

    private func magnificationGesture(size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let range: (min: CGFloat, max: CGFloat) = (min: 1, max: 4)
                guard viewModel.scale >= range.min && viewModel.scale <= range.max else {
                    return
                }
                let delta = value / viewModel.lastScale
                viewModel.lastScale = value
                viewModel.scale = min(range.max, max(range.min, viewModel.scale * delta))
            }
            .onEnded { _ in
                viewModel.lastScale = 1
            }
    }
}
