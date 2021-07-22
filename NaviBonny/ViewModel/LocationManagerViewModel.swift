//
//  LocationManagerViewModel.swift
//  NaviBonny
//
//  Created by Bonafede Massimiliano on 22/07/21.
//  Copyright © 2021 Massimiliano Bonafede. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class LocationManagerViewModel: NSObject {
    
    //MARK: - Properties

    private let locationManager = CLLocationManager()
    private let regionRadius: Double = 1000
    var newAddress: MKPlacemark? = nil
    var onMapViewUpdating: ((MKMapView) -> Void)?
    private(set) var matchingItems: [MKMapItem] = []
    
    //MARK: - Properties Injected

    var mapView: MKMapView
    
    //MARK: - Lifecycle

    init(_ mapView: MKMapView) {
        self.mapView = mapView
        super.init()
        self.mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        locationManager.startUpdatingLocation()
        
        self.mapView.isUserInteractionEnabled = true
        
        configureLocationServices()
    }
    
    //MARK: - Methods

    private func configureLocationServices() {
        if #available(iOS 14.0, *) {
            guard locationManager.authorizationStatus == .notDetermined else { return }
        } else {
            let authorizationStatus = CLLocationManager.authorizationStatus()
            guard authorizationStatus == .notDetermined else { return }
        }
        
        locationManager.requestAlwaysAuthorization()
    }
    
    private func centerMapOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        
        let coordinateRegion = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: regionRadius * 2.0,
            longitudinalMeters: regionRadius * 2.0
        )
        
        mapView.setRegion(coordinateRegion, animated: true)
        onMapViewUpdating?(mapView)
    }
    
    private func mapViewAddAnnotation(_ annotation: MKAnnotation) {
        mapView.addAnnotation(annotation)
    }
    
    func mapViewRemoveAnnotations(_ annotation: [MKAnnotation]) {
        mapView.removeAnnotations(annotation)
        onMapViewUpdating?(mapView)
    }
    
    func createAnnotationAtIndex(_ indexPath: IndexPath) {
        let address = matchingItems[indexPath.row].placemark
        let annotation = MKPointAnnotation()
        annotation.coordinate = address.coordinate
        annotation.title = address.name
        
        if let city = address.locality, let state = address.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        
        mapViewAddAnnotation(annotation)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: address.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        onMapViewUpdating?(mapView)
    }
    
    func getMatchingItemAtIndex(_ indexPath: IndexPath) -> MKPlacemark {
        matchingItems[indexPath.row].placemark
    }
    
    func removeAllMatchingItem() {
        matchingItems.removeAll()
    }
    
    func updateSearchResultsAtText(_ text: String, completion: @escaping (Bool) -> Void) {
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.region = mapView.region
        onMapViewUpdating?(mapView)
        let search = MKLocalSearch(request: request)
        
        search.start { response, error in
            
            if let error = error {
                print(error.localizedDescription)
                completion(false)
            } else if let response = response {
                self.matchingItems = response.mapItems
                completion(true)
            }
        }
    }
    
    func parseAddress(selectedItem: MKPlacemark) -> String {
        
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
}

//MARK: - CLLocationManagerDelegate

extension LocationManagerViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if locations.first != nil {
            print("location:: (location)")
        }
        
        centerMapOnUserLocation()
        onMapViewUpdating?(mapView)
    }
}

//MARK: - MKMapViewDelegate

extension LocationManagerViewModel: MKMapViewDelegate {
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
