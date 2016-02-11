//
//  PlaygroundExporter.swift
//
//  Created by Jin Wang on 11/02/2016.
//  Copyright © 2016 Uthoft. All rights reserved.
//

import AppKit

var sharedPlugin: PlaygroundExporter?

class PlaygroundExporter: NSObject {

    var bundle: NSBundle
    lazy var center = NSNotificationCenter.defaultCenter()

    init(bundle: NSBundle) {
        self.bundle = bundle

        super.init()
        center.addObserver(self, selector: Selector("createMenuItems"), name: NSApplicationDidFinishLaunchingNotification, object: nil)
    }

    deinit {
        removeObserver()
    }

    func removeObserver() {
        center.removeObserver(self)
    }

    func createMenuItems() {
        removeObserver()
        
        // Find the File menu item on the Xcode menu bar.
        if let fileMenu = NSApp.mainMenu?.itemWithTitle("File") {
            let exportAsItem = NSMenuItem(title: "ExportAs", action: "didPressExportAs", keyEquivalent: "")
            let exportAsItemSubmenu = NSMenu()
            exportAsItem.target = self
            
            // Let's add a markdown submenu to the export as menu
            let markdownItem = NSMenuItem(title: "Markdown", action: "didPressExportAsMarkdown", keyEquivalent: "")
            markdownItem.target = self
            exportAsItemSubmenu.addItem(markdownItem)
            
            let htmlItem = NSMenuItem(title: "HTML", action: "didPressExportAsHTML", keyEquivalent: "")
            htmlItem.target = self
            exportAsItemSubmenu.addItem(htmlItem)
            
            exportAsItem.submenu = exportAsItemSubmenu
            
            fileMenu.submenu?.addItem(NSMenuItem.separatorItem())
            fileMenu.submenu?.addItem(exportAsItem)
        }
    }
    
    func didPressExportAs() {
        // Nothing here.
    }
    
    func didPressExportAsMarkdown() {
        MarkdownExporter.sharedInstance.exportCurrentSource()
    }
    
    func didPressExportAsHTML() {
        MarkdownExporter.sharedInstance.exportCurrentSource(true)
    }
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        return true
    }
}

