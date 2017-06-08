//
//  dense.swift
//  CrossGuide
//
//  Created by Tong Da on 07/06/2017.
//  Copyright © 2017 Ruoyu. All rights reserved.
//

import Foundation
import MetalPerformanceShaders


func Dense(kernelWidth: Int = 1, kernelHeight: Int = 1,
           inputFeatures: Int, outputFeatures: Int,
           activation: MPSCNNNeuron? = nil, device: MTLDevice, name: String) -> Layer {
    let convDesc = MPSCNNConvolutionDescriptor(kernelWidth: kernelWidth,
                                               kernelHeight: kernelHeight,
                                               inputFeatureChannels: inputFeatures,
                                               outputFeatureChannels: outputFeatures,
                                               neuronFilter: activation)
    let w = loadParam(name: name + "_kernel",
                      count: inputFeatures * kernelHeight * kernelWidth * outputFeatures)
    let b = loadParam(name: name + "_bias", count: outputFeatures)
    let dense = MPSCNNFullyConnected(device: device,
                                     convolutionDescriptor: convDesc,
                                     kernelWeights: w!,
                                     biasTerms: b,
                                     flags: .none)
    return { (commandbuffer, input) in
        let outputID = MPSImageDescriptor(channelFormat: .float16,
                                          width: input.width,
                                          height: input.height,
                                          featureChannels: outputFeatures)
        let output = MPSTemporaryImage(commandBuffer: commandbuffer, imageDescriptor: outputID)
        dense.encode(commandBuffer: commandbuffer, sourceImage: input, destinationImage: output)
        return (commandbuffer, output)
    }
}
           
