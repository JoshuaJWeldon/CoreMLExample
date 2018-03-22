//
//  ViewController.swift
//  ML
//
//  Created by Joshua Weldon on 8/25/17.
//  Copyright © 2017 Joshua Weldon. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var image: UIImage?
    let model = MobileNet()

    @IBOutlet weak var imageCaption: UILabel!
    
    func getCaption(image: CVPixelBuffer) throws -> String {
        
        let prediction = try self.model.prediction(image: image)
        
        return prediction.classLabel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        guard let device  = AVCaptureDevice.default(for: .video)
            else{return}
        guard let input   = try? AVCaptureDeviceInput.init(device: device)
            else{return}
        
        session.addInput(input)
        session.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOut = AVCaptureVideoDataOutput()
        dataOut.setSampleBufferDelegate(self, queue: DispatchQueue(label: "Video"))
        
        session.addOutput(dataOut)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            else {return}

        guard let model = try? VNCoreMLModel(for: MobileNet().model)
            else{ return}

        let request = VNCoreMLRequest(model: model) { (finReq, err) in
            //print(finReq.results)
            guard let results = finReq.results as? [VNClassificationObservation]
                else{return}
            guard let firstOb = results.first
                else{return}
            
            print(firstOb.identifier, firstOb.confidence)
            
            DispatchQueue.main.async {
                self.imageCaption.text = firstOb.identifier
            }
            DispatchQueue.main.resume()
    
        }

        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        
    }

}

