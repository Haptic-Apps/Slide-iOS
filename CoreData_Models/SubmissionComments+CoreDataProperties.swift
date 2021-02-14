//
//  SubmissionComments+CoreDataProperties.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/7/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//
//

import CoreData
import Foundation

extension SubmissionComments {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SubmissionComments> {
        return NSFetchRequest<SubmissionComments>(entityName: "SubmissionComments")
    }

    @NSManaged public var submissionId: String?
    @NSManaged public var commentsString: String?
    @NSManaged public var saveDate: Date

}
