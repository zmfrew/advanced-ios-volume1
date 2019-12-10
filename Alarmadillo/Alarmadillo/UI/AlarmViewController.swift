import UIKit

class AlarmViewController: UITableViewController {
    @IBOutlet private weak var name: UITextField!
    @IBOutlet private weak var caption: UITextField!
    @IBOutlet private weak var datePicker: UIDatePicker!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var tapToSelectImage: UILabel!

    var alarm: Alarm!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = alarm.name
        name.text = alarm.name
        caption.text = alarm.caption
        datePicker.date = alarm.time
        
        if alarm.image.count > 0 {
            let imageFilename = Helper.getDocumentsDirectory().appendingPathComponent(alarm.image)
            imageView.image = UIImage(contentsOfFile: imageFilename.path)
            tapToSelectImage.isHidden = true
        }
    }
    @IBAction func datePickerChanged(_ sender: UIDatePicker) {
        alarm.time = datePicker.date
        save()
    }
    
    @IBAction func imageViewTapped(_ sender: UITapGestureRecognizer) {
        let vc = UIImagePickerController()
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        present(vc, animated: true)
    }
    
    @objc func save() {
        NotificationCenter.default.post(name: Notification.Name("save"), object: nil)
    }
}

extension AlarmViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        alarm.name = name.text!
        alarm.caption = caption.text!
        title = alarm.name
        save()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension AlarmViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        
        let fm = FileManager()
        if alarm.image.count > 0 {
            do {
                let currentImage = Helper.getDocumentsDirectory().appendingPathComponent(alarm.image)
                if fm.fileExists(atPath: currentImage.path) {
                    try fm.removeItem(at: currentImage)
                }
            } catch {
                print("Failed to remove current image")
            }
        }
        
        do {
            alarm.image = "\(UUID().uuidString).jpg"
            let newPath = Helper.getDocumentsDirectory().appendingPathComponent(alarm.image)
            let jpeg = image.jpegData(compressionQuality: 0.8)
            try jpeg?.write(to: newPath)
            save()
        } catch {
            print("Failed to save new image")
        }
        
        imageView.image = image
        tapToSelectImage.isHidden = true
    }
}

extension AlarmViewController: UINavigationControllerDelegate {

}
