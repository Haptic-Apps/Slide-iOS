//
//  SubmissionModel+Extensions.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/5/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import CoreData
import reddift
import UIKit

// CoreData representation of SubmissionObject
public extension SubmissionModel {
    // Takes a Link from reddift and turns it into a Realm model
    
    /*func submissionObjectToCD(submission: SubmissionObject) -> NSManagedObject {
        let managedContext = SlideCoreData.sharedInstance.backgroundContext
        let submissionEntity = NSEntityDescription.entity(forEntityName: "Submission", in: managedContext)!
        let submissionModel = NSManagedObject(entity: submissionEntity, insertInto: managedContext) as! SubmissionModel
        
        context.performAndWait {
            do {
                try context.save()
            } catch let error as NSError {
                print(error)
            }

        }

    }*/
}
