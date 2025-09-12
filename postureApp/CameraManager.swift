import AVFoundation
import Vision
import AppKit

class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private var shoulderAngles: [Double] = []
    private var history: PostureHistory

    private var lastProcessTime: Date = Date()
    private let processInterval: TimeInterval = 1

    // 👇 検出されなかった場合の処理用
    private var lastDetectedTime: Date = Date()
    private let detectionTimeout: TimeInterval = 3 // 3秒以上検出なしでリセット

    init(history: PostureHistory) {
        self.history = history
        super.init()
        checkCameraPermission { granted in
            if granted {
                self.setupCamera()
            } else {
                print("❌ カメラの利用が拒否されています。システム環境設定で許可してください。")
            }
        }
    }

    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
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

        let now = Date()
        guard now.timeIntervalSince(lastProcessTime) >= processInterval else { return }
        lastProcessTime = now

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

        var detected = false

        if let faces = faceRequest.results, let face = faces.first {
            analyzeFace(face)
            detected = true
        }

        if let bodies = bodyRequest.results, let body = bodies.first {
            analyzeShoulders(body)
            detected = true
        }

        if detected {
            lastDetectedTime = now
        } else {
            // 検出できなかった時間がしきい値を超えたらリセット
            if now.timeIntervalSince(lastDetectedTime) > detectionTimeout {
                print("🙆‍♂️ ユーザーが映っていません → セッションリセット")
                history.resetSession()
            }
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
