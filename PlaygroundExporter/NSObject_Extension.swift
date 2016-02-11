//
//  NSObject_Extension.swift
//
//  Created by Jin Wang on 11/02/2016.
//  Copyright © 2016 Uthoft. All rights reserved.
//

import Foundation

extension NSObject {
    class func pluginDidLoad(bundle: NSBundle) {
        let appName = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as? NSString
        if appName == "Xcode" {
        	if sharedPlugin == nil {
        		sharedPlugin = PlaygroundExporter(bundle: bundle)
        	}
        }
    }
}