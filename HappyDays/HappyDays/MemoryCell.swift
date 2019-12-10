import UIKit

class MemoryCell: UICollectionViewCell {
    @IBOutlet private weak var imageView: UIImageView!
    
    func configure(_ image: UIImage?) {
        imageView.image = image
    }
 }
