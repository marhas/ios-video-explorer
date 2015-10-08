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

    var delegate : FormatSelectionDelegate?
    
    @IBAction func selectionDoneButtonPressed(sender: UIButton) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            
        }
    }
    @IBOutlet weak var formatDescriptionLabel: UILabel!
    @IBOutlet weak var videoFormatPicker: UIPickerView!
    var videoFormats: [AVCaptureDeviceFormat]!
    var selectedFormat : AVCaptureDeviceFormat?
    var mainViewController: ViewController?
    
    override func viewWillAppear(animated: Bool) {
        updateFormatLabel(videoFormats[0]);
    }
    
    //MARK: UIPickerViewDataSource
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return videoFormats.count
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //MARK: UIPickerViewDelegate
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return videoFormats[row].friendlyShortDescription()
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        delegate?.didSelectFormat(videoFormats[row])
        updateFormatLabel(videoFormats[row])
    }
    
    private func updateFormatLabel(format: AVCaptureDeviceFormat) {
        formatDescriptionLabel.text = format.friendlyDescription()
    }
}

protocol FormatSelectionDelegate {
    func didSelectFormat(_: AVCaptureDeviceFormat);
}
