//
//  CaptureEvent.swift
//  Capture
//
//  Created by Aye Chan on 2/22/23.
//

import Foundation

public enum CaptureEvent {
    case initial(Int64)
    case photo(Int64, Data?)
    case livePhoto(Int64, URL)
    case end(Int64)
    case error(Int64, Error)
}
