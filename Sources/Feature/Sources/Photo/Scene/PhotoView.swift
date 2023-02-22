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
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .scaleEffect(viewModel.scale)
                            .offset(viewModel.offset)
                            .gesture(dragGesture(size: proxy.size))
                            .gesture(magnificationGesture(size: proxy.size))
                    } else {
                        ProgressView()
                    }
                }
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
                let delta = value / viewModel.lastScale
                viewModel.lastScale = value
                viewModel.scale = viewModel.scale * delta
            }
            .onEnded { _ in
                viewModel.lastScale = 1
                let range: (min: CGFloat, max: CGFloat) = (min: 1, max: 4)
                if viewModel.scale < range.min || viewModel.scale > range.max {
                    withAnimation {
                        viewModel.scale = min(range.max, max(range.min, viewModel.scale))
                    }
                }
                resetImageFrame(size: size)
            }
    }

    private func dragGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let deltaX = value.translation.width - viewModel.lastOffset.width
                let deltaY = value.translation.height - viewModel.lastOffset.height
                viewModel.lastOffset = value.translation

                let newOffsetWidth = viewModel.offset.width + deltaX
                let newOffsetHeight = viewModel.offset.height + deltaY
                viewModel.offset.width = newOffsetWidth
                viewModel.offset.height = newOffsetHeight
            }
            .onEnded { value in
                viewModel.lastOffset = .zero
                resetImageFrame(size: size)
            }
    }

    func widthLimit(size: CGSize) -> CGFloat {
        let halfWidth = size.width / 2
        let scaledHalfWidth = halfWidth * viewModel.scale
        return halfWidth - scaledHalfWidth
    }

    func heightLimit(size: CGSize) -> CGFloat {
        let halfHeight = size.height / 2
        let scaledHalfHeight = halfHeight * viewModel.scale
        return halfHeight - scaledHalfHeight
    }

    func resetImageFrame(size: CGSize) {
        let widthLimit = widthLimit(size: size)
        if viewModel.offset.width < widthLimit {
            withAnimation {
                viewModel.offset.width = widthLimit
            }
        }
        if viewModel.offset.width > -widthLimit {
            withAnimation {
                viewModel.offset.width = -widthLimit
            }
        }

        let heightLimit = heightLimit(size: size)
        if viewModel.offset.height < heightLimit {
            withAnimation {
                viewModel.offset.height = heightLimit
            }
        }
        if viewModel.offset.height > -heightLimit {
            withAnimation {
                viewModel.offset.height = -heightLimit
            }
        }
    }
}
