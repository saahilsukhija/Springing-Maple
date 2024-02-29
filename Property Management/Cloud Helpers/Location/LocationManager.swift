//
//  LocationManager.swift
//  LocationManager
//
//  Created by Rajan Maheshwari on 22/10/16.
//  Copyright © 2016 Rajan Maheshwari. All rights reserved.
//

import UIKit
import MapKit
import CoreMotion

final class LocationManager: NSObject {
    
    enum LocationErrors: String {
        case denied = "Locations are turned off. Please turn it on in Settings"
        case restricted = "Locations are restricted"
        case notDetermined = "Locations are not determined yet"
        case notFetched = "Unable to fetch location"
        case invalidLocation = "Invalid Location"
        case reverseGeocodingFailed = "Reverse Geocoding Failed"
        case unknown = "Some Unknown Error occurred"
    }
    
    typealias LocationClosure = ((_ location:CLLocation?,_ error: NSError?)->Void)
    private var locationCompletionHandler: LocationClosure?
    typealias ReverseGeoLocationClosure = ((_ location:CLLocation?, _ placemark:CLPlacemark?,_ error: NSError?)->Void)
    private var geoLocationCompletionHandler: ReverseGeoLocationClosure?
    
    private var locationManager:CLLocationManager?
    private var activityManager: CMMotionActivityManager?
    
    private var locationAccuracy = kCLLocationAccuracyBest
    
    private var lastLocation:CLLocation?
    private var lastActivity: CMMotionActivity?
    
    private var reverseGeocoding = false
    
    private var isDriving = false
    private var startDriveLocation: CLLocation?
    private var startDriveTime: Date?
    
    private var lastDriveCreated: Drive?
    
    //Singleton Instance
    static let shared: LocationManager = {
        let instance = LocationManager()
        // setup code
        return instance
    }()
    
    //private override init() {}
    
    //MARK:- Destroy the LocationManager
    deinit {
        destroyLocationManager()
        destroyActivityManager()
    }
    
    //MARK:- Private Methods
    private func setupLocationManager() {
        if locationManager != nil {
            if #available(iOS 14.0, *) {
                self.check(status: locationManager?.authorizationStatus)
            } else {
                self.check(status: CLLocationManager.authorizationStatus())
                // Fallback on earlier versions
            }
            return
        }
        //Setting of location manager
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = locationAccuracy
        locationManager?.pausesLocationUpdatesAutomatically = false
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.activityType = .automotiveNavigation
        
        if #available(iOS 14.0, *) {
            self.check(status: locationManager?.authorizationStatus)
        } else {
            self.check(status: CLLocationManager.authorizationStatus())
        }
    }
    
    private func setupActivityManager() {
        //print("setting up!")
        activityManager = CMMotionActivityManager()
        activityManager?.startActivityUpdates(to: OperationQueue.main, withHandler: { motion in
            self.motionActivityDidUpdate(with: motion)
        })
    }
    
    private func destroyLocationManager() {
        locationManager?.delegate = nil
        locationManager = nil
        lastLocation = nil
    }
    
    private func destroyActivityManager() {
        activityManager = nil
    }
    
    @objc private func sendPlacemark() {
        guard let _ = lastLocation else {
            
            self.didCompleteGeocoding(location: nil, placemark: nil, error: NSError(
                domain: self.classForCoder.description(),
                code:Int(CLAuthorizationStatus.denied.rawValue),
                userInfo:
                    [NSLocalizedDescriptionKey:LocationErrors.notFetched.rawValue,
              NSLocalizedFailureReasonErrorKey:LocationErrors.notFetched.rawValue,
         NSLocalizedRecoverySuggestionErrorKey:LocationErrors.notFetched.rawValue]))
            
            lastLocation = nil
            return
        }
        
        self.reverseGeoCoding(location: lastLocation)
        lastLocation = nil
    }
    
    @objc private func sendLocation() {
        guard let _ = lastLocation else {
            self.didComplete(location: nil,error: NSError(
                domain: self.classForCoder.description(),
                code:Int(CLAuthorizationStatus.denied.rawValue),
                userInfo:
                    [NSLocalizedDescriptionKey:LocationErrors.notFetched.rawValue,
              NSLocalizedFailureReasonErrorKey:LocationErrors.notFetched.rawValue,
         NSLocalizedRecoverySuggestionErrorKey:LocationErrors.notFetched.rawValue]))
            lastLocation = nil
            return
        }
        self.didComplete(location: lastLocation,error: nil)
        lastLocation = nil
    }
    
    //MARK:- Public Methods
    
    /// Check if location is enabled on device or not
    ///
    /// - Parameter completionHandler: nil
    /// - Returns: Bool
    func isLocationEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    /// Get current location
    ///
    /// - Parameter completionHandler: will return CLLocation object which is the current location of the user and NSError in case of error
    func getLocation(completionHandler:@escaping LocationClosure) {
        
        //Resetting last location
        lastLocation = nil
        
        self.locationCompletionHandler = completionHandler
        
        setupLocationManager()
        setupActivityManager()
    }
    
    
    /// Get Reverse Geocoded Placemark address by passing CLLocation
    ///
    /// - Parameters:
    ///   - location: location Passed which is a CLLocation object
    ///   - completionHandler: will return CLLocation object and CLPlacemark of the CLLocation and NSError in case of error
    func getReverseGeoCodedLocation(location:CLLocation,completionHandler:@escaping ReverseGeoLocationClosure) {
        
        self.geoLocationCompletionHandler = nil
        self.geoLocationCompletionHandler = completionHandler
        if !reverseGeocoding {
            reverseGeocoding = true
            self.reverseGeoCoding(location: location)
        }
        
    }
    
    /// Get Latitude and Longitude of the address as CLLocation object
    ///
    /// - Parameters:
    ///   - address: address given by the user in String
    ///   - completionHandler: will return CLLocation object and CLPlacemark of the address entered and NSError in case of error
    func getReverseGeoCodedLocation(address:String,completionHandler:@escaping ReverseGeoLocationClosure) {
        
        self.geoLocationCompletionHandler = nil
        self.geoLocationCompletionHandler = completionHandler
        if !reverseGeocoding {
            reverseGeocoding = true
            self.reverseGeoCoding(address: address)
        }
    }
    
    /// Get current location with placemark
    ///
    /// - Parameter completionHandler: will return Location,Placemark and error
    func getCurrentReverseGeoCodedLocation(completionHandler:@escaping ReverseGeoLocationClosure) {
        
        if !reverseGeocoding {
            
            reverseGeocoding = true
            
            //Resetting last location
            lastLocation = nil
            
            self.geoLocationCompletionHandler = completionHandler
            
            setupLocationManager()
            setupActivityManager()
        }
    }
    
    //MARK:- Reverse GeoCoding
    private func reverseGeoCoding(location:CLLocation?) {
        CLGeocoder().reverseGeocodeLocation(location!, completionHandler: {(placemarks, error)->Void in
            
            if (error != nil) {
                //Reverse geocoding failed
                self.didCompleteGeocoding(location: nil, placemark: nil, error: NSError(
                    domain: self.classForCoder.description(),
                    code:Int(CLAuthorizationStatus.denied.rawValue),
                    userInfo:
                        [NSLocalizedDescriptionKey:LocationErrors.reverseGeocodingFailed.rawValue,
                  NSLocalizedFailureReasonErrorKey:LocationErrors.reverseGeocodingFailed.rawValue,
             NSLocalizedRecoverySuggestionErrorKey:LocationErrors.reverseGeocodingFailed.rawValue]))
                return
            }
            if placemarks!.count > 0 {
                let placemark = placemarks![0]
                if let _ = location {
                    self.didCompleteGeocoding(location: location, placemark: placemark, error: nil)
                } else {
                    self.didCompleteGeocoding(location: nil, placemark: nil, error: NSError(
                        domain: self.classForCoder.description(),
                        code:Int(CLAuthorizationStatus.denied.rawValue),
                        userInfo:
                            [NSLocalizedDescriptionKey:LocationErrors.invalidLocation.rawValue,
                      NSLocalizedFailureReasonErrorKey:LocationErrors.invalidLocation.rawValue,
                 NSLocalizedRecoverySuggestionErrorKey:LocationErrors.invalidLocation.rawValue]))
                }
                if(!CLGeocoder().isGeocoding){
                    CLGeocoder().cancelGeocode()
                }
            }else{
                print("Problem with the data received from geocoder")
            }
        })
    }
    
    private func reverseGeoCoding(address:String) {
        CLGeocoder().geocodeAddressString(address, completionHandler: {(placemarks, error)->Void in
            if (error != nil) {
                //Reverse geocoding failed
                self.didCompleteGeocoding(location: nil, placemark: nil, error: NSError(
                    domain: self.classForCoder.description(),
                    code:Int(CLAuthorizationStatus.denied.rawValue),
                    userInfo:
                        [NSLocalizedDescriptionKey:LocationErrors.reverseGeocodingFailed.rawValue,
                  NSLocalizedFailureReasonErrorKey:LocationErrors.reverseGeocodingFailed.rawValue,
             NSLocalizedRecoverySuggestionErrorKey:LocationErrors.reverseGeocodingFailed.rawValue]))
                return
            }
            if placemarks!.count > 0 {
                if let placemark = placemarks?[0] {
                    self.didCompleteGeocoding(location: placemark.location, placemark: placemark, error: nil)
                } else {
                    self.didCompleteGeocoding(location: nil, placemark: nil, error: NSError(
                        domain: self.classForCoder.description(),
                        code:Int(CLAuthorizationStatus.denied.rawValue),
                        userInfo:
                            [NSLocalizedDescriptionKey:LocationErrors.invalidLocation.rawValue,
                      NSLocalizedFailureReasonErrorKey:LocationErrors.invalidLocation.rawValue,
                 NSLocalizedRecoverySuggestionErrorKey:LocationErrors.invalidLocation.rawValue]))
                }
                if(!CLGeocoder().isGeocoding){
                    CLGeocoder().cancelGeocode()
                }
            }else{
                print("Problem with the data received from geocoder")
            }
        })
    }
    
    //MARK:- Final closure/callback
    private func didComplete(location: CLLocation?,error: NSError?) {
        // locationManager?.stopUpdatingLocation()
        locationCompletionHandler?(location,error)
        locationManager?.delegate = nil
        locationManager = nil
    }
    
    private func didCompleteGeocoding(location:CLLocation?,placemark: CLPlacemark?,error: NSError?) {
        //locationManager?.stopUpdatingLocation()
        geoLocationCompletionHandler?(location,placemark,error)
        locationManager?.delegate = nil
        locationManager = nil
        reverseGeocoding = false
    }
    
    private func check(status: CLAuthorizationStatus?) {
        guard let status = status else { return }
        switch status {
            
        case .authorizedWhenInUse,.authorizedAlways:
            // self.locationManager?.startUpdatingLocation()
            self.locationManager?.startMonitoringVisits()
            self.locationManager?.startMonitoringSignificantLocationChanges()
            print("started tracking location")
        case .denied:
            let deniedError = NSError(
                domain: self.classForCoder.description(),
                code:Int(CLAuthorizationStatus.denied.rawValue),
                userInfo:
                    [NSLocalizedDescriptionKey:LocationErrors.denied.rawValue,
              NSLocalizedFailureReasonErrorKey:LocationErrors.denied.rawValue,
         NSLocalizedRecoverySuggestionErrorKey:LocationErrors.denied.rawValue])
            
            if reverseGeocoding {
                didCompleteGeocoding(location: nil, placemark: nil, error: deniedError)
            } else {
                didComplete(location: nil,error: deniedError)
            }
            
        case .restricted:
            if reverseGeocoding {
                didComplete(location: nil,error: NSError(
                    domain: self.classForCoder.description(),
                    code:Int(CLAuthorizationStatus.restricted.rawValue),
                    userInfo: nil))
            } else {
                didComplete(location: nil,error: NSError(
                    domain: self.classForCoder.description(),
                    code:Int(CLAuthorizationStatus.restricted.rawValue),
                    userInfo: nil))
            }
            
        case .notDetermined:
            self.locationManager?.requestAlwaysAuthorization()
            
        @unknown default:
            didComplete(location: nil,error: NSError(
                domain: self.classForCoder.description(),
                code:Int(CLAuthorizationStatus.denied.rawValue),
                userInfo:
                    [NSLocalizedDescriptionKey:LocationErrors.unknown.rawValue,
              NSLocalizedFailureReasonErrorKey:LocationErrors.unknown.rawValue,
         NSLocalizedRecoverySuggestionErrorKey:LocationErrors.unknown.rawValue]))
        }
    }
    
    func hasCorrectLocationPrivileges() -> Bool {
        
        
        if locationManager?.authorizationStatus == .notDetermined || locationManager?.authorizationStatus == .authorizedAlways {
            return true
        }
        return false
    }
    
    func stopTracking() {
        print("stopped tracking location")
        locationManager?.stopUpdatingLocation()
        locationManager?.stopMonitoringVisits()
        activityManager?.stopActivityUpdates()
    }
    
    func startTracking() {
        print("started tracking")
        setupLocationManager()
        setupActivityManager()
    }
    
}

extension LocationManager: CLLocationManagerDelegate {
    
    //MARK:- CLLocationManager Delegates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //print("updated location: \(locations.last?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))")
        
        guard locations.last != nil else {
            print("error getting location");
            return
        }
        
        lastLocation = locations.last
        RecentLocationQueue.shared.putLocation(RecentLocation(location: lastLocation, date: Date()))
    }
    
    //    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
    //
    //        let drive = Visit(
    //            coordinates: lastLocation!.coordinate,
    //            arrivalDate: Date(),
    //            departureDate: Date())
    //        //print("\(fakeVisit.coordinate): \(fakeVisit.arrivalDate)")
    //        //print("enqueueing notification for visit \(fakeVisit)")
    //        //NotificationQueue.default.enqueue(Notification(name: .newVisitDetected, userInfo: ["visit" : fakeVisit]), postingStyle: .asap)
    //        NotificationCenter.default.post(name: .newVisitDetected, object: nil, userInfo: ["visit": visit])
    //
    //        Task {
    //            do {
    //                try await FirestoreDatabase.shared.uploadPrivateDrive(visit)
    //            } catch {
    //                print(error.localizedDescription)
    //            }
    //        }
    //    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.check(status: status)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
        self.didComplete(location: nil, error: error as NSError?)
    }
    
    func motionActivityDidUpdate(with activity: CMMotionActivity?) {
        guard let activity = activity else {
            print("no activity")
            return
        }
        
        //RecentLocationQueue.shared.getLocation(within: 5)
        if (activity.automotive == true || activity.cycling == true || activity.running == true) && isDriving == false {
            //new drive
            isDriving = true

            if let recentLoc = RecentLocationQueue.shared.getLocation(within: 5) {
                startDriveLocation = recentLoc.location
                startDriveTime = recentLoc.date
            }
            else {
                startDriveLocation = lastLocation
                startDriveTime = Date()
            }
            
            if startDriveLocation == nil {
                getLocation { location, error in
                    self.startDriveLocation = location
                }
            }
            
            
            NotificationCenter.default.post(name: .newDriveStarted, object: nil)
            
            if let lastDriveCreated = lastDriveCreated {
                let work = Work(initialCoordinates: lastDriveCreated.finalCoordinate, finalCoordinates: lastDriveCreated.finalCoordinate, initialDate: lastDriveCreated.finalDate, finalDate: startDriveTime ?? Date())
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.uploadWork(work)
                }

                print("new work detected!")
            }
            
            print("new drive started!")
        }
        else if (activity.automotive == false && activity.cycling == false && activity.running == false) && isDriving == true {
            //end drive
            isDriving = false
            
            guard let startLocation = startDriveLocation else {
                print("start location was null")
                return
            }
            guard let startTime = startDriveTime else {
                print("start time was null")
                return
            }
            guard let endLocation = locationManager?.location else {
                print("end location was null")
                return
            }
            let drive = Drive(initialCoordinates: startLocation.coordinate, finalCoordinates: endLocation.coordinate, initialDate: startTime, finalDate: Date())
            if abs(drive.finalDate.secondsSince(drive.initialDate)) < 120 {
                isDriving = true
                return
            }
            startDriveTime = nil
            startDriveLocation = nil

            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                NotificationCenter.default.post(name: .newDriveFinished, object: nil, userInfo: ["drive" : drive])
                self.lastDriveCreated = drive
                self.uploadDrive(drive)
            }
        }
        //print("motion did update: \(activity)")
    }
    
    private func uploadDrive(_ drive: Drive) {
        Task {
            do {
                try await FirestoreDatabase.shared.uploadPrivateDrive(drive)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func uploadWork(_ work: Work) {
        Task {
            do {
                try await FirestoreDatabase.shared.uploadPrivateWork(work)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
