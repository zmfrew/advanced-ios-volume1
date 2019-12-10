import Foundation

class Group: NSObject, NSCoding {
    var id: String
    var name: String
    var playSound: Bool
    var enabled: Bool
    var alarms: [Alarm]
    
    init(name: String, playSound: Bool, enabled: Bool, alarms: [Alarm]) {
        self.id = UUID().uuidString
        self.name = name
        self.playSound = playSound
        self.enabled = enabled
        self.alarms = alarms
    }
    
    required init?(coder: NSCoder) {
        self.id = coder.decodeObject(forKey: "id") as! String
        self.name = coder.decodeObject(forKey: "name") as! String
        self.playSound = coder.decodeBool(forKey: "playSound")
        self.enabled = coder.decodeBool(forKey: "enabled")
        self.alarms = coder.decodeObject(forKey: "alarms") as! [Alarm]
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(id, forKey: "id")
        coder.encode(name, forKey: "id")
        coder.encode(playSound, forKey: "playSound")
        coder.encode(enabled, forKey: "enabled")
        coder.encode(alarms, forKey: "alarms")
    }
}
