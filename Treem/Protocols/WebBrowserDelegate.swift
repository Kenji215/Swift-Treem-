//
//  WebBrowserDelegate.swift
//  Treem
//
//  Created by Daniel Sorrell on 2/3/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

protocol WebBrowserDelegate {
    func shareWebLink(webBrowserController: WebBrowserViewController?, webLink: String)
}
