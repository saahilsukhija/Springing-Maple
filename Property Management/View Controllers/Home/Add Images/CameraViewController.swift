import UIKit
import AVFoundation
import AVKit

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    var captureSession: AVCaptureSession!
    var currentCamera: AVCaptureDevice!
    var frontCamera: AVCaptureDevice?
    var backCamera: AVCaptureDevice?
    var photoOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var capturedImages: [UIImage] = []
    var flickerView: UIView?
    var flashButton: UIImageView!
    var pinchGesture: UIPinchGestureRecognizer!
    var parentVC: UIViewController!
    var zoomFactor: Double = 2
    var flashMode: AVCaptureDevice.FlashMode = .off // Default flash mode
    var zoomLabel: UILabel!
    var lastImagePreviewImageView: UIImageView!
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        // Get available camera devices
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTripleCamera], mediaType: .video, position: .unspecified)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == .front {
                frontCamera = device
            } else if device.position == .back {
                backCamera = device
            }
        }
        
        for device in AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified).devices {
            if device.position == .front {
                frontCamera = device
            }
        }
        
        // Set default camera to back camera
        currentCamera = backCamera
        
        
        let viewWidth = view.frame.size.width
        let guide = view.safeAreaLayoutGuide
        let viewHeight = guide.layoutFrame.size.height
        let desiredHeight = viewWidth * 4/3
        do {
            let input = try AVCaptureDeviceInput(device: currentCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            photoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            
            previewLayer.frame = CGRect(x: 0, y: (viewHeight - desiredHeight)/3, width: viewWidth, height: desiredHeight)
            view.layer.addSublayer(previewLayer)
            
            // Start the session on a background thread
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        } catch let error {
            print("Error Unable to initialize camera:  \(error.localizedDescription)")
        }
        updateZoom(scale: 2)
        let visualEffectView = UIView()
        visualEffectView.backgroundColor = .black
        visualEffectView.frame = CGRect(x: 0, y: (viewHeight - desiredHeight)/3 + desiredHeight, width: view.frame.size.width, height: 300)
        view.addSubview(visualEffectView)
        
        // Capture Button
        let captureButton = CustomCaptureButton(frame: CGRect(x: (view.frame.size.width - 70) / 2, y: (viewHeight - desiredHeight)/3 + desiredHeight + 30, width: 70, height: 70))
        captureButton.layer.cornerRadius = captureButton.frame.size.width / 2
        captureButton.addTarget(self, action: #selector(didTapCaptureButton), for: .touchUpInside)
        view.addSubview(captureButton)
        
        lastImagePreviewImageView = UIImageView(frame: CGRect(x: 35, y: (viewHeight - desiredHeight)/3 + desiredHeight + 40, width: 50, height: 50))
        lastImagePreviewImageView.backgroundColor = .black
        lastImagePreviewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self,action: #selector(didTapCloseButton)))
        lastImagePreviewImageView.isUserInteractionEnabled = true
        lastImagePreviewImageView.layer.borderWidth = 2
        lastImagePreviewImageView.layer.borderColor = UIColor.white.cgColor
        lastImagePreviewImageView.isHidden = true
        view.addSubview(lastImagePreviewImageView)
        
        // Switch Camera Button
        let switchCameraButton = UIImageView(frame: CGRect(x: view.frame.size.width - 90, y: (viewHeight - desiredHeight)/3 + desiredHeight + 45, width: 40, height: 40))
        switchCameraButton.image = UIImage(systemName: "arrow.triangle.2.circlepath")
        switchCameraButton.contentMode = .scaleAspectFit
        switchCameraButton.tintColor = .white
        switchCameraButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapSwitchCameraButton)))
        switchCameraButton.isUserInteractionEnabled = true
        view.addSubview(switchCameraButton)
        
        // Flash Toggle Button
        flashButton = UIImageView(frame: CGRect(x: 20, y: (viewHeight - desiredHeight)/6 + 5, width: 30, height: 30))
        flashButton.image = UIImage(systemName: "bolt.slash.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .thin))
        flashButton.tintColor = .white
        
        flashButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleFlash)))
        flashButton.isUserInteractionEnabled = true
        view.addSubview(flashButton)
        
        zoomLabel = UILabel(frame: CGRect(x: viewWidth/2-20, y: (viewHeight - desiredHeight)/3 + desiredHeight - 50, width: 40, height: 40))
        zoomLabel.layer.cornerRadius = 20
        zoomLabel.font = UIFont(name: "Montserrat-Regular", size: 16)
        zoomLabel.text = "1x"
        zoomLabel.textAlignment = .center
        zoomLabel.textColor = .systemYellow
        zoomLabel.isUserInteractionEnabled = true
        zoomLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(zoomLabelClicked)))
        
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = CGRect(x: viewWidth/2-20, y: (viewHeight - desiredHeight)/3 + desiredHeight - 50, width: 40, height: 40)
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.layer.masksToBounds = true
        blurEffectView.layer.cornerRadius = 20
        
        view.addSubview(blurEffectView)
        view.addSubview(zoomLabel)
        
        let xButton = UIImageView(frame: CGRect(x: viewWidth - 50, y: (viewHeight - desiredHeight)/6 + 10, width: 20, height: 20))
        xButton.image = UIImage(systemName: "multiply")
        xButton.tintColor = .white
        xButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapCloseButton)))
        xButton.isUserInteractionEnabled = true
        view.addSubview(xButton)
        
        setupPinchGesture()
        configureHardwareInteraction()

    }
    
    
    
    func configureHardwareInteraction() {
        // Create a new capture event interaction with a handler that captures a photo.
        
        if #available(iOS 17.2, *) {
            let interaction = AVCaptureEventInteraction { [weak self] event in
                // Capture a photo on "press up" of a hardware button.
                if event.phase == .ended {
                    self?.didTapCaptureButton()
                }
            }
            self.view.addInteraction(interaction)
        } else {
            // Fallback on earlier versions
        }
    }
    
    func setupPinchGesture() {
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        view.addGestureRecognizer(pinchGesture)
    }
    
    func updateZoom(scale factor: CGFloat) {
        
        guard let device = currentCamera else { return }
        
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            device.videoZoomFactor = factor
        } catch {
            debugPrint(error)
        }
    }
    
    @objc func handlePinchGesture(_ pinch: UIPinchGestureRecognizer) {
        guard let device = currentCamera else { return }
        
        func minMaxZoom(_ factor: CGFloat) -> CGFloat { return min(max(factor, 1.0), device.activeFormat.videoMaxZoomFactor) }
        
        let newScaleFactor = minMaxZoom(pinch.scale * CGFloat(zoomFactor))
        
        switch pinch.state {
        case .began, .changed:
            updateZoom(scale: newScaleFactor)
            let actualScaleFactor = currentCamera == backCamera ? newScaleFactor / 2 : newScaleFactor
            if (actualScaleFactor*10).rounded(.down)/10 == actualScaleFactor.rounded(.down) {
                zoomLabel.text = "\(Int(actualScaleFactor))x"
            } else {
                zoomLabel.text = "\((actualScaleFactor*10).rounded(.down)/10)x"
            }
            
        case .ended:
            zoomFactor = Double(minMaxZoom(newScaleFactor))
            updateZoom(scale: CGFloat(zoomFactor))
        default: break
        }
        
    }
    
    @objc func didTapCaptureButton() {
        // Add a flash view
        if let photoOutputConnection = photoOutput.connection(with: AVMediaType.video) {
            switch UIDevice.current.orientation {
            case .unknown:
                photoOutputConnection.videoOrientation = .portrait
            case .portrait:
                photoOutputConnection.videoOrientation = .portrait
            case .portraitUpsideDown:
                photoOutputConnection.videoOrientation = .portraitUpsideDown
            case .landscapeLeft:
                photoOutputConnection.videoOrientation = .landscapeRight
            case .landscapeRight:
                photoOutputConnection.videoOrientation = .landscapeLeft
            case .faceUp:
                photoOutputConnection.videoOrientation = .portrait
            case .faceDown:
                photoOutputConnection.videoOrientation = .portrait
            @unknown default:
                print("huh")
            }
            
        }
        flickerView = UIView(frame: view.bounds)
        flickerView?.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        if let flickerView = flickerView {
            view.addSubview(flickerView)
            UIView.animate(withDuration: 0.2, animations: {
                flickerView.alpha = 0
            }) { (_) in
                flickerView.removeFromSuperview()
            }
        }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode // Set the flash mode
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc func didTapSwitchCameraButton() {
        captureSession.beginConfiguration()
        
        // Remove current input
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else {
            captureSession.commitConfiguration()
            return
        }
        
        captureSession.removeInput(currentInput)
        
        // Choose new camera
        if currentCamera == backCamera {
            currentCamera = frontCamera
            zoomFactor = 1
        } else {
            currentCamera = backCamera
            zoomFactor = 2
        }
        zoomLabel.text = "1x"
        
        // Add new input
        do {
            let newInput = try AVCaptureDeviceInput(device: currentCamera)
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
            }
        } catch {
            print("Error switching camera: \(error.localizedDescription)")
        }
        
        captureSession.commitConfiguration()
    }
    
    @objc func didTapCloseButton() {
        // Stop the session and dismiss the view controller
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
        }
        dismiss(animated: true, completion: nil)
    }
    
    @objc func toggleFlash() {
        if flashMode == .off {
            flashMode = .on
            flashButton.image = UIImage(systemName: "bolt.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .thin))
        } else {
            flashMode = .off
            flashButton.image = UIImage(systemName: "bolt.slash.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .thin))
        }
    }
    
    @objc func zoomLabelClicked() {
        if currentCamera == frontCamera {
            zoomFactor = 1
            updateZoom(scale: 1)
            zoomLabel.text = "1x"
            return
        }
        
        let actualZoom = (zoomFactor*10).rounded(.down)/20
        
        if actualZoom > 2 {
            zoomFactor = 4
            zoomLabel.text = "2x"
        }
        else if actualZoom == 2{
            zoomFactor = 1
            zoomLabel.text = "0.5x"
        }
        else if actualZoom > 1 {
            zoomFactor = 2
            zoomLabel.text = "1x"
        }
        else if actualZoom == 1 {
            zoomFactor = 4
            zoomLabel.text = "2x"
        } 
        else if actualZoom == 0.5 {
            zoomFactor = 2
            zoomLabel.text = "1x"
        } 
        else {
            zoomFactor = 1
            zoomLabel.text = "0.5x"
        }
        updateZoom(scale: zoomFactor)
        
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        guard let image = UIImage(data: imageData) else { return }
        capturedImages.append(image)
        if let vc = parentVC as? PhotoUploadVC {
            vc.newImageAdded(image, key: -1, fromGallery: false)
        }
        lastImagePreviewImageView.image = image
        lastImagePreviewImageView.isHidden = false
    }
}

class CustomCaptureButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupButton()
    }
    
    private func setupButton() {
        backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        let outerRingPath = UIBezierPath(ovalIn: rect.insetBy(dx: 5, dy: 5))
        UIColor.white.setStroke()
        outerRingPath.lineWidth = 4
        outerRingPath.stroke()
        
        let innerCirclePath = UIBezierPath(ovalIn: rect.insetBy(dx: 10, dy: 10))
        UIColor.white.setFill()
        innerCirclePath.fill()
    }
}

