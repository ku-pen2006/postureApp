import SwiftUI
import AVFoundation
import Vision
import AppKit   // Macアプリ用

// カメラ管理クラス
class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        
        // Macの前面カメラ
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .front),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else {
            return
        }
        session.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.queue"))
        
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        
        session.commitConfiguration()
        session.startRunning()
    }
}

// 姿勢検知ロジック
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([request])
        
        guard let results = request.results as? [VNHumanBodyPoseObservation] else { return }
        
        for observation in results {
            if let points = try? observation.recognizedPoints(.all),
               let leftShoulder = points[.leftShoulder],
               let rightShoulder = points[.rightShoulder],
               let leftHip = points[.leftHip],
               let rightHip = points[.rightHip],
               leftShoulder.confidence > 0.5,
               rightShoulder.confidence > 0.5,
               leftHip.confidence > 0.5,
               rightHip.confidence > 0.5 {
                
                let shoulderCenter = CGPoint(x: (leftShoulder.location.x + rightShoulder.location.x) / 2,
                                             y: (leftShoulder.location.y + rightShoulder.location.y) / 2)
                let hipCenter = CGPoint(x: (leftHip.location.x + rightHip.location.x) / 2,
                                        y: (leftHip.location.y + rightHip.location.y) / 2)
                
                let dx = shoulderCenter.x - hipCenter.x
                let dy = shoulderCenter.y - hipCenter.y
                let angle = atan2(dy, dx) * 180 / .pi
                
                if abs(angle - 90) < 10 {
                    print("✅ 良い姿勢です！")
                } else {
                    print("⚠️ 姿勢が崩れています")
                }
            }
        }
    }
}

// SwiftUIビュー
struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        CameraPreview(session: cameraManager.session)
            .ignoresSafeArea()
    }
}

// Mac用のカメラプレビュー
struct CameraPreview: NSViewRepresentable {
    let session: AVCaptureSession
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = NSScreen.main?.frame ?? .zero
        view.layer = CALayer()
        view.layer?.addSublayer(previewLayer)
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
