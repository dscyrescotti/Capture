//
//  CameraService.swift
//  Capture
//
//  Created by Aye Chan on 2/16/23.
//

import Foundation
import AVFoundation

class CameraService: NSObject {
    // MARK: - Session
    let captureSession: AVCaptureSession
    var sessionQueue: DispatchQueue = DispatchQueue(label: "capture-session")
    var isRunning: Bool { captureSession.isRunning }

    // MARK: - Devices
    private lazy var captureDevices: [AVCaptureDevice] = {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInTrueDepthCamera,
                .builtInDualCamera,
                .builtInDualWideCamera,
                .builtInTripleCamera,
                .builtInWideAngleCamera,
                .builtInUltraWideCamera,
                .builtInLiDARDepthCamera,
                .builtInTelephotoCamera
            ],
            mediaType: .video,
            position: .unspecified
        ).devices
    }()
    lazy var frontCaptureDevices: [AVCaptureDevice] = {
        captureDevices.filter { $0.position == .front }
    }()
    lazy var rearCaptureDevices: [AVCaptureDevice] = {
        captureDevices.filter { $0.position == .back }
    }()
    var captureDevice: AVCaptureDevice?
    var frontDeviceIndex: Int = -1
    var rearDeviceIndex: Int = -1

    // MARK: - Input
    var captureInput: AVCaptureInput?

    // MARK: - Output
    var captureOutput: AVCaptureOutput?

    let cameraPreviewLayer: AVCaptureVideoPreviewLayer

    override init() {
        self.captureSession = AVCaptureSession()
        self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        super.init()
    }

    func startSession() {
        sessionQueue.async { [unowned self] in
            captureSession.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [unowned self] in
            captureSession.stopRunning()
        }
    }
}

// MARK: - Configuration
extension CameraService {
    func configureSession() throws {
        captureSession.sessionPreset = .photo
        if captureDevices.isEmpty {
            throw CameraError.cameraUnavalible
        }
        if !rearCaptureDevices.isEmpty {
            try configureCameraInput(from: rearCaptureDevices, at: &rearDeviceIndex)
        } else if !frontCaptureDevices.isEmpty {
            try configureCameraInput(from: frontCaptureDevices, at: &frontDeviceIndex)
        }
        try configureCameraOutput()
    }

    private func configureCameraInput(from devices: [AVCaptureDevice], at index: inout Int) throws {
        index = (index + 1) / devices.count
        captureDevice = devices[index]
        guard let captureDevice else {
            throw CameraError.unknownError
        }
        let newCaptureInput = try AVCaptureDeviceInput(device: captureDevice)
        guard captureSession.canAddInput(newCaptureInput) else {
            throw CameraError.unknownError
        }
        self.captureInput = newCaptureInput
        sessionQueue.async { [unowned self] in
            captureSession.beginConfiguration()
            if !captureSession.inputs.isEmpty {
                for input in captureSession.inputs {
                    captureSession.removeInput(input)
                }
            }
            if let captureInput {
                captureSession.addInput(captureInput)
            }
            captureSession.commitConfiguration()
        }
    }

    private func configureCameraOutput() throws {
        let captureOutput = AVCapturePhotoOutput()
        guard captureSession.canAddOutput(captureOutput) else {
            throw CameraError.unknownError
        }
        self.captureOutput = captureOutput
        sessionQueue.async { [unowned self] in
            captureSession.beginConfiguration()
            if !captureSession.outputs.isEmpty {
                for output in captureSession.outputs {
                    captureSession.removeOutput(output)
                }
            }
            captureSession.addOutput(captureOutput)
            captureSession.commitConfiguration()
        }
    }
}

// MARK: - Permission
extension CameraService {
    var cameraPermissionStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requestCameraPermission() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {

}
