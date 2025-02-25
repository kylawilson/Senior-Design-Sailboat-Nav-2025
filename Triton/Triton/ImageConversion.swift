//
//  ImageConversion.swift
//  Triton
//
//  Created by Kyla Wilson on 2/4/25.
//

import Foundation
import SwiftUI

//https://stackoverflow.com/questions/51557553/decoding-base64-image-in-swift

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
            let dataDecoded = Data(base64Encoded: imageBase64String, options: .ignoreUnknownCharacters)
                decodedImage = UIImage(data: dataDecoded!) ?? UIImage()
        }
        return decodedImage
    }
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
