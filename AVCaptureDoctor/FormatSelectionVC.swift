//
//  FormatSelectionVC.swift
//  AVCaptureDoctor
//
//  Created by Marcel Hasselaar on 05/10/15.
//  Copyright © 2015 AgiDev. All rights reserved.
//

import UIKit
import AVFoundation

class FormatSelectionVC: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate  {

    @IBAction func selectionDoneButtonPressed(sender: UIButton) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            
        }
    }
    @IBOutlet weak var videoFormatPicker: UIPickerView!
    var videoFormats: [AVCaptureDeviceFormat]!
    var selectedFormat : AVCaptureDeviceFormat?
    var mainViewController: ViewController?
    
    //MARK: UIPickerViewDataSource
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return videoFormats.count
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //MARK: UIPickerViewDelegate
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return videoFormats[row].friendlyString()
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedFormat = videoFormats[row]
        mainViewController?.setVideoFormat(videoFormats[row])
    }

}
