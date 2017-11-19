//
//  InterfaceController.swift
//  WatchHRV WatchKit Extension
//
//  Created by Jacopo Mangiavacchi on 11/18/17.
//  Copyright © 2017 Jacopo Mangiavacchi. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit


class InterfaceController: WKInterfaceController {

    var authorized = false
    let healthStore = HKHealthStore()
    var workoutActive = false
    var session : HKWorkoutSession?
    let hrvUnit = HKUnit(from: "ms")
    let heartRateUnit = HKUnit(from: "count/min")
    var hrvQuery : HKQuery?
    var heartRateQuery : HKQuery?

    @IBOutlet private weak var startStopButton : WKInterfaceButton!
    @IBOutlet private weak var hrvLabel: WKInterfaceLabel!
    @IBOutlet private weak var heartRatelabel: WKInterfaceLabel!

    override func awake(withContext context: Any?) {
        super.willActivate()
        
        self.setTitle("WatchHRV")
        
        guard HKHealthStore.isHealthDataAvailable() == true else {
            displayNotAvailable()
            return
        }
        
        guard let hrQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            displayNotAllowed()
            return
        }
        
        guard let hrvQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN) else {
            displayNotAllowed()
            return
        }
        
        let dataTypes: Set<HKQuantityType> = [hrQuantityType, hrvQuantityType]
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) -> Void in
            if success {
                self.authorized = true
            }
            else {
                self.displayNotAllowed()
            }
        }
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    func displayNotAvailable() {
        hrvLabel.setText("N/A")
        heartRatelabel.setText("N/A")
    }

    func displayNotAllowed() {
        hrvLabel.setText("n/a")
        heartRatelabel.setText("n/a")
    }
    
    @IBAction func startStopSession() {
        if (self.workoutActive) {
            self.workoutActive = false
            self.startStopButton.setTitle("Start")
            if let workout = self.session {
                healthStore.end(workout)
            }
        } else {
            self.workoutActive = true
            self.startStopButton.setTitle("Stop")
            startWorkout()
        }
    }
    
    func startWorkout() {
        guard session == nil else { return }
        
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .other
        
        do {
            session = try HKWorkoutSession(configuration: workoutConfiguration)
            session?.delegate = self
        } catch {
        }
        
        healthStore.start(self.session!)
    }
    
    func getQuery(date: Date, identifier: HKQuantityTypeIdentifier) -> HKQuery? {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }
        
        let datePredicate = HKQuery.predicateForSamples(withStart: date, end: nil, options: .strictEndDate )
        //let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate])
        
        let query = HKAnchoredObjectQuery(type: quantityType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, samples, deletedObjects, newAnchor, error) -> Void in
            self.processSamples(samples)
        }
        
        query.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.processSamples(samples)
        }
        return query
    }
    
    func processSamples(_ samples: [HKSample]?) {
        
    }
}


extension InterfaceController: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            workoutDidStart(date)
        case .ended:
            workoutDidEnd(date)
        default:
            break
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
    }
    
    
    func workoutDidStart(_ date : Date) {
        if let query = getQuery(date: date, identifier: HKQuantityTypeIdentifier.heartRate) {
            self.heartRateQuery = query
            healthStore.execute(query)
        } else {
            heartRatelabel.setText("/")
        }

        if let query = getQuery(date: date, identifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN) {
            self.hrvQuery = query
            healthStore.execute(query)
        } else {
            hrvLabel.setText("/")
        }
    }
    
    func workoutDidEnd(_ date : Date) {
        if let q = self.hrvQuery {
            healthStore.stop(q)
        }
        if let q = self.heartRateQuery {
            healthStore.stop(q)
        }

        session = nil
    }
}
