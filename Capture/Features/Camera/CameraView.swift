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
            .task {
                await viewModel.checkCameraPermission()
            }
            .errorAlert($viewModel.error) { error, completion in
                alertActions(for: error, completion: completion)
            }
            .onChange(of: scenePhase, perform: viewModel.onChangeScenePhase(to:))
            .preferredColorScheme(.dark)
            .disabled(viewModel.disablesActions)
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
        VStack(spacing: 15) {
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
                Spacer()
                Color.clear
                    .frame(width: 40, height: 40)
                Spacer()
                Spacer()
                Button {

                } label: {
                    Circle()
                }
                .padding(10)
                .background {
                    Circle()
                        .stroke(lineWidth: 5)
                }
                .frame(width: 85, height: 85)
                Spacer()
                Spacer()
                Button {
                    viewModel.switchCameraMode()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.largeTitle)
                }
                .frame(width: 40, height: 40)
                Spacer()
            }
        }
        .foregroundColor(.white)
        .padding(.all, 15)
        .background(.black.opacity(0.6), ignoresSafeAreaEdges: .bottom)
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
}
