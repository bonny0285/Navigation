//
//  SearchStructure.swift
//  NaviBonny
//
//  Created by Massimiliano on 08/04/2019.
//  Copyright © 2019 Massimiliano Bonafede. All rights reserved.
//

import UIKit
import MapKit


struct Place {
    var place: MKPlacemark
    
    init(place: MKPlacemark) {
        self.place = place
    }
}
