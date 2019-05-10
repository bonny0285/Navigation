//
//  SearchTableViewCell.swift
//  NaviBonny
//
//  Created by Massimiliano on 08/04/2019.
//  Copyright © 2019 Massimiliano Bonafede. All rights reserved.
//

import UIKit

class SearchTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var placeLbl: UILabel!
    
    
    func updateCell(_ place: Place){
        self.placeLbl.text = place.place.name!
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
