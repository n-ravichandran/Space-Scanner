//
//  ScannerView.swift
//  SpaceScanner
//
//  Created by Niranjan Ravichandran on 8/24/22.
//

import SwiftUI
import Lottie

struct Scanner: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UINavigationController {
        UINavigationController(rootViewController: RoomCaptureViewController())
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {

    }

}

struct PreviewView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UINavigationController {
        UINavigationController(rootViewController: PreviewViewController())
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {

    }

}


struct SimpleAnimationView: UIViewRepresentable {

    let animationName: String

    func makeUIView(context: Context) -> some AnimationView {
        let animationView = AnimationView(animation: Animation.named(animationName))
        animationView.loopMode = .loop
        animationView.contentMode = .scaleAspectFit
        animationView.clipsToBounds = true
        animationView.play()
        return animationView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }

}
