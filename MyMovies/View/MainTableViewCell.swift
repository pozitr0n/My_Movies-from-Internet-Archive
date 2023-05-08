//
//  MainTableViewCell.swift
//  MyMovies
//
//  Created by Raman Kozar on 07/05/2023.
//

import UIKit
import SDWebImage

class MainTableViewCell: UITableViewCell {
    
    @IBOutlet weak var mainImagePreview: UIImageView!
    @IBOutlet weak var mainMovieName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func loadInfoCell(_ urlToImage: URL, _ movieName: String) {
     
        self.mainImagePreview.sd_setImage(with: urlToImage,
                                      placeholderImage: UIImage(named: "empty"),
                                      options: [.continueInBackground, .progressiveLoad],
                                      completed: nil)
        
        self.mainMovieName.text = movieName
        
    }
    
}
