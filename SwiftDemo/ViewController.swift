//
//  ViewController.swift
//  SwiftDemo
//
//  Created by Ray Vo on 13/5/15.
//  Copyright (c) 2015 Truong Vo. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView?
    let cellIdentifier = "SubtitleCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! UITableViewCell
        cell.accessoryType = .DisclosureIndicator
        
        let shortPath = (indexPath.section, indexPath.row)
        switch shortPath {
            case (0, 0):
                cell.textLabel!.text = "Watch Streaming"
                cell.detailTextLabel!.text = "http://stream.ssh101.com/hls/truongvo.m3u8"
            case (0, 1):
                cell.textLabel!.text = "Start Streaminng"
                cell.detailTextLabel!.text = "rtmp://stream.ssh101.com/live"
            default:
                cell.textLabel!.text = ""
                cell.detailTextLabel!.text = ""
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        println("section \(indexPath.section) row \(indexPath.row)")
        
        let shortPath = (indexPath.section, indexPath.row)
        switch shortPath {
            case (0, 1):
                self.performSegueWithIdentifier("showPublisherPreview", sender: self)
            default:
                println("nothing")
        }
    }
    
    @IBAction func infoButtonPressed(sender: AnyObject) {
        let alert: UIAlertView = UIAlertView(title: "SwiftDemo", message: "This app is written in Swift language", delegate: nil, cancelButtonTitle: "OK")
        alert.show()
    }
}

