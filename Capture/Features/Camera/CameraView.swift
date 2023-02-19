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
            .overlay(alignment: .bottom) {
                cameraBottomActions
            }
            .overlay(alignment: .top) {
                cameraTopActions
            }
            .task {
                await viewModel.checkPhotoLibraryPermission()
                await viewModel.checkCameraPermission()
            }
            .errorAlert($viewModel.cameraError) { error, completion in
                cameraAlertActions(for: error, completion: completion)
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
                .blur(radius: viewModel.blursCameraPreview ? 5 : 0)
                .overlay {
                    if viewModel.hidesCameraPreview {
                        Color(uiColor: .systemBackground)
                            .transition(.opacity.animation(.default))
                    }
                }
        } else {
            Color.black
        }
    }

    @ViewBuilder
    var cameraBottomActions: some View {
        VStack(spacing: 20) {
            switch viewModel.cameraMode {
            case .front:
                cameraPicker(selection: $viewModel.frontDeviceIndex, devices: viewModel.frontDevices)
                    .onChange(of: viewModel.frontDeviceIndex) { index in
                        self.viewModel.switchCameraDevice(to: index, for: .front)
                    }
            case .rear:
                cameraPicker(selection: $viewModel.rearDeviceIndex, devices: viewModel.rearDevices)
                    .onChange(of: viewModel.rearDeviceIndex) { index in
                        self.viewModel.switchCameraDevice(to: index, for: .rear)
                    }
            case .none:
                Color.clear
                    .frame(height: 25)
            }
            HStack {
                Color.clear
                    .frame(width: 60, height: 60)
                Spacer()
                Button {
                    viewModel.capturePhoto()
                } label: {
                    Circle()
                }
                .padding(5)
                .background {
                    Circle()
                        .stroke(lineWidth: 3)
                }
                .frame(width: 80, height: 80)
                Spacer()
                Button {
                    viewModel.switchCameraMode()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.title)
                        .frame(width: 60, height: 60)
                        .background(.ultraThinMaterial, in: Circle())
                        .clipShape(Circle())
                }
            }
        }
        .foregroundColor(.white)
        .padding(.all, 15)
        .background(.black.opacity(0.7), ignoresSafeAreaEdges: .bottom)
        .errorAlert($viewModel.photoLibraryError) { error, completion in
            photoLibraryAlertActions(for: error, completion: completion)
        }
    }

    @ViewBuilder
    func cameraPicker(selection: Binding<Int>, devices: [String]) -> some View {
        Picker("", selection: selection) {
            ForEach(0..<devices.count, id: \.self) { index in
                Text(devices[index])
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    var cameraTopActions: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    viewModel.toggleLivePhoto()
                } label: {
                    Image(systemName: viewModel.enablesLivePhoto ? "livephoto" : "livephoto.slash")
                        .font(.title3)
                }
            }
        }
        .foregroundColor(.white)
        .padding(.all, 15)
        .background(.black.opacity(0.7), ignoresSafeAreaEdges: .top)
    }
}
