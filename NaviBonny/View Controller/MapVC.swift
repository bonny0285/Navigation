//
//  ViewController.swift
//  NaviBonny
//
//  Created by Massimiliano on 08/04/2019.
//  Copyright © 2019 Massimiliano Bonafede. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol HandleMapSearch: class {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class MapVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func dropPinZoomIn(placemark: MKPlacemark) {
        guard let coordinate = locationManager.location?.coordinate else {return}
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius * 1.0, longitudinalMeters: regionRadius * 1.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
   
    
    
    
    @IBOutlet weak var pullUpStuckView: NSLayoutConstraint!
    
    
    
    @IBOutlet weak var searchBox: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableViewSearch: UITableView!
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    var matchingItems:[MKMapItem] = []
    var selectedPin:MKPlacemark? = nil
    var newAddress : MKPlacemark? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableViewSearch.delegate = self
        tableViewSearch.dataSource = self
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        configureLocationServices()
        centerMapOnUserLocation()
        
        //locationSearchTable.handleMapSearchDelegate = self
    }

    
    func getDirections(){
        guard let selectedPin = selectedPin else { return }
        let mapItem = MKMapItem(placemark: selectedPin)
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
    }

    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func parseAddress(selectedItem:MKPlacemark) -> String {
        print(#function)
        // put a space between "4" and "Melrose Place"
        let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
        // put a comma between street and city/state
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        // put a space between "Washington" and "DC"
        let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
        let addressLine = String(
            format:"%@%@%@%@%@%@%@",
            // street number
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            // street name
            selectedItem.thoroughfare ?? "",
            comma,
            // city
            selectedItem.locality ?? "",
            secondSpace,
            // state
            selectedItem.administrativeArea ?? ""
        )
        return addressLine
    }
    
    
    @IBAction func upBox(_ sender: UITextField) {
        if pullUpStuckView.constant < 396 {
            pullUP()
            dismissKeyboard()
        }
    }
    
    
    
    @IBAction func searchTextBoxEditChange(_ sender: UITextField) {
        pullUP()
        
        if sender.text == "" {
            pullDown()
            dism()
            dismissKeyboard()
            
        }
        updateSearchResults()
        dism()
       
    }
    
    func dism (){
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return matchingItems.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: SEARCH_CELL) as? SearchTableViewCell
            let selectedItem = matchingItems[indexPath.row].placemark
            cell?.textLabel?.text = " "
            cell?.detailTextLabel?.text = " "
            return cell!
        }
    }
    
    func setStuckView(){
        if pullUpStuckView.constant == 60{
            pullUP()
        } else {
            pullDown()
        }
    }
    
    func pullUP(){
        pullUpStuckView.constant = 900
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func pullDown(){
        pullUpStuckView.constant = 60
        searchBox.text = ""
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SEARCH_CELL) as? SearchTableViewCell
        let selectedItem = matchingItems[indexPath.row].placemark
        cell?.textLabel?.text = selectedItem.name
        cell?.detailTextLabel?.text = parseAddress(selectedItem: selectedItem)
        print(parseAddress(selectedItem: selectedItem))
        return cell!
    }
 
    
    func updateSearchResults() {
        print(#function)
        guard let mapView = mapView,
            let searchBarText = searchBox.text else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                return
            }
            self.matchingItems = response.mapItems
            print(self.matchingItems)
            self.tableViewSearch.reloadData()
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let address = matchingItems[indexPath.row].placemark
        newAddress = address
        getAddress()
       // dropPinZoomIn(placemark: address)
        dismiss(animated: true, completion: nil)
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = address.coordinate
        annotation.title = address.name
        if let city = address.locality,
            let state = address.administrativeArea{
            annotation.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: address.coordinate, span: span)
        mapView.setRegion(region, animated: true)
       // dropPinZoomIn(placemark: address)
        dismissKeyboard()
        pullDown()
    }
    
    func getAddress(){
        print(#function)
    }
    
}



extension MapVC: MKMapViewDelegate{
    func centerMapOnUserLocation(){
        guard let coordinate = locationManager.location?.coordinate else {return}
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        
    }
    
    
    

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        print(#function, "!!!!")
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        button.setBackgroundImage(UIImage(named: "car"), for: .normal)
        button.addTarget(self, action: #selector(openMap), for: .touchUpInside)
        print(button.addTarget(self, action: #selector(openMap), for: .touchUpInside))
       
        pinView?.leftCalloutAccessoryView = button
        return pinView
    }
    
  
     @objc func openMap(){
        print(#function, "openMap")
       
        let lati = (newAddress?.coordinate.latitude)!
        let long = (newAddress?.coordinate.longitude)!
        let regionDistance:CLLocationDistance = 10000
        print("REGIONDISTANCE",regionDistance)
        
       // let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let coordinates = CLLocationCoordinate2DMake(lati, long)
        //guard let coordinates = selectedPin?.coordinate else {return}
        print("COORDINATES",coordinates)
        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        print("REGIONSPAN",regionSpan)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
           MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        print("OPTIONS",options)
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.openInMaps(launchOptions: options)
    }
    
 
}



extension MapVC : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
    
    // focus on user location
    func configureLocationServices(){
        if authorizationStatus == .notDetermined{
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if locations.first != nil {
            print("location:: (location)")
        }
    }
}




