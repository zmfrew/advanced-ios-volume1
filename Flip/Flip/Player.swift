import GameplayKit
import UIKit

class Player: NSObject {
    static let allPlayers = [Player(stone: .black), Player(stone: .white)]

    var playerId: Int
    var stoneColor: StoneColor
    
    init(stone: StoneColor) {
        playerId = stone.rawValue
        stoneColor = stone
    }
    
    var opponent: Player {
        stoneColor == .black ? Player.allPlayers[1] : Player.allPlayers[0]
    }
}

extension Player: GKGameModelPlayer { }
