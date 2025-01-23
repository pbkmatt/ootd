//
//  CameraPreview.swift
//  OOTD
//
//  Created by Matt Imhof on 1/22/25.
//


import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var cameraModel: CameraModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        // Dynamically attach the preview layer when available
        DispatchQueue.main.async {
            if let previewLayer = cameraModel.previewLayer {
                previewLayer.frame = view.bounds
                view.layer.addSublayer(previewLayer)
                print("Preview layer added to view in makeUIView.")
            } else {
                print("Preview layer is nil in makeUIView.")
            }
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Ensure the preview layer is updated dynamically
        DispatchQueue.main.async {
            if let previewLayer = cameraModel.previewLayer {
                previewLayer.frame = uiView.bounds
                if previewLayer.superlayer == nil {
                    uiView.layer.addSublayer(previewLayer)
                    print("Preview layer added to view in updateUIView.")
                }
            } else {
                print("Preview layer is nil in updateUIView.")
            }
        }
    }
}
