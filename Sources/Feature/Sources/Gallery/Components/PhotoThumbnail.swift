//
//  PhotoThumbnail.swift
//  Capture
//
//  Created by Aye Chan on 2/21/23.
//

import SwiftUI

struct PhotoThumbnail: View {
    @State var image: UIImage?

    let assetId: String
    let loadImage: (String, CGSize) async -> UIImage?
    let onTap: (UIImage?, String) -> Void

    init(
        assetId: String,
        loadImage: @escaping (String, CGSize) async -> UIImage?,
        onTap: @escaping (UIImage?, String) -> Void
    ) {
        self.assetId = assetId
        self.loadImage = loadImage
        self.onTap = onTap
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } else {
                    Color.gray
                        .opacity(0.3)
                }
            }
            .task {
                let image = await loadImage(assetId, proxy.size)
                await MainActor.run {
                    self.image = image
                }
            }
            .onDisappear {
                self.image = nil
            }
            .onTapGesture {
                onTap(image, assetId)
            }
        }
    }
}

