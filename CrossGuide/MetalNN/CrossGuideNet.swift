//
//  CrossGuideNet.swift
//  CrossGuide
//
//  Created by Ruoyu Fu on 7/6/2017.
//  Copyright © 2017 Ruoyu. All rights reserved.
//

import Foundation
import MetalPerformanceShaders


func CrossGuideNet(device: MTLDevice) -> Layer {

    let tanh = MPSCNNNeuronTanH(device: device, a:1, b:1)

    //    TODO: apply normalization `(x / 255.0) - 0.5`
    let image = Input(device: device)
    let poolMax = PoolingMax(device: device)

    let conv1 = Conv2d(kernelWidth:1, kernelHeight:1, inputFeatures: 3, outputFeatures: 16,  activation: tanh, device: device, name: "conv2d_1")
    let conv2 = Conv2d(kernelWidth:5, kernelHeight:5, inputFeatures: 16, outputFeatures: 32,  activation: tanh, device: device, name: "conv2d_2")
    let conv3 = Conv2d(kernelWidth:5, kernelHeight:5, inputFeatures: 32,   outputFeatures: 32,  activation: tanh, device: device, name: "conv2d_3")
    let conv4 = Conv2d(kernelWidth:5, kernelHeight:5, inputFeatures: 32,   outputFeatures: 64,  activation: tanh, device: device, name: "conv2d_4")
    let conv5 = Conv2d(kernelWidth:3, kernelHeight:3, inputFeatures: 64,   outputFeatures: 64,  activation: tanh, device: device, name: "conv2d_5")
    let conv6 = Conv2d(kernelWidth:3, kernelHeight:3, inputFeatures: 64,   outputFeatures: 128,  activation: tanh, device: device, name: "conv2d_6")
    let dense1 = Dense(kernelWidth: 9, kernelHeight: 11, inputFeatures: 128, outputFeatures: 128, activation: tanh, device: device, name: "dense_1")
    let dense2 = Dense(kernelWidth: 1, kernelHeight: 1, inputFeatures: 128, outputFeatures: 64, activation: tanh, device: device, name: "dense_2")
    let dense3 = Dense(kernelWidth: 1, kernelHeight: 1, inputFeatures: 64, outputFeatures: 16, activation: tanh, device: device, name: "dense_3")
    let dense4 = Dense(kernelWidth: 1, kernelHeight: 1, inputFeatures: 16, outputFeatures: 3, activation: nil, device: device, name: "dense_4")

    return { raw in
        let input = raw
            |> image
            |> retain()
        let pool1 = input
            |> conv1
            |> conv2
            |> retain()
        let pool2 = pool1
            |> poolMax
            |> conv3
            |> retain()
        let pool3 = pool2
            |> poolMax
            |> conv4
            |> retain()
        let pool4 = pool3
            |> poolMax
            |> conv5
            |> retain()
        let pool5 = pool4
            |> poolMax
            |> conv6
            |> retain()
        let fc0 = pool5
            |> dense1
            |> retain()
        let fc1 = fc0
            |> dense2
            |> retain()
        let fc2 = fc1
            |> dense3
            |> retain()
        let fc3 = fc2
            |> dense4
        return fc3
    }
}
