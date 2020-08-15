//
//  AppDelegate.swift
//  SoundCloon
//
//  Created by Naman Kalkhuria on 7/21/20.
//  Copyright © 2020 Naman Kalkhuria. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    
    @IBOutlet weak var menu: NSMenu?
    @IBOutlet weak var firstMenuItem: NSMenuItem?
    
    @IBAction func launchApp(_ sender: Any) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateController(withIdentifier: .init(stringLiteral: "popupId")) as? ViewController else { return }
        
        
        let window = NSWindow(contentViewController: vc)
        window.makeKeyAndOrderFront(nil)
    }
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
   override func awakeFromNib() {
       statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
       statusItem?.button?.title = "Tiny Synth"
    
       if let menu = menu {
           statusItem?.menu = menu
       }
   }
}

