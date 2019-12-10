import UIKit
import UserNotifications

class ViewController: UITableViewController {
    var groups = [Group]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let titleAttributes = [NSAttributedString.Key.font: UIFont(name: "Arial Rounded MT Bold", size: 20)!]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        title = "Alarmadillo"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addGroup))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Groups", style: .plain, target: nil, action: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(save), name: Notification.Name("save"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        load()
    }
    
    @objc func addGroup() {
        let newGroup = Group(name: "Name this group", playSound: true, enabled: false, alarms: [])
        groups.append(newGroup)
        
        performSegue(withIdentifier: "EditGroup", sender: newGroup)
    }
    
    @objc func save() {
        do {
            _ = Helper.getDocumentsDirectory().appendingPathComponent("groups")
            _ = try NSKeyedArchiver.archivedData(withRootObject: groups, requiringSecureCoding: false)
        } catch {
            print("Failed to save")
        }
        updateNotifications()
    }
    
    func createNotifications() {
        let center = UNUserNotificationCenter.current()
        
        center.removeAllPendingNotificationRequests()
        
        for group in groups {
            guard group.enabled == true else { continue }
            
            for alarm in group.alarms {
                let notification = createNotificationRequest(group: group, alarm: alarm)
                
                center.add(notification) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error)")
                    }
                }
            }
        }
    }
    
    func createNotificationAttachments(alarm: Alarm) -> [UNNotificationAttachment] {
        guard alarm.image.count > 0 else { return [] }
        
        let fm = FileManager.default
        
        do {
            let imageURL = Helper.getDocumentsDirectory().appendingPathComponent(alarm.image)
            let copyURL = Helper.getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).jpg")
            
            try fm.copyItem(at: imageURL, to: copyURL)
            
            let attachment = try UNNotificationAttachment(identifier: UUID().uuidString, url: copyURL)
            
            return [attachment]
        } catch {
            print("Failed to attach alarm image: \(error)")
            return []
        }
    }
    
    func createNotificationRequest(group: Group, alarm: Alarm) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        
        content.title = alarm.name
        content.body = alarm.caption
        
        content.categoryIdentifier = "alarm"
        content.userInfo = ["group": group.id, "alarm": alarm.id]
        
        if group.playSound {
            content.sound = UNNotificationSound.default
        }
        
        content.attachments = createNotificationAttachments(alarm: alarm)
        
        let cal = Calendar.current
        
        var dateComponents = DateComponents()
        dateComponents.hour = cal.component(.hour, from: alarm.time)
        dateComponents.minute = cal.component(.minute, from: alarm.time)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        return request
    }
    
    func destroy(group groupID: String) {
        navigationController?.popViewController(animated: false)
        
        for (index, group) in groups.enumerated() {
            if group.id == groupID {
                groups.remove(at: index)
                break
            }
        }
        
        save()
        load()
    }
    
    func display(group groupID: String) {
        navigationController?.popViewController(animated: false)
        
        for group in groups {
            if group.id == groupID {
                performSegue(withIdentifier: "EditGroup", sender: group)
                return
            }
        }
    }
    
    func load() {
        do {
            let path = Helper.getDocumentsDirectory().appendingPathComponent("groups")
            let data = try Data(contentsOf: path)
            groups = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [Group] ?? [Group]()
        } catch {
            print("Failed to load")
        }
    
        tableView.reloadData()
    }
    
    func rename(group groupID: String, newName: String) {
        navigationController?.popViewController(animated: false)
        
        for group in groups {
            if group.id == groupID {
                group.name = newName
                break
            }
        }
        
        save()
        load()
    }
    
    func updateNotifications() {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if granted {
                self.createNotifications()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let group: Group
        
        if sender is Group {
            group = sender as! Group
        } else {
            guard let indexPath = tableView.indexPathForSelectedRow else { return }
            group = groups[indexPath.row]
        }
        
        if let groupViewController = segue.destination as? GroupViewController {
            groupViewController.group = group
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groups.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Group", for: indexPath)
        
        let group = groups[indexPath.row]
        cell.textLabel?.text = group.name
        
        cell.textLabel?.textColor = group.enabled ? UIColor.black : UIColor.red
        
        cell.detailTextLabel?.text = group.alarms.count == 1 ? "1 alarm" : "\(group.alarms.count) alarms"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        groups.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}

extension ViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let groupID = userInfo["group"] as? String {
            switch response.actionIdentifier {
            case UNNotificationDefaultActionIdentifier:
                print("Default identifier")
                
            case UNNotificationDismissActionIdentifier:
                print("Dismiss identifier")
                
            case "show":
                display(group: groupID)
                break
                
            case "destroy":
                destroy(group: groupID)
                break
                
            case "rename":
                if let textResponse = response as? UNTextInputNotificationResponse {
                    rename(group: groupID, newName: textResponse.userText)
                }
                break
                
            default:
                break
            }
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert])
    }
}
