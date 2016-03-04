//
//  UITextView+Scroll.swift
//  OAuth2-Swift
//
//  Created by Sergii Nezdolii on 03/03/16.
//  Copyright © 2016 FrostDigital. All rights reserved.
//

import UIKit

extension UITextView {
    
    func scrollToBotom() {
        let range = NSMakeRange(text.characters.count - 1, 1);
        scrollRangeToVisible(range);
    }    
}