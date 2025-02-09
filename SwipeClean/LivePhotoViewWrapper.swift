//
//  LivePhotoViewWrapper.swift
//  SwipeClean
//
//  Created by Jan Haider on 01.02.25.
//

import SwiftUI
import PhotosUI

struct LivePhotoViewWrapper: UIViewRepresentable {
    let livePhoto: PHLivePhoto

    func makeUIView(context: Context) -> PHLivePhotoView {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        return view
    }

    func updateUIView(_ uiView: PHLivePhotoView, context: Context) {
        uiView.livePhoto = livePhoto
        uiView.startPlayback(with: .full)
    }
}
