//
//  Keychain.swift
//  MarketingData
//
//  Created by echo on 11/24/24.
//

import Foundation
import Marketing

/// Keychain helper methods for AccessGroupCollector
/// Do NOT use this for passwords! Access control is NOT set.
public struct Keychain {
    
    /// Deletes an entry from keychain
    public static func deleteFromKeychain(service: String, key: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny
        ] as CFDictionary
        
        let status = SecItemDelete(query)
        if status != 0 {
            // ignoring this since it always occurs on first check for securityGroup
            Logger.shared.logVerbose(message: "deleteFromKeychain OSStatus: \(status). This often occurs on first check for securityGroup.")
        }
    }
    
    /// Saves a string to keychain, only when device is unlocked
    /// This call blocks threads, call it async.
    public static func saveStringToKeychain(string: String, service: String, key: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
            kSecValueData: string.data(using: .utf8) as Any,
            kSecAttrIsInvisible: kCFBooleanTrue!,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ] as CFDictionary
        
        let status = SecItemAdd(query, nil)
        if status != 0 {
            Logger.shared.logVerbose(message: "saveStringToKeychain OSStatus: \(status)")
        }
    }
    
    /// Reads a single string from keychain.
    public static func readStringFromKeychain(service: String, key: String) -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
            kSecReturnAttributes: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        
        var value: CFTypeRef?
        let status = SecItemCopyMatching(query, &value)
        if status == 0 {
            if let string = String(data: value as! Data, encoding: .utf8) {
                return string
            }
        } else {
            Logger.shared.logVerbose(message: "readAccessGroupFromKeychain OSStatus: \(status)")
        }

        Logger.shared.logWarning(message: "Failed to read string from keychain")
        return nil
    }
    
    /// Reads access group from keychain.
    public static func readAccessGroupFromKeychain(service: String) -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
            kSecReturnAttributes: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        
        var value: CFTypeRef?
        let status = SecItemCopyMatching(query, &value)
        if status != 0 {
            Logger.shared.logVerbose(message: "readAccessGroupFromKeychain OSStatus: \(status)")
        }

        // read data from Keychain
        guard let dict = value as? [String: Any],
              let accessGroup = dict[kSecAttrAccessGroup as String] as? String
        else {
            Logger.shared.logWarning(message: "Failed to read access group from keychain")
            return nil
        }
        
        return accessGroup
    }
}