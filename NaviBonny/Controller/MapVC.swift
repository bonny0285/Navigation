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

protocol HandleMapSearch: AnyObject {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class MapVC: UIViewController {
    
    //MARK: - Outlets
    
    @IBOutlet weak var searchBox: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - Properties
    
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    var matchingItems: [MKMapItem] = []
    var selectedPin: MKPlacemark? = nil
    var newAddress: MKPlacemark? = nil
    
    var keyboardWillShow: NSNotification!
    var keyboardWillHide: NSNotification!
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.isUserInteractionEnabled = true
        mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(mapTouched(_:))))
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        setupAllDelegateAndLocations()
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    //MARK: - Methods
    
    private func setupAllDelegateAndLocations() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.isHidden = true
        mapView.delegate = self
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        configureLocationServices()
        centerMapOnUserLocation()
    }
    
    private func parseAddress(selectedItem: MKPlacemark) -> String {
        
        // put a space between "4" and "Melrose Place"
        let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
        
        // put a comma between street and city/state
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        
        // put a space between "Washington" and "DC"
        let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
        
        let addressLine = String (
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
    
    private func startSearching() {
        tableView.isHidden = false
    }
    
    private func endSearching() {
        tableView.isHidden = true
        searchBox.text = ""
        matchingItems.removeAll()
        tableView.reloadData()
    }
    
    private func getAddress(){
        print(#function)
    }
    
    private func updateSearchResults() {
        
        guard let mapView = mapView, let searchBarText = searchBox.text else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        
        search.start { response, error in
            
            if let error = error {
                print(error.localizedDescription)
                
            } else if let response = response {
                self.matchingItems = response.mapItems
                self.tableView.reloadData()
            }
        }
    }
    
    //MARK: - Actions
    
    @objc private func mapTouched(_ sednder: UITapGestureRecognizer) {
        view.endEditing(true)
        tableView.isHidden = true
    }
    
    @IBAction func upBox(_ sender: UITextField) {
        // dismissKeyboard()
        view.endEditing(true)
    }
    
    @IBAction func searchTextBoxEditChange(_ sender: UITextField) {
        startSearching()
        
        if sender.text == "" {
            endSearching()
            view.endEditing(true)
            //dismissKeyboard()
        }
        
        updateSearchResults()
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension MapVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let address = matchingItems[indexPath.row].placemark
        newAddress = address
        getAddress()
        
        ///dismiss(animated: true, completion: nil)
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = address.coordinate
        annotation.title = address.name
        
        if let city = address.locality, let state = address.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: address.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        //dismissKeyboard()
        
        endSearching()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SEARCH_CELL) as? SearchTableViewCell else {
            return UITableViewCell()
        }
        
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = parseAddress(selectedItem: selectedItem)
        
        return cell
    }
}

//MARK: - CLLocationManagerDelegate

extension MapVC : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
    
    // focus on user location
    func configureLocationServices() {
        guard authorizationStatus == .notDetermined else { return }
        
        locationManager.requestAlwaysAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if locations.first != nil {
            print("location:: (location)")
        }
    }
}

//MARK: - MKMapViewDelegate

extension MapVC: MKMapViewDelegate {
    
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        
        let coordinateRegion = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: regionRadius * 2.0,
            longitudinalMeters: regionRadius * 2.0
        )
        
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation { return nil }
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        button.setBackgroundImage(UIImage(named: "car"), for: .normal)
        button.addTarget(self, action: #selector(openMap), for: .touchUpInside)
        pinView?.leftCalloutAccessoryView = button
        
        return pinView
    }
    
    @objc func openMap() {
        
        let lati = (newAddress?.coordinate.latitude)!
        let long = (newAddress?.coordinate.longitude)!
        let regionDistance:CLLocationDistance = 10000
        
        let coordinates = CLLocationCoordinate2DMake(lati, long)
        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.openInMaps(launchOptions: options)
    }
}



