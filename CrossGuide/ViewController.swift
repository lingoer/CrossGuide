//
//  ViewController.swift
//  CrossGuide
//
//  Created by Ruoyu Fu on 7/6/2017.
//  Copyright © 2017 Ruoyu. All rights reserved.
//

import UIKit
import CoreVideo
import MetalKit
import AVFoundation
import MetalPerformanceShaders


class ViewController: UIViewController {

    @IBOutlet weak var mtkView: MTKView!

    let session = AVCaptureSession()
    let output = AVCaptureVideoDataOutput()
    var crossGuide: Layer?
    var videoTextureCache : CVMetalTextureCache?
    var commandQueue: MTLCommandQueue!
    var displayPipeline: MTLComputePipelineState!

    let semaphoreDraw = DispatchSemaphore(value: 0)
    let semaphoreCapture = DispatchSemaphore(value: 1)

    var inputTexture:MTLTexture? = nil

    @IBOutlet weak var label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        commandQueue = device.makeCommandQueue()
        guard let function = device.newDefaultLibrary()?.makeFunction(name: "display") else{
            return
        }


        displayPipeline = try! device.makeComputePipelineState(function: function)
        mtkView.device = device
        mtkView.delegate = self
        crossGuide = CrossGuideNet(device: device)
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &videoTextureCache)
        videoInit()

    }

    func videoInit() {
        let queue = DispatchQueue(label: "com.color.back")
        output.setSampleBufferDelegate(self, queue: queue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        guard let videoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else { return }
        try? session.addInput(AVCaptureDeviceInput(device: videoDevice))
        session.addOutput(output)
        output.connection(withMediaType: AVMediaTypeVideo).videoOrientation = .portrait
        session.sessionPreset = AVCaptureSessionPreset352x288
        session.startRunning()
    }
}


extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        semaphoreCapture.wait()
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        var yTextureRef : CVMetalTexture?
        let yWidth = CVPixelBufferGetWidth(pixelBuffer);
        let yHeight = CVPixelBufferGetHeight(pixelBuffer);

        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                  videoTextureCache!,
                                                  pixelBuffer,
                                                  nil,
                                                  .r8Unorm,
                                                  yWidth, yHeight, 0,
                                                  &yTextureRef)
        inputTexture = CVMetalTextureGetTexture(yTextureRef!)
        semaphoreDraw.signal()
    }
}

extension ViewController: MTKViewDelegate{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize){

    }
    func draw(in view: MTKView) {
        semaphoreDraw.wait()
        guard let drawable = view.currentDrawable,
            let inputTexture = self.inputTexture else {
                return
        }
        let commandBuffer = commandQueue.makeCommandBuffer()
//        TODO: hwo to get 3 channel images? the original number was 1.
        let src = MPSImage(texture: inputTexture, featureChannels: 3)
//        TODO: how to use prediction here?
        let (_, prediction) = crossGuide!(commandbuffer: commandBuffer, image: src)
        print(prediction)
//        let encoder = commandBuffer.makeComputeCommandEncoder()
//        encoder.setTexture(inputTexture, at: 0)
//        encoder.setTexture(uv.texture, at: 1)
//        encoder.setTexture(drawable.texture, at: 2)
//        encoder.dispatch(pipeline: displayPipeline, width: drawable.texture.width, height: drawable.texture.height, featureChannels: 3)
//        encoder.endEncoding()
//        releaseImage(uv)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        drawable.present()
        semaphoreCapture.signal()
        
    }
}



