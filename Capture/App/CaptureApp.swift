//
//  CaptureApp.swift
//  Capture
//
//  Created by Aye Chan on 2/16/23.
//

import SwiftUI

@main
struct CaptureApp: App {
    var body: some Scene {
        WindowGroup {
            CameraView(dependency: .live)
        }
    }
}
