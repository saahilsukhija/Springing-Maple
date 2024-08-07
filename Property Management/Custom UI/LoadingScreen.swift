//
//  LoadingScreen.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/4/24.
//

import UIKit
import Lottie

extension UIViewController {
    
    func createLoadingScreen(frame: CGRect, message: String = "", animation: String? = nil) -> UIView {
        
        let loadingScreen = UIView(frame: frame)
        loadingScreen.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
        if let animation = animation {
            let animationView = LottieAnimationView(name: animation)
            animationView.center = view.center
            animationView.contentMode = .scaleAspectFill
            animationView.loopMode = .loop
            animationView.play()
            loadingScreen.addSubview(animationView)
        }
        else {
            let loadingIndicator = UIActivityIndicatorView(frame: view.frame)
            loadingIndicator.style = .large
            loadingIndicator.startAnimating()
            loadingScreen.addSubview(loadingIndicator)
        }
        
        let messageView = UILabel(frame: CGRect(x: view.center.x - 100, y: view.center.y + 60, width: 200, height: 50))
        messageView.textAlignment = .center
        messageView.font = UIFont(name: "Montserrat-Medium", size: 20)
        messageView.text = message
        messageView.numberOfLines = 0
        loadingScreen.addSubview(messageView)
        
        return loadingScreen
    }
    
}

