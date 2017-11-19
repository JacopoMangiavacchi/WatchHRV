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
        hrvLabel.setText("not available")
        heartRatelabel.setText("not available")
    }

    func displayNotAllowed() {
        hrvLabel.setText("not allowed")
        heartRatelabel.setText("not allowed")
    }


}
