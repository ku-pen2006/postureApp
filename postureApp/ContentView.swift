import SwiftUI
import AVFoundation
import Vision
import AppKit

// MARK: - カメラ管理
class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private var shoulderAngles: [Double] = [] // 肩角度の履歴

    override init() {
        super.init()
        setupCamera()
    }

    private func setupCamera() {
        session.beginConfiguration()

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .unspecified), // .front より .unspecified の方がMacでは確実
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else {
            print("❌ カメラのセットアップに失敗しました")
            return
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.queue"))

        guard session.canAddOutput(output) else {
            print("❌ ビデオ出力の追加に失敗しました")
            return
        }
        session.addOutput(output)

        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
}

// MARK: - 姿勢判定処理
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let faceRequest = VNDetectFaceLandmarksRequest()
        let bodyRequest = VNDetectHumanBodyPoseRequest()

        // 💡 向き(orientation)の指定を削除
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([faceRequest, bodyRequest])
        } catch {
            print("❌ Visionリクエストの実行に失敗: \(error)")
            return
        }

        // --- 顔判定 ---
        // 💡 as? でのキャストが不要なため修正
        if let faces = faceRequest.results, let face = faces.first {
            analyzeFace(face)
        }

        // --- 肩判定 ---
        // 💡 as? でのキャストが不要なため修正
        if let bodies = bodyRequest.results, let body = bodies.first {
            analyzeShoulders(body)
        }
    }

    private func analyzeFace(_ face: VNFaceObservation) {
        if let roll = face.roll?.doubleValue {
            // ラジアンから度への変換（分かりやすさのため）
            let rollAngle = roll * 180 / .pi
            if abs(rollAngle) < 6.0 { // ±6度以内
                print("🙂 顔は水平")
            } else {
                print("⚠️ 顔が傾いています (roll=\(String(format: "%.1f", rollAngle))度)")
            }
        }

        // 前傾チェック（顔の大きさで判定）
        let faceHeight = face.boundingBox.height
        if faceHeight > 0.45 {
            print("⚠️ 前傾しています（画面に近すぎ）")
        }

        // 横ズレチェック
        let offset = abs(face.boundingBox.midX - 0.5)
        if offset > 0.15 { // 閾値を少し広げる
            print("⚠️ 横にズレています")
        }
    }

    private func analyzeShoulders(_ body: VNHumanBodyPoseObservation) {
        // 💡 recognizedPointsの指定方法を修正
        guard let points = try? body.recognizedPoints(.all),
              let leftShoulder = points[.leftShoulder], leftShoulder.confidence > 0.3, // 認識信頼度の閾値を少し下げる
              let rightShoulder = points[.rightShoulder], rightShoulder.confidence > 0.3 else {
            return
        }

        let dx = rightShoulder.location.x - leftShoulder.location.x
        let dy = rightShoulder.location.y - leftShoulder.location.y
        let angle = atan2(dy, dx)

        // 平滑化（直近10フレームの平均）
        shoulderAngles.append(angle)
        if shoulderAngles.count > 10 {
            shoulderAngles.removeFirst()
        }
        let avgAngle = shoulderAngles.reduce(0,+) / Double(shoulderAngles.count)
        
        // ラジアンから度への変換
        let avgAngleDegrees = avgAngle * 180 / .pi

        if abs(avgAngleDegrees) < 5.0 { // ±5度以内
            print("✅ 肩は水平")
        } else {
            print("⚠️ 肩が傾いています (avg=\(String(format: "%.1f", avgAngleDegrees))度)")
        }
    }
}

// MARK: - SwiftUIビュー
struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()

    var body: some View {
        CameraPreview(session: cameraManager.session)
            .ignoresSafeArea()
    }
}

// MARK: - カメラプレビュー
struct CameraPreview: NSViewRepresentable {
    let session: AVCaptureSession

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        
        // 💡 viewのlayerが確定してからframeを設定
        view.layer = CALayer()
        view.layer?.addSublayer(previewLayer)
        
        // 💡 AutoresizingMaskを設定してリサイズに対応
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        previewLayer.frame = view.bounds

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
//import SwiftUI
//import AVFoundation
//import Vision
//import AppKit  // Macアプリ用
//
//// MARK: - カメラ管理 & 姿勢検知
//class CameraManager: NSObject, ObservableObject {
//    let session = AVCaptureSession()
//    
//    override init() {
//        super.init()
//        setupCamera()
//    }
//    
//    private func setupCamera() {
//        session.beginConfiguration()
//        
//        // Macのカメラを取得
//        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
//                                                   for: .video,
//                                                   position: .front),
//              let input = try? AVCaptureDeviceInput(device: camera),
//              session.canAddInput(input) else {
//            print("カメラのセットアップに失敗しました。")
//            return
//        }
//        session.addInput(input)
//        
//        // フレームを処理するための出力を設定
//        let output = AVCaptureVideoDataOutput()
//        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.queue"))
//        
//        guard session.canAddOutput(output) else {
//            print("ビデオ出力の追加に失敗しました。")
//            return
//        }
//        session.addOutput(output)
//        
//        session.commitConfiguration()
//        
//        // セッションを開始
//        DispatchQueue.global(qos: .userInitiated).async {
//            self.session.startRunning()
//        }
//    }
//}
//
//// 姿勢検知ロジック
//extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
//    func captureOutput(_ output: AVCaptureOutput,
//                       didOutput sampleBuffer: CMSampleBuffer,
//                       from connection: AVCaptureConnection) {
//        
//        // ① まず、このメソッドが呼ばれているかを確認
//        print("--- フレームをキャプチャしました ---")
//        
//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//        
//        let request = VNDetectHumanBodyPoseRequest()
//        
//        do {
//            // ✅ ここで orientation を .leftMirrored に変更
//                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
//                                                    orientation: .leftMirrored, // ← ここポイント
//                                                    options: [:])
//            try handler.perform([request])
//        } catch {
//            print("❌ Visionリクエストでエラーが発生しました: \(error)")
//            return
//        }
//        
//        print("🔍 検出結果:", request.results?.count ?? 0)
//        // ② Visionが「人」を検出したかを確認
//        guard let results = request.results, !results.isEmpty else {
//            print("👤 人が検出されませんでした。")
//            return
//        }
//        print("✅ \(results.count)人の人を検出しました。")
//        
//        for observation in results {
//            guard let points = try? observation.recognizedPoints(.all) else {
//                print("⚠️ 関節ポイントの取得に失敗しました。")
//                continue
//            }
//            
//            // ③ 必要な関節の信頼度（Confidence）をチェック
//            let lsConf = points[.leftShoulder]?.confidence ?? 0
//            let rsConf = points[.rightShoulder]?.confidence ?? 0
//            let noseConf = points[.nose]?.confidence ?? 0
//            let leConf = points[.leftEar]?.confidence ?? 0
//            let reConf = points[.rightEar]?.confidence ?? 0
//            
//            print(String(format: "信頼度 -> 肩(L:%.2f, R:%.2f), 鼻:%.2f, 耳(L:%.2f, R:%.2f)", lsConf, rsConf, noseConf, leConf, reConf))
//            
//            // ④ 信頼度が0.5を超えているかを確認
//            guard lsConf > 0.5, rsConf > 0.5, noseConf > 0.5, leConf > 0.5, reConf > 0.5 else {
//                print("📉 信頼度が不足しているため、姿勢判定をスキップします。")
//                continue
//            }
//            
//            // --- ここまで到達すれば、最終的な姿勢判定が行われるはず ---
//            print("👍 信頼度の条件をクリア！姿勢を判定します。")
//            
//            // (元の判定ロジックは省略)
//            let shoulderWidth = abs(points[.leftShoulder]!.location.x - points[.rightShoulder]!.location.x)
//            let shoulderCenter = CGPoint(x: (points[.leftShoulder]!.location.x + points[.rightShoulder]!.location.x) / 2, y: (points[.leftShoulder]!.location.y + points[.rightShoulder]!.location.y) / 2)
//            let horizontalOffset = abs(points[.nose]!.location.x - shoulderCenter.x)
//            let isCentered = horizontalOffset < (shoulderWidth * 0.15)
//            let verticalTilt = abs(points[.leftEar]!.location.y - points[.rightEar]!.location.y)
//            let isLevel = verticalTilt < (shoulderWidth * 0.10)
//            
//            if isCentered && isLevel {
//                print("✅ 良い姿勢です！")
//            } else {
//                print("⚠️ 姿勢が崩れています")
//            }
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
//// MARK: - Mac用のカメラプレビュー
//struct CameraPreview: NSViewRepresentable {
//    let session: AVCaptureSession
//    
//    func makeNSView(context: Context) -> NSView {
//        let view = NSView()
//        view.wantsLayer = true // NSViewがレイヤーを持つように設定
//        
//        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
//        previewLayer.videoGravity = .resizeAspectFill
//        
//        // viewのサイズ変更にpreviewLayerが追従するように設定
//        previewLayer.frame = view.bounds
//        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
//        
//        view.layer?.addSublayer(previewLayer)
//        
//        return view
//    }
//    
//    func updateNSView(_ nsView: NSView, context: Context) {}
//}
