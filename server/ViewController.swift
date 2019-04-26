//
//  ViewController.swift
//  server
//
//  Created by panzhijun on 2019/4/22.
//  Copyright © 2019 panzhijun. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    
        let mana = ServerManager()
        mana.startRunning()
        
        // Do any additional setup after loading the view, typically from a nib.
    }


}

