//
//  DataSource.swift
//  NaviBonny
//
//  Created by Massimiliano on 08/04/2019.
//  Copyright © 2019 Massimiliano Bonafede. All rights reserved.
//

import UIKit
import MapKit

class DataService{
    static let instance = DataService()
    
    var placeArray: [Place] = []
    
    func getPlace() -> [Place]{
        return placeArray
    }
}
