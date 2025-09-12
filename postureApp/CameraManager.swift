import AVFoundation
import Vision
import AppKit

class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private var shoulderAngles: [Double] = []
    private var history: PostureHistory
    
    private var lastProcessTime: Date = Date()
        /// 処理間隔（秒）
    private let processInterval: TimeInterval = 1
    
    init(history: PostureHistory) {
        self.history = history
        super.init()
        setupCamera()
    }

    private func setupCamera() {
        session.beginConfiguration()

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .unspecified),
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

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // --- ↓↓↓ ここにコードを追加 ↓↓↓ ---
               let now = Date()
               // lastProcessTime から processInterval（5秒）以上経過していなければ、処理をスキップ
               guard now.timeIntervalSince(lastProcessTime) >= processInterval else {
                   return
               }
               // 最終処理時間を現在時刻に更新
               lastProcessTime = now
               // --- ↑↑↑ ここまで ---

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let faceRequest = VNDetectFaceLandmarksRequest()
        let bodyRequest = VNDetectHumanBodyPoseRequest()

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        do {
            try handler.perform([faceRequest, bodyRequest])
        } catch {
            print("❌ Visionリクエスト失敗: \(error)")
            return
        }

        if let faces = faceRequest.results, let face = faces.first {
            analyzeFace(face)
        }

        if let bodies = bodyRequest.results, let body = bodies.first {
            analyzeShoulders(body)
        }
    }

    private func analyzeFace(_ face: VNFaceObservation) {
        var status: PostureType = .good

        if let roll = face.roll?.doubleValue {
            let rollAngle = roll * 180 / .pi
            if abs(rollAngle) >= 6.0 {
                print("⚠️ 顔が傾いています")
                status = .faceTilt
            }
        }

        let faceHeight = face.boundingBox.height
        if faceHeight > 0.45 {
            print("⚠️ 前傾しています")
            status = .forwardLean
        }

        let offset = abs(face.boundingBox.midX - 0.5)
        if offset > 0.15 {
            print("⚠️ 横ズレしています")
            status = .sideLean
        }

        history.add(status)
    }

    private func analyzeShoulders(_ body: VNHumanBodyPoseObservation) {
        guard let points = try? body.recognizedPoints(.all),
              let leftShoulder = points[.leftShoulder], leftShoulder.confidence > 0.3,
              let rightShoulder = points[.rightShoulder], rightShoulder.confidence > 0.3 else {
            return
        }

        let dx = rightShoulder.location.x - leftShoulder.location.x
        let dy = rightShoulder.location.y - leftShoulder.location.y
        let angle = atan2(dy, dx)

        shoulderAngles.append(angle)
        if shoulderAngles.count > 10 {
            shoulderAngles.removeFirst()
        }
        let avgAngle = shoulderAngles.reduce(0,+) / Double(shoulderAngles.count)
        let avgAngleDegrees = avgAngle * 180 / .pi

        if abs(avgAngleDegrees) >= 5.0 {
            print("⚠️ 肩が傾いています")
            history.add(.shoulderTilt)
        } else {
            history.add(.good)
        }
    }
}
