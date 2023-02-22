//
//  CaptureApp.swift
//  Capture
//
//  Created by Aye Chan on 2/16/23.
//

import App
import SwiftUI

@main
struct CaptureApp: App {

    init() {
        Application.setInitialRoute(to: .camera)
    }

    var body: some Scene {
        WindowGroup {
            Application()
        }
    }
}
