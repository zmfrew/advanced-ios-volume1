import UIKit

class ViewController: UIViewController {
    var animator: UIViewPropertyAnimator!

    override func viewDidLoad() {
        super.viewDidLoad()
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slider)

        slider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80).isActive = true
        slider.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        let redBox = UIView(frame: CGRect(x: -64, y: 0, width: 128, height: 128))
        redBox.translatesAutoresizingMaskIntoConstraints = false
        redBox.backgroundColor = UIColor.red
        redBox.center.y = view.center.y
        view.addSubview(redBox)
        
        animator = UIViewPropertyAnimator(duration: 2, curve: .easeInOut) { [unowned self, redBox] in
            redBox.center.x = self.view.frame.width
            redBox.transform = CGAffineTransform(rotationAngle: CGFloat.pi).scaledBy(x: 0.001, y: 0.001)
        }
        
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        
        let play = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(playTapped))
        let flip = UIBarButtonItem(barButtonSystemItem: .rewind, target: self, action: #selector(reverseTapped))
        navigationItem.rightBarButtonItems = [play, flip]
        
        animator.addCompletion { [unowned self] position in
            if position == .end {
                self.view.backgroundColor = UIColor.green
            } else {
                self.view.backgroundColor = UIColor.black
            }
        }
    }
    
    @objc func playTapped() {
        // if the animation has started
        if animator.state == .active {
            // if it's current in motion
            if animator.isRunning {
                // pause it
                animator.pauseAnimation()
            } else {
                // continue at the same speed
                animator.continueAnimation(withTimingParameters: nil, durationFactor: 1)
            }
        } else {
            // not started yet; start it now
            animator.startAnimation()
        }
    }

    @objc func reverseTapped() {
        animator.isReversed = true
    }
    
    @objc func sliderChanged(_ sender: UISlider) {
        animator.fractionComplete = CGFloat(sender.value)
    }
}

