//
//  DatabaseManager.swift
//  SwipeClean
//
//  Created by Jan Haider on 01.02.25.
//

import Foundation
import Photos

class DatabaseManager {
    static let shared = DatabaseManager()
    private let userDefaultsKey = "KeptImages"
    private let deletedImagesKey = "DeletedImages"
    private let deletedCountKey = "DeletedCount"
    private let freedSpaceKey = "FreedSpace" // in Bytes

    let cooldown: TimeInterval = 7 * 24 * 60 * 60

    private var keptImages: [String: TimeInterval] = [:]
    private var deletedImages: Set<String> = []
    
    private(set) var deletedCount: Int = 0
    private(set) var freedSpace: Int64 = 0
    var keptImagesCount: Int {
        return keptImages.count
    }

    private init() {
        if let saved = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: TimeInterval] {
            keptImages = saved
        }
        if let savedDeleted = UserDefaults.standard.array(forKey: deletedImagesKey) as? [String] {
            deletedImages = Set(savedDeleted)
        }
        
        deletedCount = UserDefaults.standard.integer(forKey: deletedCountKey)
        if let freedNumber = UserDefaults.standard.object(forKey: freedSpaceKey) as? NSNumber {
            freedSpace = freedNumber.int64Value
        } else {
            freedSpace = 0
        }
    }
    
    func saveAsset(assetID: String, date: Date) {
        keptImages[assetID] = date.timeIntervalSince1970
        UserDefaults.standard.set(keptImages, forKey: userDefaultsKey)
    }
    
    func isAssetKeptRecently(assetID: String) -> Bool {
        if let timestamp = keptImages[assetID] {
            let savedDate = Date(timeIntervalSince1970: timestamp)
            return Date().timeIntervalSince(savedDate) < cooldown
        }
        return false
    }
    
    /// Neue Methode: Prüft, ob eine Asset-ID bereits als behalten markiert wurde.
    func isAssetKept(assetID: String) -> Bool {
        let isKept = keptImages[assetID] != nil
        return isKept
    }
    
    func deleteAsset(assetID: String, freedBytes: Int64) {
        deletedImages.insert(assetID)
        UserDefaults.standard.set(Array(deletedImages), forKey: deletedImagesKey)
        
        deletedCount += 1
        freedSpace += freedBytes
        UserDefaults.standard.set(deletedCount, forKey: deletedCountKey)
        UserDefaults.standard.set(NSNumber(value: freedSpace), forKey: freedSpaceKey)
    }
    
    func isAssetDeleted(assetID: String) -> Bool {
        return deletedImages.contains(assetID)
    }
    
    func resetDatabase() {
        keptImages.removeAll()
        deletedImages.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: deletedImagesKey)
        
        UserDefaults.standard.removeObject(forKey: deletedCountKey)
        UserDefaults.standard.removeObject(forKey: freedSpaceKey)
    }
    
    /// Setzt nur die "keptImages" zurück, die zu den Assets des angegebenen Albums gehören.
    /// Falls `album` nil ist, werden alle keptImages entfernt.
    func resetKeptImages(for album: PHAssetCollection?) {
        guard let album = album else {
            // Kein Album angegeben – alle keptImages zurücksetzen.
            keptImages.removeAll()
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            return
        }
        
        let fetchResult = PHAsset.fetchAssets(in: album, options: nil)
        var assetIDsInAlbum = Set<String>()
        fetchResult.enumerateObjects { (asset, _, _) in
            assetIDsInAlbum.insert(asset.localIdentifier)
        }
        
        for assetID in assetIDsInAlbum {
            keptImages.removeValue(forKey: assetID)
        }
        
        UserDefaults.standard.set(keptImages, forKey: userDefaultsKey)
    }
    
    func removeKeptAsset(assetID: String) {
        keptImages.removeValue(forKey: assetID)
        UserDefaults.standard.set(keptImages, forKey: userDefaultsKey)
    }
    
    // Getter- und Setter-Methoden für den iCloud-Sync
    func getKeptImages() -> [String: TimeInterval] {
        return keptImages
    }
    
    func setKeptImages(_ images: [String: TimeInterval]) {
        keptImages = images
        UserDefaults.standard.set(keptImages, forKey: userDefaultsKey)
    }
    
    func getDeletedImages() -> Set<String> {
        return deletedImages
    }
    
    func setDeletedImages(_ images: Set<String>) {
        deletedImages = images
        UserDefaults.standard.set(Array(deletedImages), forKey: deletedImagesKey)
    }
    
    func getDeletedCount() -> Int {
        return deletedCount
    }
    
    func setDeletedCount(_ count: Int) {
        deletedCount = count
        UserDefaults.standard.set(deletedCount, forKey: deletedCountKey)
    }
    
    func getFreedSpace() -> Int64 {
        return freedSpace
    }
    
    func setFreedSpace(_ space: Int64) {
        freedSpace = space
        UserDefaults.standard.set(NSNumber(value: freedSpace), forKey: freedSpaceKey)
    }
}
