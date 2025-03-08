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
    // Persistente Einstellung für LivePhoto Auto-Play (lokal)
    @AppStorage("livePhotoAutoPlay") var livePhotoAutoPlay: Bool = false

    func makeUIView(context: Context) -> PHLivePhotoView {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        return view
    }

    func updateUIView(_ uiView: PHLivePhotoView, context: Context) {
        uiView.livePhoto = livePhoto
        if !livePhotoAutoPlay {
            uiView.startPlayback(with: .full)
        } else {
            uiView.stopPlayback()
        }
    }
}

struct LivePhotoViewWrapper_Previews: PreviewProvider {
    static var previews: some View {
        Text("LivePhotoViewWrapper Preview")
    }
}
