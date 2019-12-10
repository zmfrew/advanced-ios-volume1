import UIKit

final class ViewController: UITableViewController {
    var words = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewWord))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(startTest))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "End Test", style: .plain, target: nil, action: nil)
        
        let titleAttributes = [NSAttributedString.Key.font: UIFont(name: "AmericanTypewriter", size: 22)!]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        title = "POLYGLOT"
        
        guard let defaults = UserDefaults(suiteName: "group.com.zachfrew.polyglot") else { fatalError("App group doesn't exist!!")}
        
        if let savedWords = defaults.object(forKey: "Words") as? [String] {
            words = savedWords
        } else {
            saveInitialValues(to: defaults)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        words.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        
        let word = words[indexPath.row]
        let split = word.components(separatedBy: "::")
        
        cell.textLabel?.text = split[0]
        cell.detailTextLabel?.text = ""
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        words.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        saveWords()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let cell = tableView.cellForRow(at: indexPath) {
            if cell.detailTextLabel?.text == "" {
                let word = words[indexPath.row]
                let split = word.components(separatedBy: "::")
                cell.detailTextLabel?.text = split[1]
            } else {
                cell.detailTextLabel?.text = ""
            }
        }
    }
}

extension ViewController {
    @objc func addNewWord() {
        let alert = UIAlertController(title: "Add new word", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "English"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "French"
        }
        
        alert.addAction(UIAlertAction(title: "Add Word", style: .default, handler: { [unowned self, alert] (action: UIAlertAction!) in
            let firstWord = alert.textFields?[0].text ?? ""
            let secondWord = alert.textFields?[1].text ?? ""
            
            self.insertFlashcard(first: firstWord, second: secondWord)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    func insertFlashcard(first: String, second: String) {
        guard first.count > 0 && second.count > 0 else { return }
        
        let newIndexPath = IndexPath(row: words.count, section: 0)
        
        words.append("\(first)::\(second)")
        tableView.insertRows(at: [newIndexPath], with: .automatic)
        
        saveWords()
    }
    
    func saveInitialValues(to defaults: UserDefaults) {
        words.append("bear::l'ours")
        words.append("camel::le chameau")
        words.append("cow::la vache")
        words.append("fox::le renard")
        words.append("goat::la chèvre")
        words.append("monkey::le singe")
        words.append("pig::le cochon")
        words.append("rabbit::le lapin")
        words.append("sheep::le mouton")
        
        defaults.set(words, forKey: "Words")
    }
    
    func saveWords() {
        let defaults = UserDefaults(suiteName: "group.com.zachfrew.polyglot")
        defaults?.set(words, forKey: "Words")
    }
    
    @objc func startTest() {
        guard let vc = storyboard?.instantiateViewController(identifier: "Test") as? TestViewController else { return }
        
        vc.words = words
        navigationController?.pushViewController(vc, animated: true)
    }
}
