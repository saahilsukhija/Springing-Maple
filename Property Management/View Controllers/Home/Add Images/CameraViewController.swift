//
//  CameraViewController.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/26/24.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    
    var captureSession: AVCaptureSession!
    var currentCamera: AVCaptureDevice!
    var frontCamera: AVCaptureDevice?
    var backCamera: AVCaptureDevice?
    var photoOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var capturedImages: [UIImage] = []
    var flashView: UIView?
    var pinchGesture: UIPinchGestureRecognizer!
    var parentVC: UIViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        // Get available camera devices
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        let devices = deviceDiscoverySession.devices

        for device in devices {
            if device.position == .front {
                frontCamera = device
            } else if device.position == .back {
                backCamera = device
            }
        }

        // Set default camera to back camera
        currentCamera = backCamera

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
            previewLayer.frame = view.layer.bounds
            view.layer.addSublayer(previewLayer)

            // Start the session on a background thread
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        } catch let error {
            print("Error Unable to initialize camera:  \(error.localizedDescription)")
        }
        
        let blurEffect = UIBlurEffect(style: .light)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.frame = CGRect(x: 0, y: view.frame.size.height - 170, width: view.frame.size.width, height: 170)
        view.addSubview(visualEffectView)
        
        // Capture Button
        let captureButton = CustomCaptureButton(frame: CGRect(x: (view.frame.size.width - 70) / 2, y: view.frame.size.height - 155, width: 70, height: 70))
        //captureButton.backgroundColor = .accentColor
        captureButton.layer.cornerRadius = captureButton.frame.size.width / 2
        captureButton.addTarget(self, action: #selector(didTapCaptureButton), for: .touchUpInside)
        view.addSubview(captureButton)
        
        // Close Button
        let closeButton = UIButton(frame: CGRect(x: 35, y: view.frame.size.height - 140, width: 70, height: 30))
        let mutableString = NSMutableAttributedString(string: "Close", attributes: [NSAttributedString.Key.font : UIFont(name: "Montserrat-SemiBold", size: 16) ?? .systemFont(ofSize: 16), .foregroundColor : UIColor.black])
        closeButton.setAttributedTitle(mutableString, for: .normal)
        closeButton.backgroundColor = .clear
        //closeButton.setTitleColor(.accentColor, for: .normal)
        closeButton.layer.cornerRadius = 15
        closeButton.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        view.addSubview(closeButton)
        
        let switchCameraButton = UIButton(type: .custom)
        switchCameraButton.frame = CGRect(x: view.frame.size.width - 90, y: view.frame.size.height - 140, width: 40, height: 40)
        switchCameraButton.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        switchCameraButton.imageView?.contentMode = .center
        switchCameraButton.tintColor = .black
        switchCameraButton.addTarget(self, action: #selector(didTapSwitchCameraButton), for: .touchUpInside)
        view.addSubview(switchCameraButton)
        
        setupPinchGesture()
    }
    
    func setupPinchGesture() {
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        view.addGestureRecognizer(pinchGesture)
    }

    @objc func handlePinchGesture(_ pinch: UIPinchGestureRecognizer) {
        guard let device = currentCamera else { return }

        if pinch.state == .changed {
            let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
            let pinchVelocityDividerFactor: CGFloat = 10.0
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                
                let desiredZoomFactor = device.videoZoomFactor + atan2(pinch.velocity, pinchVelocityDividerFactor)
                device.videoZoomFactor = max(1, min(desiredZoomFactor, maxZoomFactor))
            } catch {
                print("Error setting zoom: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func didTapCaptureButton() {
        
        // Add a flash view
        flashView = UIView(frame: view.bounds)
        flashView?.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        if let flashView = flashView {
            view.addSubview(flashView)
            UIView.animate(withDuration: 0.2, animations: {
                flashView.alpha = 0
            }) { (_) in
                flashView.removeFromSuperview()
            }
        }
        
        let settings = AVCapturePhotoSettings()
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
            } else {
                currentCamera = backCamera
            }
            
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
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        guard let image = UIImage(data: imageData) else { return }
        capturedImages.append(image)
        if let vc = parentVC as? PhotoUploadVC {
            vc.newImageAdded(image, key: -1)
        }
        //print("ADDED TO CAPTURED IMAGES")
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
        UIColor.black.setFill()
        innerCirclePath.fill()
    }
}
