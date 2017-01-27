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
    static var upVotedFullnames : [String] = []
    static var downVotedFullnames : [String] = []
    
    static var unvotedFullnames : [String] = []
    static var savedFullnames : [String] = []
    static var unSavedFullnames : [String] = []
    
    static func getVoteDirection(s: Thing) -> VoteDirection {
        if(upVotedFullnames.contains(s.getId())){
            return .up
        } else if(downVotedFullnames.contains(s.getId())){
            return .down
        } else if(unvotedFullnames.contains(s.getId())){
            return .none
        } else {
            return ((s is Comment) ? (s as! Comment).likes : (s as! Link).likes)
        }
    }
    
    static func setVoteDirection(s: Thing, direction: VoteDirection){
        let fullname = s.getId()
        
        if let index = upVotedFullnames.index(of: fullname) {
            upVotedFullnames.remove(at: index)
        }
        
        if let index = downVotedFullnames.index(of: fullname) {
            downVotedFullnames.remove(at: index)
        }
        
        if let index = unvotedFullnames.index(of: fullname) {
            unvotedFullnames.remove(at: index)
        }
        
        switch(direction){
        case .up:
            upVotedFullnames.append(fullname)
            break
        case .down:
            downVotedFullnames.append(fullname)
            break
        default:
            unvotedFullnames.append(fullname)
            break
        }
    }
    
    static func isRead(s: Message) -> Bool {
        if(savedFullnames.contains(s.getId())){
            return true
        } else if(unSavedFullnames.contains(s.getId())){
            return false
        } else {
            return !s.new
        }
    }
    
    static func setRead(s: Message, read: Bool){
        let fullname = s.getId()
        if let index = savedFullnames.index(of: fullname){
            savedFullnames.remove(at: index)
        }
        
        if(read){
            savedFullnames.append(fullname)
        } else {
            unSavedFullnames.append(fullname)
        }
    }


    static func isSaved(s: Thing) -> Bool {
        if(savedFullnames.contains(s.getId())){
            return true
        } else if(unSavedFullnames.contains(s.getId())){
            return false
        } else {
            return ((s is Comment) ? (s as! Comment).saved : (s as! Link).saved)
        }
    }

    static func setSaved(s: Thing, saved: Bool){
        let fullname = s.getId()
        if let index = savedFullnames.index(of: fullname){
            savedFullnames.remove(at: index)
        }
        
        if(saved){
            savedFullnames.append(fullname)
        } else {
            unSavedFullnames.append(fullname)
        }
    }
    
    //Realm
    static func getVoteDirection(sb: Object) -> VoteDirection {
        var id = (sb is RSubmission) ? ((RSubmission)sb).getId() : ((RComment)sb).getId()
        if(upVotedFullnames.contains(id)){
            return .up
        } else if(downVotedFullnames.contains(s.getId())){
            return .down
        } else if(unvotedFullnames.contains(s.getId())){
            return .none
        } else {
            return ((s is Comment) ? (s as! Comment).likes : (s as! Link).likes)
        }
    }
    
    static func setVoteDirection(s: RSubmission, direction: VoteDirection){
        let fullname = s.getId()
        
        if let index = upVotedFullnames.index(of: fullname) {
            upVotedFullnames.remove(at: index)
        }
        
        if let index = downVotedFullnames.index(of: fullname) {
            downVotedFullnames.remove(at: index)
        }
        
        if let index = unvotedFullnames.index(of: fullname) {
            unvotedFullnames.remove(at: index)
        }
        
        switch(direction){
        case .up:
            upVotedFullnames.append(fullname)
            break
        case .down:
            downVotedFullnames.append(fullname)
            break
        default:
            unvotedFullnames.append(fullname)
            break
        }
    }
    
    static func isSaved(s: RSubmission) -> Bool {
        if(savedFullnames.contains(s.getId())){
            return true
        } else if(unSavedFullnames.contains(s.getId())){
            return false
        } else {
            return ((s is Comment) ? (s as! Comment).saved : (s as! Link).saved)
        }
    }
    
    static func setSaved(s: RSubmission, saved: Bool){
        let fullname = s.getId()
        if let index = savedFullnames.index(of: fullname){
            savedFullnames.remove(at: index)
        }
        
        if(saved){
            savedFullnames.append(fullname)
        } else {
            unSavedFullnames.append(fullname)
        }
    }

}
