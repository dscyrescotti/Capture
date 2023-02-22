//
//  CameraContainer.swift
//  Capture
//
//  Created by Aye Chan on 2/16/23.
//

import Core
import SwiftUI
import AVFoundation

struct CameraPreviewLayer: UIViewRepresentable {
    let camera: CameraService

    func makeUIView(context: Context) -> LayerView {
        let view = LayerView()
        camera.cameraPreviewLayer.videoGravity = .resizeAspectFill
        camera.cameraPreviewLayer.frame = view.frame
        view.layer.addSublayer(camera.cameraPreviewLayer)
        return view
    }

    func updateUIView(_ uiView: LayerView, context: Context) { }
}

extension CameraPreviewLayer {
    class LayerView: UIView {
        override func layoutSubviews() {
            super.layoutSubviews()
            /// disable default animation of layer.
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.sublayers?.forEach({ layer in
                layer.frame = frame
            })
            CATransaction.commit()
        }
    }
}
