import Foundation

class Alarm: NSObject, NSCoding {
    var id: String
    var name: String
    var caption: String
    var time: Date
    var image: String
    
    init(name: String, caption: String, time: Date, image: String) {
        self.id = UUID().uuidString
        self.name = name
        self.caption = caption
        self.time = time
        self.image = image
    }
    
    required init?(coder: NSCoder) {
        self.id = coder.decodeObject(forKey: "id") as! String
        self.name = coder.decodeObject(forKey: "name") as! String
        self.caption = coder.decodeObject(forKey: "caption") as! String
        self.time = coder.decodeObject(forKey: "time") as! Date
        self.image = coder.decodeObject(forKey: "image") as! String
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(id, forKey: "id")
        coder.encode(name, forKey: "name")
        coder.encode(caption, forKey: "caption")
        coder.encode(time, forKey: "time")
        coder.encode(image, forKey: "image")
    }
}
