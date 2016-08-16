//
//  Encryption.swift
//  Treem
//
//  Created by Matthew Walker on 10/9/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation

class Encryption {
    static let sharedInstance = Encryption()
    
    private func convertStringToBytes(key: String) -> [UInt8] {
        var decodedBytes = Array<UInt8>()
        
        for b in key.utf8 {
            decodedBytes.append(b)
        }
        
        return decodedBytes
    }
    
    private func hmacSHA256(key: String) -> String {
        let inputData   = key.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        let keyData     = key.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        let algorithm   = kCCHmacAlgSHA256
        let digestLen   = Int(CC_SHA256_DIGEST_LENGTH)
        let result      = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        
        CCHmac(CCHmacAlgorithm(algorithm), keyData.bytes, Int(keyData.length), inputData.bytes, Int(inputData.length), result)
        let data = NSData(bytes: result, length: digestLen)
        result.destroy()
        
        return data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
    }
    
    func getObfuscatedKey(keyBytes: [UInt8]) -> String {
        if let keyString = String(bytes: keyBytes, encoding: NSUTF8StringEncoding) {
            return keyString
        }
        
        return ""
    }
    
    func getObfuscatedKeyWithClassTypes(keyBytes: [UInt8], className: String, className2: String, className3: String) -> String {
        let className1  = hmacSHA256(className)
        let className2  = hmacSHA256(className2)
        let className3  = hmacSHA256(className3)
        let classBytes  = convertStringToBytes(className1 + className2 + className3)
        
        var returnBytes = [UInt8](count: keyBytes.count, repeatedValue: 0)
        
        var returnByte: UInt8
        
        for i in 0 ..< keyBytes.count {
            returnByte = keyBytes[i] ^ classBytes[i]
            
            // must be valid within "-" / "." / "_" / DIGIT / ALPHA
            let isValid = isValidOAuthCharacter(returnByte)

            // general ranges
            if (!isValid) {
                returnByte = (i % 2 == 0) || !isValidOAuthCharacter(classBytes[i]) ? keyBytes[i] : classBytes[i]
            }
            
            returnBytes[i] = returnByte
        }
        
        return getObfuscatedKey(returnBytes)
    }
    
    private func isValidOAuthCharacter(charByte: UInt8) -> Bool {
        return (charByte > 47 && charByte < 58) || (charByte > 64 && charByte < 91) || (charByte > 96 && charByte < 123) || (charByte == 45) || (charByte == 46) || (charByte == 95)
    }
}