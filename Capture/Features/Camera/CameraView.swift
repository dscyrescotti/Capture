//
//  CameraView.swift
//  Capture
//
//  Created by Aye Chan on 2/16/23.
//

import SwiftUI

struct CameraView: View {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var viewModel: CameraViewModel

    init(dependency: CameraDependency) {
        let viewModel = CameraViewModel(dependency: dependency)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        cameraPreview
            .ignoresSafeArea()
            .task {
                await viewModel.checkCameraPermission()
            }
            .errorAlert($viewModel.error) { error, completion in
                alertActions(for: error, completion: completion)
            }
            .onChange(of: scenePhase, perform: viewModel.onChangeScenePhase(to:))
            .preferredColorScheme(.dark)
    }

    @ViewBuilder
    var cameraPreview: some View {
        if viewModel.cameraPermission == .authorized {
            CameraPreviewLayer(camera: viewModel.camera)
                .onAppear {
                    viewModel.hideCameraPreview(false)
                    viewModel.camera.startSession()
                }
                .onDisappear {
                    viewModel.hideCameraPreview(true)
                    viewModel.camera.stopSession()
                }
                .overlay {
                    if viewModel.hidesCameraPreview {
                        Color(uiColor: .systemBackground)
                            .transition(.opacity.animation(.default))
                    }
                }
        }
    }
}
