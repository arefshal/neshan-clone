//
//  LaunchScreenViewController.swift
//  neshan
//
//  Created by Aref on 9/8/24.
//

import UIKit
import Lottie

class LaunchScreenViewController: UIViewController {
    
    private var animationView: LottieAnimationView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        // Animation setup
        if let animation = LottieAnimation.named("Animation") {
            animationView = LottieAnimationView(animation: animation)
            if let animationView = animationView {
                animationView.frame = view.bounds
                animationView.contentMode = .scaleAspectFit
                animationView.loopMode = .playOnce
                animationView.animationSpeed = 0.5
                view.addSubview(animationView)
            }
        } else {
            print("Error: Lottie animation not found!")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Play animation after view has appeared
        DispatchQueue.main.async { [weak self] in
            self?.animationView?.play { finished in
                print("Animation finished playing")
                
                // Add a 10 second delay
                DispatchQueue.main.asyncAfter(deadline: .now() ) {
                    self?.navigateToMapScreen()
                }
            }
        }
    }
    
    private func navigateToMapScreen() {
        print("Navigating to Map Screen")
        let mapViewController = MapViewController()
        mapViewController.modalPresentationStyle = .fullScreen
        self.present(mapViewController, animated: true, completion: nil)
    }
}
