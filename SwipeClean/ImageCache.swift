//
//  ImageCache.swift
//  SwipeClean
//
//  Created by Jan Haider on 01.02.25.
//

import SwiftUI

class ImageCache: ObservableObject {
    @Published var cache: [String: UIImage] = [:]
}
