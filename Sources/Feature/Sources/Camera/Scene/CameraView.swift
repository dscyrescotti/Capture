//
//  CameraView.swift
//  Capture
//
//  Created by Aye Chan on 2/16/23.
//

import Core
import Routing
import SwiftUI
import Utility

public struct CameraView: View {
    @Coordinator var coordinator
    @Environment(\.scenePhase) var scenePhase
    @StateObject var viewModel: CameraViewModel

    public init(dependency: CameraDependency) {
        let viewModel = CameraViewModel(dependency: dependency)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
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
                                    .animation(.none, value: viewModel.pointOfInterest)
                                    .foregroundColor(.yellow)
                                    .transition(.opacity)
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
        .task {
            await viewModel.bindCaptureChannel()
        }
        .errorAlert($viewModel.cameraError) { error, completion in
            cameraAlertActions(for: error, completion: completion)
        }
        .onChange(of: scenePhase, perform: viewModel.onChangeScenePhase(to:))
        .preferredColorScheme(.dark)
        .coordinated($coordinator)
    }

    @ViewBuilder
    var cameraPreview: some View {
        if viewModel.cameraPermission == .authorized {
            GeometryReader { proxy in
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
                    .overlay(alignment: .bottomLeading) {
                        if !viewModel.photos.isEmpty {
                            photoPreviewStack
                        }
                    }
                    .overlay(alignment: .bottom) {
                        Text("x\(viewModel.zoomFactor * 100 / viewModel.camera.zoomFactorRange.max, specifier: "%.1f")")
                            .font(.headline.bold())
                            .padding(.vertical, 3)
                            .padding(.horizontal, 10)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                            .padding(.bottom, 5)
                    }
                    .gesture(magnificationGesture(size: proxy.size))
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
                Button {
                    $coordinator.fullScreen(.gallery)
                } label: {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title)
                        .frame(width: 60, height: 60)
                        .background(.ultraThinMaterial, in: Circle())
                        .clipShape(Circle())
                }
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

    @ViewBuilder
    var photoPreviewStack: some View {
        ZStack {
            ForEach(viewModel.photos.sorted(by: <)) { photo in
                if let image = photo.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipped()
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .clipped()
        .frame(width: 110, height: 110)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 5))
        .padding(15)
        .transition(.opacity)
    }

    private func magnificationGesture(size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let range = viewModel.camera.zoomFactorRange
                let maxZoom = range.max * 5 / 100
                guard viewModel.zoomFactor >= range.min && viewModel.zoomFactor <= maxZoom else {
                    return
                }
                let delta = value / viewModel.lastZoomFactor
                viewModel.lastZoomFactor = value
                viewModel.zoomFactor = min(maxZoom, max(range.min, viewModel.zoomFactor * delta))
                viewModel.changeZoomFactor()
            }
            .onEnded { _ in
                viewModel.lastZoomFactor = 1
                viewModel.changeZoomFactor()
            }
    }
}
