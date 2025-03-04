//
//  iCloudSyncManager.swift
//  SwipeClean
//
//  Created by Jan Haider on 15.02.25.
//


import Foundation

class iCloudSyncManager: ObservableObject {
    static let shared = iCloudSyncManager()
    
    @Published var syncStatus: String = "Idle"
    var syncInterval: TimeInterval = 12.0 // Konfigurierbarer Intervall in Sekunden
    private var syncTimer: Timer?
    
    private let kKeptImages = "keptImages"
    private let kDeletedImages = "deletedImages"
    private let kDeletedCount = "deletedCount"
    private let kFreedSpace = "freedSpace"
    private let kMediaMuted = "mediaMuted"
    private let kICloudSyncPurchased = "iCloudSyncPurchased"
    private let kICloudSyncEnabled = "iCloudSyncEnabled"
    
    private init() {}
    
    func startSync() {
        stopSync() // Bestehenden Timer stoppen
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            self?.syncData()
        }
        // Initialen Sync nach syncInterval Sekunden anstoßen
        DispatchQueue.main.asyncAfter(deadline: .now() + syncInterval) {
            self.syncData()
        }
    }
    
    func stopSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    func syncData() {
        // Prüfe, ob iCloud-Sync freigeschaltet und gekauft wurde
        let iCloudSyncPurchased = UserDefaults.standard.bool(forKey: kICloudSyncPurchased)
        let iCloudSyncEnabled = UserDefaults.standard.bool(forKey: kICloudSyncEnabled)
        guard iCloudSyncPurchased && iCloudSyncEnabled else {
            self.syncStatus = "iCloud Sync deaktiviert"
            return
        }
        
        self.syncStatus = "Synchronisiere..."
        
        let remoteStore = NSUbiquitousKeyValueStore.default
        remoteStore.synchronize() // Stelle sicher, dass Remote-Daten aktuell sind
        
        // MERGE: keptImages
        let localKept = DatabaseManager.shared.getKeptImages()
        let remoteKept = remoteStore.dictionary(forKey: kKeptImages) as? [String: TimeInterval] ?? [:]
        var mergedKept = remoteKept
        for (key, localValue) in localKept {
            if let remoteValue = remoteKept[key] {
                mergedKept[key] = max(localValue, remoteValue)
            } else {
                mergedKept[key] = localValue
            }
        }
        DatabaseManager.shared.setKeptImages(mergedKept)
        remoteStore.set(mergedKept, forKey: kKeptImages)
        
        // MERGE: deletedImages (Vereinigung)
        let localDeleted = DatabaseManager.shared.getDeletedImages()
        let remoteDeletedArray = remoteStore.array(forKey: kDeletedImages) as? [String] ?? []
        let remoteDeleted = Set(remoteDeletedArray)
        let mergedDeleted = localDeleted.union(remoteDeleted)
        DatabaseManager.shared.setDeletedImages(mergedDeleted)
        remoteStore.set(Array(mergedDeleted), forKey: kDeletedImages)
        
        // MERGE: deletedCount (Maximalwert)
        let localDeletedCount = DatabaseManager.shared.getDeletedCount()
        let remoteDeletedCount = remoteStore.longLong(forKey: kDeletedCount)
        let mergedDeletedCount = max(Int(localDeletedCount), Int(remoteDeletedCount))
        DatabaseManager.shared.setDeletedCount(mergedDeletedCount)
        remoteStore.set(mergedDeletedCount, forKey: kDeletedCount)
        
        // MERGE: freedSpace (Maximalwert)
        let localFreed = DatabaseManager.shared.getFreedSpace()
        let remoteFreed = remoteStore.longLong(forKey: kFreedSpace)
        let mergedFreed = max(localFreed, remoteFreed)
        DatabaseManager.shared.setFreedSpace(mergedFreed)
        remoteStore.set(mergedFreed, forKey: kFreedSpace)
        
        // MERGE: mediaMuted (OR-Verknüpfung)
        let localMediaMuted = UserDefaults.standard.bool(forKey: kMediaMuted)
        UserDefaults.standard.set(localMediaMuted, forKey: kMediaMuted)
        remoteStore.set(localMediaMuted, forKey: kMediaMuted)
        
        // MERGE: iCloudSyncPurchased (OR)
        let localPurchased = UserDefaults.standard.bool(forKey: kICloudSyncPurchased)
        let remotePurchased = remoteStore.bool(forKey: kICloudSyncPurchased)
        let mergedPurchased = localPurchased || remotePurchased
        UserDefaults.standard.set(mergedPurchased, forKey: kICloudSyncPurchased)
        remoteStore.set(mergedPurchased, forKey: kICloudSyncPurchased)
        
        // MERGE: iCloudSyncEnabled (OR)
        let localSyncEnabled = UserDefaults.standard.bool(forKey: kICloudSyncEnabled)
        let remoteSyncEnabled = remoteStore.bool(forKey: kICloudSyncEnabled)
        let mergedSyncEnabled = localSyncEnabled || remoteSyncEnabled
        UserDefaults.standard.set(mergedSyncEnabled, forKey: kICloudSyncEnabled)
        remoteStore.set(mergedSyncEnabled, forKey: kICloudSyncEnabled)
        
        remoteStore.synchronize()
        self.syncStatus = "Synchronisiert"
    }
}
