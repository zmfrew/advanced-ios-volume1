import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func createNewEvent(_ sender: Any) {
        requestPresentationStyle(.expanded)
    }
    
    override func willBecomeActive(with conversation: MSConversation) {
        if presentationStyle == .expanded {
            displayEventViewController(conversation: conversation, identifier: "SelectDates")
        }
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        if presentationStyle == .expanded {
            displayEventViewController(conversation: activeConversation, identifier: "CreateEvent")
        }
    }
}

extension MessagesViewController {
    func createMessage(with dates: [Date], votes: [Int]) {
        requestPresentationStyle(.compact)
        guard let conversation = activeConversation else { return }
        
        var components = URLComponents()
        var items: [URLQueryItem] = []
        
        for (index, date) in dates.enumerated() {
            let dateItem = URLQueryItem(name: "date-\(index)", value: string(from: date))
            items.append(dateItem)
            
            let voteItem = URLQueryItem(name: "vote-\(index)", value: String(votes[index]))
            items.append(voteItem)
        }
        
        components.queryItems = items
        
        let session = conversation.selectedMessage?.session ?? MSSession()
        let message = MSMessage(session: session)
        message.url = components.url
        
        let layout = MSMessageTemplateLayout()
        layout.image = render(dates: dates)
        layout.caption = "I voted"
        message.layout = layout
        
        conversation.insert(message) { error in
            if let error = error {
                print("Error occurred inserting message into conversation: \(error)")
            }
        }
    }
    
    func displayEventViewController(conversation: MSConversation?, identifier: String) {
        guard let conversation = conversation,
            let vc = storyboard?.instantiateViewController(withIdentifier: identifier) as? EventViewController else { return }
        
        vc.load(from: conversation.selectedMessage)
        vc.delegate = self
        addChild(vc)
        
        vc.view.frame = view.bounds
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vc.view)
        
        vc.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        vc.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        vc.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        vc.didMove(toParent: self)
    }
    
    func render(dates: [Date]) -> UIImage {
        let inset: CGFloat = 20
        let attributes = [
            NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body),
            NSAttributedString.Key.foregroundColor: UIColor.darkGray
        ]
        
        let stringToRender = dates.map { DateFormatter.localizedString(from: $0, dateStyle: .long, timeStyle: .short) }.joined(separator: "\n")
        
        let attributedString = NSAttributedString(string: stringToRender, attributes: attributes)
        
        var imageSize = attributedString.size()
        imageSize.width += inset * 2
        imageSize.height += inset * 2
        
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = 3
        
        let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)
        let image = renderer.image { context in
            UIColor.white.set()
            context.fill(CGRect(origin: CGPoint.zero, size: imageSize))
            
            attributedString.draw(at: CGPoint(x: inset, y: inset))
        }
        
        return image
    }
    
    func string(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyy-MM-dd-HH-mm"
        return dateFormatter.string(from: date)
    }
}
