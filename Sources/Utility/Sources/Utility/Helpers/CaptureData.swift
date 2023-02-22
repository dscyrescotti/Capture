//
//  CaptureData.swift
//  Capture
//
//  Created by Aye Chan on 2/22/23.
//

import Foundation

public struct CaptureData {
    public var uniqueId: Int64
    public var photo: Data?
    public var livePhotoURL: URL?

    public init(uniqueId: Int64) {
        self.uniqueId = uniqueId
    }

    mutating public func setPhoto(_ photo: Data?) {
        self.photo = photo
    }

    mutating public func setLivePhotoURL(_ url: URL) {
        self.livePhotoURL = url
    }
}
