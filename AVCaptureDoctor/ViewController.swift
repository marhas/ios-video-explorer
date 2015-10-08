//
//  ViewController.swift
//  AVCaptureDoctor
//
//  Created by Marcel Hasselaar on 03/10/15.
//  Copyright © 2015 AgiDev. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIPickerViewDelegate, FormatSelectionDelegate {

    @IBOutlet weak var formatButton: UIButton!
    @IBOutlet weak var videoPreviewView: UIView!
    @IBOutlet weak var focusSlider: UISlider!
    @IBOutlet weak var isoSlider: UISlider!
    @IBOutlet weak var currentFocusLabel: UILabel!
    @IBOutlet weak var currentIsoLabel: UILabel!
    @IBOutlet weak var torchModeSwitch: UISwitch!
    
    var session:AVCaptureSession!
    var videoDevice:AVCaptureDevice!
    var audioDevice:AVCaptureDevice!
    var selectedVideoFormat:AVCaptureDeviceFormat?
    var previewLayer:AVCaptureVideoPreviewLayer!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        torchModeSwitch?.on = false
        session = AVCaptureSession()
        self.initVideo()
        var videoFormatLabel = "No video device available"
        if (self.selectedVideoFormat != nil) {
             videoFormatLabel = (self.selectedVideoFormat?.friendlyShortDescription())!
        }
        formatButton.setTitle(videoFormatLabel, forState: .Normal)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "formatSelectionSegue" {
            let formatSelectionVC = segue.destinationViewController as! FormatSelectionVC
            formatSelectionVC.videoFormats = getVideoFormats()
            formatSelectionVC.mainViewController = self
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        formatButton.titleLabel?.text = self.selectedVideoFormat?.friendlyShortDescription()
        formatButton.titleLabel?.sizeToFit()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewDidLayoutSubviews() {
        previewLayer?.frame = self.videoPreviewView.bounds
    }
    
    @IBAction func flashSwitchToggled(sender: UISwitch) {
        if (sender.on) {
            enableFlash(true)
        } else {
            enableFlash(false)
        }
    }
    
    private func initVideo() {
        guard let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) else {
            print("No video capture device avaialbe on this hardware")
            return
        }
        self.videoDevice = videoDevice
        setVideoFormat(getVideoFormats()[0])
        
        setCameraFocus(0.5)
        setCameraIso(0.5)
        
        var videoInput:AVCaptureDeviceInput!
        do {
            videoInput = try AVCaptureDeviceInput(device: videoDevice)
        } catch {
            print("Couldn't create video input")
            return;
        }
        
        if (session.canAddInput(videoInput)) {
            session.addInput(videoInput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session);
        self.videoPreviewView.layer.addSublayer(previewLayer)
        
        session.startRunning()
    }

    private func enableFlash(enable: Bool) {
        defer {
            videoDevice.unlockForConfiguration()
        }
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.torchMode = enable ? .On : .Off
        } catch {
            print("Error enabling torch mode.");
        }
    }
    
    private func getVideoFormats() -> [AVCaptureDeviceFormat] {
        guard let videoDevice = videoDevice else {
            return []
        }
        return videoDevice.formats as! [AVCaptureDeviceFormat]
    }
    
    func setVideoFormat(format: AVCaptureDeviceFormat) {
        defer {
            enableFlash(torchModeSwitch.on)
            videoDevice.unlockForConfiguration()
        }
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.activeFormat = format;
            self.selectedVideoFormat = format;
            videoDevice.focusMode = .Locked

            print("Changed video mode to: \(videoDevice.activeFormat.friendlyShortDescription())")
        } catch {
            print("Error trying to set video capture format to \(format)");
        }
    }
    
    private func setCameraFocus(focus: Float) {
        defer {
            videoDevice.unlockForConfiguration()
        }
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.setFocusModeLockedWithLensPosition(focus, completionHandler: { [weak self] (time: CMTime) -> Void  in
                self?.currentFocusLabel.text = String(focus)
            })
        } catch {
            print("Error setting focus to \(focus)");
        }
    }

    private func setCameraIso(relativeIso: Float) {
        defer {
            videoDevice.unlockForConfiguration()
        }
        var calculatedIso : Float = 0;
        do {
            try videoDevice.lockForConfiguration()
            calculatedIso = self.videoDevice.activeFormat.minISO + (self.videoDevice.activeFormat.maxISO - self.videoDevice.activeFormat.minISO) * relativeIso;

            videoDevice.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, ISO: calculatedIso, completionHandler: { [weak self] (time: CMTime) -> Void in
                self?.currentIsoLabel.text = String(calculatedIso)
            })
        } catch {
            print("Error setting iso to \(calculatedIso)");
        }
    }

    
    //MARK: Focus UISliderView delegate
    
    @IBAction func focusSliderValueChanged(sender: UISlider) {
        self.setCameraFocus(sender.value)
    }

    //MARK: Iso UISliderView delegate
    
    @IBAction func isoSliderValueChanged(sender: UISlider) {
        self.setCameraIso(sender.value)
    }

    //MARK: FormatSelectionDelegate
    func didSelectFormat(format: AVCaptureDeviceFormat) {
        setVideoFormat(format)
    }
}

extension AVCaptureDeviceFormat {
    func friendlyDescription() -> String {
        let xDimension = CMVideoFormatDescriptionGetDimensions(self.formatDescription).width
        let yDimension = CMVideoFormatDescriptionGetDimensions(self.formatDescription).height
        let avFrameRateRanges = self.videoSupportedFrameRateRanges
        let minFrameRate = (avFrameRateRanges[0] as! AVFrameRateRange).minFrameRate
        let maxFrameRate = (avFrameRateRanges[0] as! AVFrameRateRange).maxFrameRate
        let avFrameRateRangeString = "\(Int(minFrameRate)) - \(Int(maxFrameRate))"
        let isoRange = "\(Int(self.minISO))-\(Int(self.maxISO))"
        
        var friendlyFormatString = "Dimensions: \(xDimension)x\(yDimension)\n"
        friendlyFormatString.appendContentsOf("Iso range: \(isoRange)\n")
        friendlyFormatString.appendContentsOf("Frame rate range: \(avFrameRateRangeString)\n")
        if (self.videoBinned) {
            friendlyFormatString.appendContentsOf("Binned\n")
        }
        if (self.videoHDRSupported) {
            friendlyFormatString.appendContentsOf("HDR supported\n")
        }
        if (self.autoFocusSystem == AVCaptureAutoFocusSystem.ContrastDetection) {
            friendlyFormatString.appendContentsOf("AF mode: contrast detection\n")
        } else if self.autoFocusSystem == AVCaptureAutoFocusSystem.PhaseDetection {
            friendlyFormatString.appendContentsOf("AF mode: phase detection\n")
        }
        if self.isVideoStabilizationModeSupported(AVCaptureVideoStabilizationMode.Cinematic) {
            friendlyFormatString.appendContentsOf("Video stabilization mode: Cinematic\n")
        } else if self.isVideoStabilizationModeSupported(AVCaptureVideoStabilizationMode.Standard) {
            friendlyFormatString.appendContentsOf("Video stabilization mode: Standard\n")
        }
        friendlyFormatString.appendContentsOf("Media type: \(self.mediaType)\n")
        friendlyFormatString.appendContentsOf("Max zoom factor: \(self.videoMaxZoomFactor)\n")
        friendlyFormatString.appendContentsOf("Field of view: \(self.videoFieldOfView)\n")

        if (avFrameRateRanges.count > 1) {
            print("Warning, format (\(friendlyFormatString)) contains multiple frame rate ranges")
        }
        return friendlyFormatString

    }
    func friendlyShortDescription() -> String {
        let xDimension = CMVideoFormatDescriptionGetDimensions(self.formatDescription).width
        let yDimension = CMVideoFormatDescriptionGetDimensions(self.formatDescription).height
        let avFrameRateRanges = self.videoSupportedFrameRateRanges
        let minFrameRate = (avFrameRateRanges[0] as! AVFrameRateRange).minFrameRate
        let maxFrameRate = (avFrameRateRanges[0] as! AVFrameRateRange).maxFrameRate
        let avFrameRateRangeString = "\(Int(minFrameRate)) - \(Int(maxFrameRate))"
        let isoRange = "\(Int(self.minISO))-\(Int(self.maxISO))"
        
        let friendlyFormatString = "\(xDimension)x\(yDimension) \(isoRange) \(avFrameRateRangeString)"
        return friendlyFormatString
    }
}