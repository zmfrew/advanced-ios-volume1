import UIKit

class GroupViewController: UITableViewController {
    let playSoundTag = 1001
    let enabledTag = 1002
    var group: Group!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAlarm))
        title = group.name
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        if sender.tag == playSoundTag {
            group.playSound = sender.isOn
        } else {
            group.enabled = sender.isOn
        }
        
        save()
    }
    
    @objc func addAlarm() {
        let alarm = Alarm(name: "Name this alarm", caption: "Add an optional description", time: Date(), image: "")
        group.alarms.append(alarm)
        
        performSegue(withIdentifier: "EditAlarm", sender: alarm)
        save()
    }
    
    @objc func save() {
        NotificationCenter.default.post(name: Notification.Name("save"), object: nil)
    }
    
    func createGroupCell(for indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "EditableText", for: indexPath)
            if let cellTextField = cell.viewWithTag(1) as? UITextField {
                cellTextField.text = group.name
            }
            
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Switch", for: indexPath)
            
            if let cellLabel = cell.viewWithTag(1) as? UILabel,
                let cellSwitch = cell.viewWithTag(2) as? UISwitch {
                cellLabel.text = "Play Sound"
                cellSwitch.isOn = group.playSound
                
                cellSwitch.tag = playSoundTag
            }
            
            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Switch", for: indexPath)
            
            if let cellLabel = cell.viewWithTag(1) as? UILabel,
                let cellSwitch = cell.viewWithTag(2) as? UISwitch {
                cellLabel.text = "Enabled"
                cellSwitch.isOn = group.enabled
                cellSwitch.tag = enabledTag
            }
            
            return cell
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let alarm: Alarm
        
        if sender is Alarm {
            alarm = sender as! Alarm
        } else {
            guard let indexPath = tableView.indexPathForSelectedRow else { return }
            alarm = group.alarms[indexPath.row]
        }
        
        if let alarmViewController = segue.destination as? AlarmViewController {
            alarmViewController.alarm = alarm
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return nil }
        
        if group.alarms.count > 0 { return "Alarms" }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 3 : group.alarms.count
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == 1
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        group.alarms.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        save()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return createGroupCell(for: indexPath, in: tableView)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RightDetail", for: indexPath)
            
            let alarm = group.alarms[indexPath.row]
            
            cell.textLabel?.text = alarm.name
            cell.detailTextLabel?.text = DateFormatter.localizedString(from: alarm.time, dateStyle: .none, timeStyle: .short)
            
            return cell
        }
    }
}

extension GroupViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        group.name = textField.text!
        title = group.name
        save()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
