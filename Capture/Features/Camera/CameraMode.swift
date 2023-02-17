//
//  CameraMode.swift
//  Capture
//
//  Created by Aye Chan on 2/16/23.
//

import Foundation

enum CameraMode {
    case front
    case rear
    case none

    var opposite: CameraMode {
        switch self {
        case .front:
            return .rear
        case .rear:
            return .front
        case .none:
            return .none
        }
    }
}
