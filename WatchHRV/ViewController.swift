//
//  ViewController.swift
//  WatchHRV
//
//  Created by Jacopo Mangiavacchi on 11/18/17.
//  Copyright © 2017 Jacopo Mangiavacchi. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {

    let healthStore = HKHealthStore()
    let hrvUnit = HKUnit(from: "ms")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard HKHealthStore.isHealthDataAvailable() == true else {
            print("not available")
            return
        }
        
        guard let hrQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            print("not allowed")
            return
        }
        
        guard let hrvQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN) else {
            print("not allowed")
            return
        }
        
        let dataTypes: Set<HKQuantityType> = [hrQuantityType, hrvQuantityType]
        
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) -> Void in
            if success {
                let day = Date(timeIntervalSinceNow: -7*24*60*60)
                if let query = self.createheartRateVariabilitySDNNStreamingQuery(day) {
                    self.healthStore.execute(query)
                }
            }
            else {
                print("not allowed")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func createheartRateVariabilitySDNNStreamingQuery(_ startDate: Date) -> HKQuery? {
        let typeHRV = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
        let predicate: NSPredicate? = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: HKQueryOptions.strictStartDate)

        let squery = HKSampleQuery(sampleType: typeHRV!, predicate: predicate, limit: 10, sortDescriptors: nil) { (query, samples, error) in
            DispatchQueue.main.async(execute: {() -> Void in
                guard error == nil, let hrvSamples = samples as? [HKQuantitySample] else {return}

                for sample in hrvSamples {
                    let value = sample.quantity.doubleValue(for: self.hrvUnit)
                    print("got: \(value) - \(sample.startDate)")
                }
            })
        }

        return squery
    }
}

