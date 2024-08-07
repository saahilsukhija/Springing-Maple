import UIKit
import AVFoundation
import AVKit

class VideoPreviewVC: UIViewController {
    
    static let identifier = "VideoPreviewScreen"
    
    var data: NSData!
    var image: UIImage!
    var key: Int!
    var parentVC: UIViewController!
    
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    @IBOutlet weak var videoContainerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func setup(with image: UIImage, data: NSData, key: Int, _ vc: UIViewController) {
        self.image = image
        self.data = data
        self.key = key
        self.parentVC = vc
        
        playVideo(from: data)
    }
    
    @IBAction func doneButtonClicked(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func deleteButtonClicked(_ sender: Any) {
        if let vc = parentVC as? PhotoUploadVC {
            vc.videoRemoved(image, key: key)
        }
        if let vc = parentVC as? AddPropertyImagesVC {
            vc.imageRemoved(image, key: key)
        }
        self.dismiss(animated: true)
    }
    
    func playVideo(from data: NSData) {
        // Save the NSData to a temporary file
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent("tempVideo.mov")
        
        do {
            try data.write(to: tempFileURL)
            playVideo(from: tempFileURL)
        } catch {
            print("Failed to write video data to temporary file: \(error.localizedDescription)")
        }
    }
    
    func playVideo(from url: URL) {
        // Create an AVPlayer
        player = AVPlayer(url: url)
        
        // Create an AVPlayerViewController
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        
        // Add the AVPlayerViewController as a child view controller
        if let playerViewController = playerViewController {
            addChild(playerViewController)
            videoContainerView.addSubview(playerViewController.view)
            playerViewController.view.frame = videoContainerView.bounds
            playerViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            playerViewController.didMove(toParent: self)
            
            // Play the video
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure the player view controller's view frame is updated when the view's layout changes
        playerViewController?.view.frame = videoContainerView.bounds
    }
}

