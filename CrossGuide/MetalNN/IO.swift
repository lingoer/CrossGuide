//
//  IO.swift
//  MetalColor
//
//  Created by Ruoyu Fu on 20/5/2017.
//  Copyright © 2017 Ruoyu. All rights reserved.
//

import UIKit
import MetalPerformanceShaders



func Input(device: MTLDevice)->Layer{

    let scale = MPSImageLanczosScale(device: device)
    
    return { (commandbuffer, input) in
        let outputID = MPSImageDescriptor(channelFormat: .float16,
                                          width: 352,
                                          height: 288,
                                          featureChannels: 3)
        let output = MPSTemporaryImage(commandBuffer: commandbuffer, imageDescriptor: outputID)
        scale.encode(commandBuffer: commandbuffer, sourceTexture: input.texture, destinationTexture: output.texture)
        return (commandbuffer, output)
    }
}
