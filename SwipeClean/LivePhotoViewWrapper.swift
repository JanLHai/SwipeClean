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
    @AppStorage("mediaMuted") var mediaMuted: Bool = false

    func makeUIView(context: Context) -> PHLivePhotoView {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        return view
    }

    func updateUIView(_ uiView: PHLivePhotoView, context: Context) {
        uiView.livePhoto = livePhoto
        // Bei aktiviertem "mediaMuted" wird hint playback (stumm) genutzt,
        // andernfalls wird full playback mit Ton verwendet.
        uiView.startPlayback(with: mediaMuted ? .hint : .full)
    }
}

struct LivePhotoViewWrapper_Previews: PreviewProvider {
    static var previews: some View {
        Text("LivePhotoViewWrapper Preview")
    }
}
