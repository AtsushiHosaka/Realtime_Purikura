import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    private var captureSession: AVCaptureSession!
    private var cameraLayer: AVCaptureVideoPreviewLayer!
    private var detectionLayer: CALayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
        setupLayers()
        startCaptureSession()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        guard let videoDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoDeviceInput = try! AVCaptureDeviceInput(device: videoDevice)
        if captureSession.canAddInput(videoDeviceInput) {
            captureSession.addInput(videoDeviceInput)
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
    }
    
    private func setupLayers() {
        cameraLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraLayer.videoGravity = .resizeAspectFill
        cameraLayer.frame = view.layer.bounds
        view.layer.addSublayer(cameraLayer)
        
        detectionLayer = CALayer()
        detectionLayer.frame = view.layer.bounds
        view.layer.addSublayer(detectionLayer)
    }
    
    private func startCaptureSession() {
        captureSession.startRunning()
    }
    
    private func detectFaces(in image: CVPixelBuffer) {
        let request = VNDetectFaceRectanglesRequest { (request, error) in
            DispatchQueue.main.async {
                self.detectionLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
                
                guard let results = request.results as? [VNFaceObservation] else { return }
                for face in results {
                    self.drawOverlay(for: face)
                }
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        try? handler.perform([request])
    }
    
    private func drawOverlay(for face: VNFaceObservation) {
        let boundingBox = face.boundingBox
        let size = CGSize(
            width: boundingBox.width * view.bounds.height * 1.2,
            height: boundingBox.height * view.bounds.width * 1.2
        )
        let origin = CGPoint(
            x: boundingBox.maxY * view.bounds.width - size.height,
            y: boundingBox.minX * view.bounds.height
        )
        let faceFrame = CGRect(origin: origin, size: size)
        
        // 顔の四角を描画
        let faceBoxLayer = CALayer()
        faceBoxLayer.frame = faceFrame
        faceBoxLayer.borderWidth = 2.0
        faceBoxLayer.borderColor = UIColor.red.cgColor
        detectionLayer.addSublayer(faceBoxLayer)
        
        // 左上に画像を描画
        let overlayImage1 = UIImage(named: "Gaha_Face")!
        let overlayLayer1 = CALayer()
        overlayLayer1.contents = overlayImage1.cgImage
        overlayLayer1.frame = CGRect(x: faceFrame.minX, y: faceFrame.minY - 30, width: faceFrame.width, height: faceFrame.height + 40)  // サイズと位置を調整
        detectionLayer.addSublayer(overlayLayer1)
        
        // 右上に画像を描画
//        let overlayImage2 = UIImage(named: "nekomimi_right.png")!
//        let overlayLayer2 = CALayer()
//        overlayLayer2.contents = overlayImage2.cgImage
//        overlayLayer2.frame = CGRect(x: faceFrame.maxX - 50, y: faceFrame.minY - 50, width: 50, height: 50)  // サイズと位置を調整
//        detectionLayer.addSublayer(overlayLayer2)
    }
    
    
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        detectFaces(in: pixelBuffer)
    }
}
