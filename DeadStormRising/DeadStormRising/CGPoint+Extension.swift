import UIKit

extension CGPoint {
    func manhattanDistance(to: CGPoint) -> CGFloat {
        abs(x - to.x) + abs(y - to.y)
    }
}
