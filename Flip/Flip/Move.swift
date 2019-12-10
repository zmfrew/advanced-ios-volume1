import GameplayKit
import UIKit

class Move: NSObject {
    var col: Int
    var row: Int
    var value = 0
    
    init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
}

extension Move: GKGameModelUpdate {
    
}
