//
//  VCPresenter.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/19/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation

public class VCPresenter{

public static func showVC(viewController: UIViewController, popupIfPossible: Bool, parentNavigationController: UINavigationController){
    
    }

    public static func presentAlert(_ alertController: UIViewController, parentVC: UIViewController){
    
        do {
            try parentVC.present(alertController, animated: true, completion: nil);
        } catch {
            print("Error presenting alert controller \(alertController)")
        }
     }
}
