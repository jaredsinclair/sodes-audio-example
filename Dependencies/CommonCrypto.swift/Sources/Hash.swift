//
//  Hash.swift
//  CommonCryptoSwift
//
//  Created by Khoa Pham on 07/05/16.
//  Copyright © 2016 Fantageek. All rights reserved.
//

import Foundation
import CCommonCrypto

public struct Hash {

  // MARK: - NSData

  public static func MD2(data: NSData) -> NSData {
    return Hash.hash(data: data, crypto: .MD2)
  }

  public static func MD4(data: NSData) -> NSData {
    return Hash.hash(data: data, crypto: .MD4)
  }

  public static func MD5(data: NSData) -> NSData {
    return Hash.hash(data: data, crypto: .MD5)
  }

  public static func SHA1(data: NSData) -> NSData {
    return Hash.hash(data: data, crypto: .SHA1)
  }

  public static func SHA224(data: NSData) -> NSData {
    return Hash.hash(data: data, crypto: .SHA224)
  }

  public static func SHA256(data: NSData) -> NSData {
    return Hash.hash(data: data, crypto: .SHA256)
  }

  public static func SHA384(data: NSData) -> NSData {
    return Hash.hash(data: data, crypto: .SHA384)
  }

  public static func SHA512(data: NSData) -> NSData {
    return Hash.hash(data: data, crypto: .SHA512)
  }

  static func hash(data: NSData, crypto: Crypto) -> NSData {
    var buffer = Array<UInt8>(repeating: 0, count: Int(crypto.length))
    let _ = crypto.method(data.bytes, UInt32(data.length), &buffer)

    return NSData(bytes: buffer, length: buffer.count)
  }

  // MARK: - String

  public static func MD2(_ string: String) -> String? {
    return Hash.hash(string: string, crypto: .MD2)
  }

  public static func MD4(_ string: String) -> String? {
    return Hash.hash(string: string, crypto: .MD4)
  }

  public static func MD5(_ string: String) -> String? {
    return Hash.hash(string: string, crypto: .MD5)
  }

  public static func SHA1(_ string: String) -> String? {
    return Hash.hash(string: string, crypto: .SHA1)
  }

  public static func SHA224(_ string: String) -> String? {
    return Hash.hash(string: string, crypto: .SHA224)
  }

  public static func SHA256(_ string: String) -> String? {
    return Hash.hash(string: string, crypto: .SHA256)
  }

  public static func SHA384(_ string: String) -> String? {
    return Hash.hash(string: string, crypto: .SHA384)
  }

  public static func SHA512(_ string: String) -> String? {
    return Hash.hash(string: string, crypto: .SHA512)
  }

  static func hash(string: String, crypto: Crypto) -> String? {
    guard let data = string.data(using: String.Encoding.utf8) else { return nil }

    return Hash.hash(data: data as NSData, crypto: crypto).hexString
  }
}
