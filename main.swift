#!/usr/bin/swift
//
//  main.swift
//  usdz-preview
//
//  Created by Jonathan Mendoza on 05/10/2023.
//

import Foundation
import SceneKit.ModelIO
import ImageIO
import UniformTypeIdentifiers

print("Generating Thumbnail...")

let generator = ARQLThumbnailGenerator()
let path = FileManager.default.currentDirectoryPath
let url = URL(filePath: "/Users/ichbinjon/xcode/usdz-preview/usdz-preview/pancakes.usdz")
let img = generator.thumbnail(for: url, size: CGSize(width: 420, height: 420))

if img != nil, let imageData = img!.imagePNGRepresentation() {
    imageData.write(toFile: "/Users/ichbinjon/xcode/usdz-preview/usdz-preview/pancakes.png", atomically: false)
}

let images = generator.thumbnails(for: url, size:  CGSize(width: 420, height: 420))
//for (index, image) in images.enumerated(){
//    if let imageData = image.imagePNGRepresentation() {
//        imageData.write(toFile: "/Users/ichbinjon/xcode/usdz-preview/usdz-preview/pancakes\(index).png", atomically: false)
//    }
//}


func createGIF(with images: [NSImage], name: URL, loopCount: Int = 0, frameDelay: Double) {

    let destinationURL = name
    let destinationGIF = CGImageDestinationCreateWithURL(destinationURL as CFURL, UTType.gif.identifier as CFString, images.count, nil)!

    // This dictionary controls the delay between frames
    // If you don't specify this, CGImage will apply a default delay
//    let properties = [
//        (kCGImagePropertyGIFDictionary as String): [(kCGImagePropertyGIFDelayTime as String): frameDelay]
//    ]

    var rect = NSMakeRect(0, 0, 350, 250)

    for img in images {
        // Convert an UIImage to CGImage, fitting within the specified rect
//        let cgImage = img.cgImage
        let cgImage = img.cgImage(forProposedRect: &rect, context: nil, hints: nil)!

        // Add the frame to the GIF image
        CGImageDestinationAddImage(destinationGIF, cgImage , nil)
    }

    // Write the GIF file to disk
    CGImageDestinationFinalize(destinationGIF)
}
createGIF(with: images, name: URL(filePath: "/Users/ichbinjon/xcode/usdz-preview/usdz-preview/pancakes.gif"), loopCount: 2, frameDelay: 0)

extension NSImage {
    func imagePNGRepresentation() -> NSData? {
        if let imageTiffData = self.tiffRepresentation, let imageRep = NSBitmapImageRep(data: imageTiffData) {
            // let imageProps = [NSImageCompressionFactor: 0.9] // Tiff/Jpeg
            // let imageProps = [NSImageInterlaced: NSNumber(value: true)] // PNG
            let imageProps: [NSBitmapImageRep.PropertyKey : Any] = [:]
            let imageData = imageRep.representation(using: .png, properties: imageProps) as NSData?
            return imageData
        }
        return nil
    }
}

class ARQLThumbnailGenerator {
    private let device = MTLCreateSystemDefaultDevice()!

    /// Create a thumbnail image of the asset with the specified URL at the specified
    /// animation time. Supports loading of .scn, .usd, .usdz, .obj, and .abc files,
    /// and other formats supported by ModelIO.
    /// - Parameters:
    ///     - url: The file URL of the asset.
    ///     - size: The size (in points) at which to render the asset.
    ///     - time: The animation time to which the asset should be advanced before snapshotting.
    func thumbnail(for url: URL, size: CGSize, time: TimeInterval = 0) -> NSImage? {
        let renderer = SCNRenderer(device: device, options: [:])
        renderer.autoenablesDefaultLighting = true

        if (url.pathExtension == "scn") {
            let scene = try? SCNScene(url: url, options: nil)
            renderer.scene = scene
        } else {
            let asset = MDLAsset(url: url)
            asset.loadTextures()
            let scene = SCNScene(mdlAsset: asset)
            let (x, y, z, w) = angleConversion(x: 0, y:5, z: 0, w: 0)
            scene.rootNode.localRotate(by: SCNQuaternion(x, y, z, w))
            renderer.scene = scene
        }

        let image = renderer.snapshot(atTime: time, with: size, antialiasingMode: .multisampling4X)
        return image
    }

    func thumbnails(for url: URL, size: CGSize, time: TimeInterval = 0) -> [NSImage] {
        var images : [NSImage] = []
        let renderer = SCNRenderer(device: device, options: [:])
        renderer.autoenablesDefaultLighting = true

        if (url.pathExtension == "scn") {
            let scene = try? SCNScene(url: url, options: nil)
            renderer.scene = scene
        } else {
            let asset = MDLAsset(url: url)
            asset.loadTextures()
            let scene = SCNScene(mdlAsset: asset)
           
//                let (x, y, z, w) = angleConversion(x: 0, y: Float(0 + i/10), z: 0, w: 0)
//                scene.rootNode.localRotate(by: SCNQuaternion(x, y, z, w))
                renderer.scene = scene
            let action = SCNAction.rotateBy(x: 0, y: 1, z: 0 , duration: 200)
                scene.rootNode.runAction(action)
            for i in 1...200 {
                let image = renderer.snapshot(atTime: CFTimeInterval(i), with: size, antialiasingMode: .multisampling4X)
                images.append(image)
            }
           
        }

        return images
    }
}
func angleConversion(x: Float, y: Float, z: Float, w: Float) -> (Float, Float, Float, Float) {
    let c1 = cos( x / 2 )
    let c2 = cos( y / 2 )
    let c3 = cos( z / 2 )
    let s1 = sin( x / 2 )
    let s2 = sin( y / 2 )
    let s3 = sin( z / 2 )
    let xF = s1 * c2 * c3 + c1 * s2 * s3
    let yF = c1 * s2 * c3 - s1 * c2 * s3
    let zF = c1 * c2 * s3 + s1 * s2 * c3
    let wF = c1 * c2 * c3 - s1 * s2 * s3
    return (xF, yF, zF, wF)
}
