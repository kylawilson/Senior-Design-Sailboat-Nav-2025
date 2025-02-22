//
//  ImageConversion.swift
//  Triton
//
//  Created by Kyla Wilson on 2/4/25.
//

import Foundation
import SwiftUI

//https://stackoverflow.com/questions/51557553/decoding-base64-image-in-swift


let filePath = Bundle.main.path(forResource: "img_serialized", ofType: "txt")

func readData() -> UIImage? {
    var imageEncoded: UIImage? = nil
    do {
        // Get the saved data
        let savedData = try Data(contentsOf: URL(fileURLWithPath: filePath!))
        
        // Convert the data back into a string
        if let savedString = String(data: savedData, encoding: .utf8) {
            // Split the content by the delimiter
            let parts = savedString.components(separatedBy: "\n|||IMAGE_END|||\n")
            
            for (_, part) in parts.enumerated() {
                let trimmedPart = part.trimmingCharacters(in: .whitespacesAndNewlines) // Remove unnecessary spaces/newlines
                if !trimmedPart.isEmpty { // Ensure we don't save empty parts
                    imageEncoded = base64Convert(base64String: trimmedPart)
                    return imageEncoded
                }
            }
        }
    } catch {
        print("Unable to read the file: \(error)")
    }
    return imageEncoded
}

func readImage(finalPhotoData: String) -> UIImage? {
    var imageEncoded: UIImage? = nil
    if !finalPhotoData.isEmpty { // Ensure we don't save empty parts
        imageEncoded = base64Convert(base64String: finalPhotoData)
        return imageEncoded
    }
    return imageEncoded
}

func base64Convert(base64String: String?) -> UIImage {
    var decodedImage = UIImage()
    if ((base64String?.isEmpty)! || (base64String?.contains("null"))!) {
        return decodedImage
    }else {
        if  let imageBase64String = base64String {
            //let dataDecoded = Data(base64Encoded: imageBase64String, options: .ignoreUnknownCharacters) {
            let dataDecoded = imageBase64String.data(using: .utf8)
                decodedImage = UIImage(data: dataDecoded!) ?? UIImage()
        }
        return decodedImage
    }
}

func dataToImage(_ data: Data?) -> UIImage? {
    guard let data = data else { print("data return nil"); return nil }
    return UIImage(data: data)
}

struct ImageView: View {
    var image: UIImage
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: 300, height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 5)
    }
}
