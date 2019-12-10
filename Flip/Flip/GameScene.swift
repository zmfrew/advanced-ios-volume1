import SpriteKit
import GameplayKit

class GameScene: SKScene {
    var board: Board!
    var rows = [[Stone]]()
    var strategist: GKMonteCarloStrategist!
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "background")
        background.blendMode = .replace
        background.zPosition = 1
        addChild(background)
        
        let gameBoard = SKSpriteNode(imageNamed: "board")
        gameBoard.name = "board"
        gameBoard.zPosition = 2
        addChild(gameBoard)
        
        board = Board()
        
        let offsetX = -280
        let offsetY = -281
        let stoneSize = 80
        
        for row in 0 ..< Board.size {
            var colArray = [Stone]()
            
            for col in 0 ..< Board.size {
                let stone = Stone(color: UIColor.clear, size: CGSize(width: stoneSize, height: stoneSize))
                
                stone.position = CGPoint(x: offsetX + (col * stoneSize), y: offsetY + (row * stoneSize))
                
                stone.row = row
                stone.col = col
                
                gameBoard.addChild(stone)
                colArray.append(stone)
            }
            
            board.rows.append([StoneColor](repeating: .empty, count: Board.size))
            rows.append(colArray)
        }
        
        rows[4][3].setPlayer(.white)
        rows[4][4].setPlayer(.black)
        rows[3][4].setPlayer(.white)
        rows[3][3].setPlayer(.black)
        
        board.rows[4][3] = .white
        board.rows[4][4] = .black
        board.rows[3][4] = .white
        board.rows[3][3] = .black
        
        strategist = GKMonteCarloStrategist()
        strategist.budget = 100
        strategist.explorationParameter = 1
        strategist.randomSource = GKRandomSource.sharedRandom()
        strategist.gameModel = board
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        guard let gameBoard = childNode(withName: "board") else { return }
        
        let location = touch.location(in: gameBoard)
        
        let nodesAtPoint = nodes(at: location)
        
        let tappedStones = nodesAtPoint.filter { $0 is Stone }
        
        guard tappedStones.count > 0 else { return }
        
        let tappedStone = tappedStones[0] as! Stone
        
        if board.canMoveIn(row: tappedStone.row, col: tappedStone.col) {
            makeMove(row: tappedStone.row, col: tappedStone.col)
            if board.currentPlayer.stoneColor == .white {
                makeAIMove()
            }
        } else {
            print("Move is illegal")
        }
    }
    
    func makeAIMove() {
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            let strategistTime = CFAbsoluteTimeGetCurrent()
            guard let move = self.strategist.bestMoveForActivePlayer() as? Move else { return }
            
            let delta = CFAbsoluteTimeGetCurrent()
            
            DispatchQueue.main.async { [unowned self] in
                self.rows[move.row][move.col].setPlayer(.choice)
                
                let aiTimeCeiling = 3.0
                let delay = min(aiTimeCeiling - delta, aiTimeCeiling)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [unowned self] in
                    self.makeMove(row: move.row, col: move.col)
                }
            }
        }
    }
    
    func makeMove(row: Int, col: Int) {
        let captured = board.makeMove(player: board.currentPlayer, row: row, col: col)
        
        for move in captured {
            let stone = rows[move.row][move.col]
            
            stone.setPlayer(board.currentPlayer.stoneColor)
            
            stone.xScale = 1.2
            stone.yScale = 1.2
            
            stone.run(SKAction.scale(to: 1, duration: 0.5))
        }
        
        board.currentPlayer = board.currentPlayer.opponent
    }
}
