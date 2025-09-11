import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var history = PostureHistory()
    @StateObject private var cameraManager: CameraManager

    init() {
        let history = PostureHistory()
        _history = StateObject(wrappedValue: history)
        _cameraManager = StateObject(wrappedValue: CameraManager(history: history))
    }

    var body: some View {
        TabView {
            // リアルタイム
            CameraPreview(session: cameraManager.session)
                .tabItem { Label("リアルタイム", systemImage: "camera") }

            // グラフ
            GraphView(history: history)
                .tabItem { Label("グラフ", systemImage: "chart.bar.fill") }

            // 振り返り
            SummaryView(history: history)
                .tabItem { Label("振り返り", systemImage: "clock.fill") }
        }
    }
}

//import SwiftUI
//import AVFoundation
//import Vision
//import AppKit
//
//// MARK: - カメラ管理
//class CameraManager: NSObject, ObservableObject {
//    let session = AVCaptureSession()
//    private var shoulderAngles: [Double] = [] // 肩角度の履歴
//
//    override init() {
//        super.init()
//        setupCamera()
//    }
//
//    private func setupCamera() {
//        session.beginConfiguration()
//
//        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
//                                                   for: .video,
//                                                   position: .unspecified), // .front より .unspecified の方がMacでは確実
//              let input = try? AVCaptureDeviceInput(device: camera),
//              session.canAddInput(input) else {
//            print("❌ カメラのセットアップに失敗しました")
//            return
//        }
//        session.addInput(input)
//
//        let output = AVCaptureVideoDataOutput()
//        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.queue"))
//
//        guard session.canAddOutput(output) else {
//            print("❌ ビデオ出力の追加に失敗しました")
//            return
//        }
//        session.addOutput(output)
//
//        session.commitConfiguration()
//
//        DispatchQueue.global(qos: .userInitiated).async {
//            self.session.startRunning()
//        }
//    }
//}
//
//// MARK: - 姿勢判定処理
//extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
//    func captureOutput(_ output: AVCaptureOutput,
//                       didOutput sampleBuffer: CMSampleBuffer,
//                       from connection: AVCaptureConnection) {
//
//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//
//        let faceRequest = VNDetectFaceLandmarksRequest()
//        let bodyRequest = VNDetectHumanBodyPoseRequest()
//
//        // 💡 向き(orientation)の指定を削除
//        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
//        
//        do {
//            try handler.perform([faceRequest, bodyRequest])
//        } catch {
//            print("❌ Visionリクエストの実行に失敗: \(error)")
//            return
//        }
//
//        // --- 顔判定 ---
//        // 💡 as? でのキャストが不要なため修正
//        if let faces = faceRequest.results, let face = faces.first {
//            analyzeFace(face)
//        }
//
//        // --- 肩判定 ---
//        // 💡 as? でのキャストが不要なため修正
//        if let bodies = bodyRequest.results, let body = bodies.first {
//            analyzeShoulders(body)
//        }
//    }
//
//    private func analyzeFace(_ face: VNFaceObservation) {
//        if let roll = face.roll?.doubleValue {
//            // ラジアンから度への変換（分かりやすさのため）
//            let rollAngle = roll * 180 / .pi
//            if abs(rollAngle) < 6.0 { // ±6度以内
//                print("🙂 顔は水平")
//            } else {
//                print("⚠️ 顔が傾いています (roll=\(String(format: "%.1f", rollAngle))度)")
//            }
//        }
//
//        // 前傾チェック（顔の大きさで判定）
//        let faceHeight = face.boundingBox.height
//        if faceHeight > 0.45 {
//            print("⚠️ 前傾しています（画面に近すぎ）")
//        }
//
//        // 横ズレチェック
//        let offset = abs(face.boundingBox.midX - 0.5)
//        if offset > 0.15 { // 閾値を少し広げる
//            print("⚠️ 横にズレています")
//        }
//    }
//
//    private func analyzeShoulders(_ body: VNHumanBodyPoseObservation) {
//        // 💡 recognizedPointsの指定方法を修正
//        guard let points = try? body.recognizedPoints(.all),
//              let leftShoulder = points[.leftShoulder], leftShoulder.confidence > 0.3, // 認識信頼度の閾値を少し下げる
//              let rightShoulder = points[.rightShoulder], rightShoulder.confidence > 0.3 else {
//            return
//        }
//
//        let dx = rightShoulder.location.x - leftShoulder.location.x
//        let dy = rightShoulder.location.y - leftShoulder.location.y
//        let angle = atan2(dy, dx)
//
//        // 平滑化（直近10フレームの平均）
//        shoulderAngles.append(angle)
//        if shoulderAngles.count > 10 {
//            shoulderAngles.removeFirst()
//        }
//        let avgAngle = shoulderAngles.reduce(0,+) / Double(shoulderAngles.count)
//        
//        // ラジアンから度への変換
//        let avgAngleDegrees = avgAngle * 180 / .pi
//
//        if abs(avgAngleDegrees) < 5.0 { // ±5度以内
//            print("✅ 肩は水平")
//        } else {
//            print("⚠️ 肩が傾いています (avg=\(String(format: "%.1f", avgAngleDegrees))度)")
//        }
//    }
//}
//
//// MARK: - SwiftUIビュー
//struct ContentView: View {
//    @StateObject private var cameraManager = CameraManager()
//
//    var body: some View {
//        CameraPreview(session: cameraManager.session)
//            .ignoresSafeArea()
//    }
//}
//
//// MARK: - カメラプレビュー
//struct CameraPreview: NSViewRepresentable {
//    let session: AVCaptureSession
//
//    func makeNSView(context: Context) -> NSView {
//        let view = NSView()
//        view.wantsLayer = true
//
//        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
//        previewLayer.videoGravity = .resizeAspectFill
//        
//        // 💡 viewのlayerが確定してからframeを設定
//        view.layer = CALayer()
//        view.layer?.addSublayer(previewLayer)
//        
//        // 💡 AutoresizingMaskを設定してリサイズに対応
//        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
//        previewLayer.frame = view.bounds
//
//        return view
//    }
//
//    func updateNSView(_ nsView: NSView, context: Context) {}
//}
