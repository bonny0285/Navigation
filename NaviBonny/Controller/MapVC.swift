//
//  ViewController.swift
//  NaviBonny
//
//  Created by Massimiliano on 08/04/2019.
//  Copyright © 2019 Massimiliano Bonafede. All rights reserved.
//

import UIKit
import MapKit

class MapVC: UIViewController {
    
    //MARK: - Outlets
    
    @IBOutlet weak var searchBox: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - Properties
    
    var keyboardWillShow: NSNotification!
    var keyboardWillHide: NSNotification!
    var locationManagerViewModel: LocationManagerViewModel!
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManagerViewModel = LocationManagerViewModel(mapView)
        
        locationManagerViewModel.onMapViewUpdating = { [weak self] mapView in
            DispatchQueue.main.async {
                self?.mapView = mapView
            }
        }

        mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(mapTouched(_:))))
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        setupAllDelegateAndLocations()
    }
    
    @objc
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc
    func keyboardWillHide(notification: NSNotification) {
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
    }
    
    private func startSearching() {
        tableView.isHidden = false
    }
    
    private func endSearching() {
        tableView.isHidden = true
        searchBox.text = ""
        locationManagerViewModel.removeAllMatchingItem()
        tableView.reloadData()
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
        
        locationManagerViewModel.updateSearchResultsAtText(sender.text ?? "") { [weak self] needReloadTableView in
            if needReloadTableView == true {
                self?.tableView.reloadData()
            }
        }
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension MapVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locationManagerViewModel.matchingItems.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        locationManagerViewModel.createAnnotationAtIndex(indexPath)
        locationManagerViewModel.mapViewRemoveAnnotations(mapView.annotations)
        locationManagerViewModel.createAnnotationAtIndex(indexPath)
        endSearching()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SEARCH_CELL) as? SearchTableViewCell else {
            return UITableViewCell()
        }
        
        let selectedItem = locationManagerViewModel.getMatchingItemAtIndex(indexPath)
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = locationManagerViewModel.parseAddress(selectedItem: selectedItem)
        
        return cell
    }
}



