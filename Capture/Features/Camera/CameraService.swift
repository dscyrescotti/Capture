//
//  CameraService.swift
//  Capture
//
//  Created by Aye Chan on 2/16/23.
//

import Foundation
import AVFoundation

class CameraService: NSObject {
    let photoLibrary: PhotoLibraryService

    // MARK: - Session
    let captureSession: AVCaptureSession
    var sessionQueue: DispatchQueue = DispatchQueue(label: "capture-session")

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

    // MARK: - Input
    var captureInput: AVCaptureInput?

    // MARK: - Output
    var captureOutput: AVCaptureOutput?
    var isAvailableLivePhoto: Bool {
        guard let captureOutput = captureOutput as? AVCapturePhotoOutput, captureOutput.availablePhotoCodecTypes.contains(.hevc) else {
            return false
        }
        return captureOutput.isLivePhotoCaptureSupported
    }

    // MARK: - Preview
    let cameraPreviewLayer: AVCaptureVideoPreviewLayer

    // MARK: - Image
    var photoImageData: Data?

    init(photoLibrary: PhotoLibraryService) {
        self.photoLibrary = photoLibrary
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

// MARK: - Capture
extension CameraService {
    func capturePhoto(enablesLivePhoto: Bool = true) {
        guard let captureOutput = captureOutput as? AVCapturePhotoOutput else { return }
        let captureSettings: AVCapturePhotoSettings
        captureOutput.isLivePhotoCaptureEnabled = isAvailableLivePhoto && enablesLivePhoto
        if captureOutput.isLivePhotoCaptureEnabled {
            captureSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            captureSettings.livePhotoMovieFileURL = FileManager.default.temporaryDirectory
        } else {
            captureSettings = AVCapturePhotoSettings()
        }
        captureOutput.capturePhoto(with: captureSettings, delegate: self)
    }
}

// MARK: - Configuration
extension CameraService {
    func configureSession() throws -> CameraMode {
        captureSession.sessionPreset = .photo
        if captureDevices.isEmpty {
            throw CameraError.cameraUnavalible
        }
        var cameraMode: CameraMode = .none
        if !rearCaptureDevices.isEmpty {
            cameraMode = try configureCameraInput(from: rearCaptureDevices, for: .rear)
        } else if !frontCaptureDevices.isEmpty {
            cameraMode = try configureCameraInput(from: frontCaptureDevices, for: .front)
        }
        try configureCameraOutput()
        sessionQueue.async { [unowned self] in
            captureSession.beginConfiguration()
            if let captureInput {
                captureSession.addInput(captureInput)
            }
            if let captureOutput {
                captureSession.addOutput(captureOutput)
            }
            captureSession.commitConfiguration()
        }
        return cameraMode
    }

    @discardableResult
    private func configureCameraInput(from devices: [AVCaptureDevice], for cameraMode: CameraMode, at index: Int = 0) throws -> CameraMode {
        guard index < devices.count else { throw CameraError.unknownError }
        captureDevice = devices[index]
        guard let captureDevice else {
            throw CameraError.unknownError
        }
        if let captureInput {
            captureSession.removeInput(captureInput)
        }
        let newCaptureInput = try AVCaptureDeviceInput(device: captureDevice)
        guard captureSession.canAddInput(newCaptureInput) else {
            throw CameraError.unknownError
        }
        self.captureInput = newCaptureInput
        return cameraMode
    }

    private func configureCameraOutput() throws {
        let captureOutput = AVCapturePhotoOutput()
        captureOutput.isLivePhotoCaptureEnabled = captureOutput.isLivePhotoCaptureSupported
        guard captureSession.canAddOutput(captureOutput) else {
            throw CameraError.unknownError
        }
        self.captureOutput = captureOutput
    }
}

// MARK: - Camera Switching
extension CameraService {
    func switchCameraDevice(to index: Int, for captureMode: CameraMode) throws -> CameraMode {
        var cameraMode: CameraMode
        switch captureMode {
        case .front:
            cameraMode = try configureCameraInput(from: frontCaptureDevices, for: captureMode, at: index)
        case .rear:
            cameraMode = try configureCameraInput(from: rearCaptureDevices, for: captureMode, at: index)
        case .none:
            cameraMode = .none
        }
        sessionQueue.async { [unowned self] in
            captureSession.beginConfiguration()
            if let captureInput {
                captureSession.addInput(captureInput)
            }
            captureSession.commitConfiguration()
        }
        return cameraMode
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
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            print("[ERROR]: \(error.localizedDescription)")
            return
        }
        self.photoImageData = photo.fileDataRepresentation()
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL, duration: CMTime, photoDisplayTime: CMTime, resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error {
            print("[Error]: \(error.localizedDescription)")
            return
        }
        guard let photoImageData else {
            return
        }
        print("[URL]: \(outputFileURL.absoluteString)")
        Task {
            do {
                try await photoLibrary.savePhoto(for: photoImageData, withLivePhotoURL: outputFileURL)
            } catch {
                print("[Error]: \(error.localizedDescription)")
            }
        }
    }
}
