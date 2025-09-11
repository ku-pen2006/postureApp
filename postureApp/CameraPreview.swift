//
//  CameraPreview.swift
//  postureApp
//
//  Created by 🐣 on 2025/09/11.
//

import SwiftUI
import AVFoundation
import AppKit

struct CameraPreview: NSViewRepresentable {
    let session: AVCaptureSession

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer = CALayer()
        view.layer?.addSublayer(previewLayer)
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        previewLayer.frame = view.bounds

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
