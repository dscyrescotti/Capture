//
//  CameraMode.swift
//  Capture
//
//  Created by Aye Chan on 2/16/23.
//

import Foundation

public enum CameraMode {
    case front
    case rear
    case none

    public var opposite: CameraMode {
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
