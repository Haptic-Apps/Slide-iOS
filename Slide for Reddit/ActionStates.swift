//
//  ActionStates.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/7/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift

class ActionStates {
    static var upVotedFullnames: [String] = []
    static var downVotedFullnames: [String] = []
    
    static var unvotedFullnames: [String] = []
    static var savedFullnames: [String] = []
    static var unSavedFullnames: [String] = []
    
    static func getVoteDirection(s: Thing) -> VoteDirection {
        if upVotedFullnames.contains(s.id) {
            return .up
        } else if downVotedFullnames.contains(s.id) {
            return .down
        } else if unvotedFullnames.contains(s.id) {
            return .none
        } else {
            return ((s is Comment) ? (s as! Comment).likes : (s as! Link).likes)
        }
    }
    
    static func setVoteDirection(s: Thing, direction: VoteDirection) {
        if #available(iOS 10.0, *) {
            HapticUtility.hapticActionComplete()
        }
        let fullname = s.id
        
        if let index = upVotedFullnames.firstIndex(of: fullname) {
            upVotedFullnames.remove(at: index)
        }
        
        if let index = downVotedFullnames.firstIndex(of: fullname) {
            downVotedFullnames.remove(at: index)
        }
        
        if let index = unvotedFullnames.firstIndex(of: fullname) {
            unvotedFullnames.remove(at: index)
        }
        
        switch direction {
        case .up:
            upVotedFullnames.append(fullname)
        case .down:
            downVotedFullnames.append(fullname)
        default:
            unvotedFullnames.append(fullname)
        }
    }
    
    static func isRead(s: MessageObject) -> Bool {
        if savedFullnames.contains(s.id) {
            return true
        } else if unSavedFullnames.contains(s.id) {
            return false
        } else {
            return !s.isNew
        }
    }
    
    static func setRead(s: MessageObject, read: Bool) {
        let fullname = s.id
        if let index = savedFullnames.firstIndex(of: fullname) {
            savedFullnames.remove(at: index)
        }
        
        if read {
            savedFullnames.append(fullname)
        } else {
            unSavedFullnames.append(fullname)
        }
    }

    static func isSaved(s: Thing) -> Bool {
        if savedFullnames.contains(s.id) {
            return true
        } else if unSavedFullnames.contains(s.id) {
            return false
        } else {
            return ((s is Comment) ? (s as! Comment).saved : (s as! Link).saved)
        }
    }

    static func setSaved(s: Thing, saved: Bool) {
        if #available(iOS 10.0, *) {
            HapticUtility.hapticActionStrong()
        }
        let fullname = s.id
        if let index = savedFullnames.firstIndex(of: fullname) {
            savedFullnames.remove(at: index)
        }
        
        if saved {
            savedFullnames.append(fullname)
        } else {
            unSavedFullnames.append(fullname)
        }
    }
    
    // Realm
    static func getVoteDirection(s: SubmissionObject) -> VoteDirection {
        if upVotedFullnames.contains(s.id) {
            return .up
        } else if downVotedFullnames.contains(s.id) {
            return .down
        } else if unvotedFullnames.contains(s.id) {
            return .none
        } else {
            return s.likes
        }
    }
    
    static func setVoteDirection(s: SubmissionObject, direction: VoteDirection) {
        if #available(iOS 10.0, *) {
            HapticUtility.hapticActionComplete()
        }
        let fullname = s.id
        
        if let index = upVotedFullnames.firstIndex(of: fullname) {
            upVotedFullnames.remove(at: index)
        }
        
        if let index = downVotedFullnames.firstIndex(of: fullname) {
            downVotedFullnames.remove(at: index)
        }
        
        if let index = unvotedFullnames.firstIndex(of: fullname) {
            unvotedFullnames.remove(at: index)
        }
        
        switch direction {
        case .up:
            upVotedFullnames.append(fullname)
        case .down:
            downVotedFullnames.append(fullname)
        default:
            unvotedFullnames.append(fullname)
        }
    }
    
    static func isSaved(s: SubmissionObject) -> Bool {
        if savedFullnames.contains(s.id) {
            return true
        } else if unSavedFullnames.contains(s.id) {
            return false
        } else if Collections.isSavedCollectionAny(link: s) {
            return true
        } else {
            return s.isSaved
        }
    }
    
    static func setSaved(s: SubmissionObject, saved: Bool) {
        if #available(iOS 10.0, *) {
            HapticUtility.hapticActionStrong()
        }
        let fullname = s.id
        if let index = savedFullnames.firstIndex(of: fullname) {
            savedFullnames.remove(at: index)
        }
        
        if saved {
            savedFullnames.append(fullname)
        } else {
            unSavedFullnames.append(fullname)
        }
    }
    
    // Realm comments
    static func getVoteDirection(s: CommentObject) -> VoteDirection {
        if upVotedFullnames.contains(s.id) {
            return .up
        } else if downVotedFullnames.contains(s.id) {
            return .down
        } else if unvotedFullnames.contains(s.id) {
            return .none
        } else {
            return (s.likes)
        }
    }
    
    static func setVoteDirection(s: CommentObject, direction: VoteDirection) {
        if #available(iOS 10.0, *) {
            HapticUtility.hapticActionComplete()
        }
        let fullname = s.id
        
        if let index = upVotedFullnames.firstIndex(of: fullname) {
            upVotedFullnames.remove(at: index)
        }
        
        if let index = downVotedFullnames.firstIndex(of: fullname) {
            downVotedFullnames.remove(at: index)
        }
        
        if let index = unvotedFullnames.firstIndex(of: fullname) {
            unvotedFullnames.remove(at: index)
        }
        
        switch direction {
        case .up:
            upVotedFullnames.append(fullname)
        case .down:
            downVotedFullnames.append(fullname)
        default:
            unvotedFullnames.append(fullname)
        }
    }
    
    static func isSaved(s: CommentObject) -> Bool {
        if savedFullnames.contains(s.id) {
            return true
        } else if unSavedFullnames.contains(s.id) {
            return false
        } else {
            return s.isSaved
        }
    }
    
    static func setSaved(s: CommentObject, saved: Bool) {
        if #available(iOS 10.0, *) {
            HapticUtility.hapticActionStrong()
        }
        let fullname = s.id
        if let index = savedFullnames.firstIndex(of: fullname) {
            savedFullnames.remove(at: index)
        }
        
        if saved {
            savedFullnames.append(fullname)
        } else {
            unSavedFullnames.append(fullname)
        }
    }

}
