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
        VStack(spacing: 0) {
            cameraTopActions
            GeometryReader { proxy in
                ZStack {
                    cameraPreview
                        .onTapGesture(coordinateSpace: .local) { point in
                            viewModel.changePointOfInterest(to: point, in: proxy.frame(in: .local))
                        }
                        .overlay {
                            if viewModel.pointOfInterest != .zero {
                                Rectangle()
                                    .stroke(lineWidth: 2)
                                    .frame(width: 120, height: 120)
                                    .position(viewModel.pointOfInterest)
                                    .foregroundColor(.yellow)
                            }
                        }
                    FocusFrame()
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            cameraBottomActions
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
                if viewModel.isAvailableFlashLight {
                    Button {
                        viewModel.switchFlashMode()
                    } label: {
                        switch viewModel.flashMode {
                        case .auto:
                            Image(systemName: "bolt.circle")
                        case .off:
                            Image(systemName: "bolt.slash.circle")
                        case .on:
                            Image(systemName: "bolt.circle")
                                .foregroundColor(.yellow)
                        default:
                            EmptyView()
                        }
                    }
                }
                if let focusMode = viewModel.focusMode {
                    Button {
                        viewModel.switchFocusMode()
                    } label: {
                        switch focusMode {
                        case .locked:
                            Image(systemName: "photo.circle.fill")
                        case .autoFocus:
                            Image(systemName: "photo.circle")
                        case .continuousAutoFocus:
                            Image(systemName: "photo.circle")
                                .foregroundColor(.yellow)
                        default:
                            EmptyView()
                        }
                    }
                }
                if let exposureMode = viewModel.exposureMode {
                    Button {
                        viewModel.switchExposureMode()
                    } label: {
                        switch exposureMode {
                        case .locked:
                            Image(systemName: "smallcircle.filled.circle.fill")
                        case .autoExpose:
                            Image(systemName: "smallcircle.filled.circle")
                        case .continuousAutoExposure:
                            Image(systemName: "smallcircle.filled.circle")
                                .foregroundColor(.yellow)
                        default:
                            EmptyView()
                        }
                    }
                }
                Spacer()
                if viewModel.isAvailableLivePhoto {
                    Button {
                        viewModel.toggleLivePhoto()
                    } label: {
                        Image(systemName: viewModel.enablesLivePhoto ? "livephoto" : "livephoto.slash")
                    }
                }
            }
        }
        .foregroundColor(.white)
        .padding(.all, 15)
        .background(.black.opacity(0.7), ignoresSafeAreaEdges: .top)
        .font(.title2)
    }
}
