import UIKit

final class TestViewController: UIViewController {
    @IBOutlet weak var prompt: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    
    var words: [String]!
    var questionCounter = 0
    var showingQuestion = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .fastForward, target: self, action: #selector(nextTapped))
        words.shuffle()
        title = "TEST"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        askQuestion()
        stackView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        stackView.alpha = 0
    }
    
    @objc func nextTapped() {
        showingQuestion = !showingQuestion
        
        if showingQuestion {
            prepareForNextQuestion()
        } else {
            prompt.text = words[questionCounter].components(separatedBy: "::")[0]
            prompt.textColor = UIColor(red: 0, green: 0.7, blue: 0, alpha: 1)
        }
    }
    
    func askQuestion() {
        questionCounter += 1
        if questionCounter == words.count {
            questionCounter = 0
        }
        
        prompt.text = words[questionCounter].components(separatedBy: "::")[1]
        
        let animation = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.5) {
            self.stackView.alpha = 1
            self.stackView.transform = CGAffineTransform.identity
        }
        
        animation.startAnimation()
    } 
    
    func prepareForNextQuestion() {
        let animation = UIViewPropertyAnimator(duration: 0.5, curve: .easeInOut) { [unowned self] in
            self.stackView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.stackView.alpha = 0
        }
        
        animation.addCompletion { [unowned self] position in
            self.prompt.textColor = UIColor.black
            self.askQuestion()
        }

        animation.startAnimation()
    }
}
