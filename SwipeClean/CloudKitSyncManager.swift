//
//  CloudKitSyncManager.swift
//  SwipeClean
//
//  Created by Jan Haider on 15.02.25.
//

import Foundation
import CloudKit
import SwiftUI

class CloudKitSyncManager: ObservableObject {
    static let shared = CloudKitSyncManager()
    
    @Published var syncStatus: String = "Idle"
    var syncInterval: TimeInterval = 12.0 // Konfigurierbarer Intervall in Sekunden
    private var syncTimer: Timer?
    
    // CloudKit Record-Konfiguration
    private let recordType = "UserGallery"
    private let recordID = CKRecord.ID(recordName: "UserGalleryRecord")
    
    // Keys für die Felder im CloudKit Record
    private let keyKeptImages = "keptImages"       // JSON-codierter String ([String: TimeInterval])
    private let keyDeletedImages = "deletedImages"   // JSON-codierter String (Set<String>)
    private let keyDeletedCount = "deletedCount"     // Int
    private let keyFreedSpace = "freedSpace"           // Int64
    // Entfernt: private let keyMediaMuted = "mediaMuted"
    
    private let database = CKContainer.default().privateCloudDatabase
    
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
        let enabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        if !enabled {
            DispatchQueue.main.async {
                self.syncStatus = "CloudKit Sync deaktiviert"
            }
            return
        }
        
        DispatchQueue.main.async {
            self.syncStatus = "Synchronisiere..."
        }
        
        database.fetch(withRecordID: recordID) { (record, error) in
            if let ckError = error as? CKError, ckError.code == .unknownItem {
                let newRecord = CKRecord(recordType: self.recordType, recordID: self.recordID)
                self.mergeAndSave(record: newRecord)
            } else if let record = record {
                self.mergeAndSave(record: record)
            } else if let error = error {
                DispatchQueue.main.async {
                    self.syncStatus = "Fehler: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private let keyResetTimestamp = "resetTimestamp"

    func resetCloudDatabase(completion: @escaping (Result<Void, Error>) -> Void) {
        database.fetch(withRecordID: recordID) { record, error in
            let currentTime = Date().timeIntervalSince1970
            if let record = record {
                record[self.keyKeptImages] = "{}" as CKRecordValue
                record[self.keyDeletedImages] = "[]" as CKRecordValue
                record[self.keyDeletedCount] = 0 as CKRecordValue
                record[self.keyFreedSpace] = 0 as CKRecordValue
                // Entfernt: record[self.keyMediaMuted] = false as CKRecordValue
                record[self.keyResetTimestamp] = currentTime as CKRecordValue
                
                self.database.save(record) { savedRecord, saveError in
                    DispatchQueue.main.async {
                        if let saveError = saveError {
                            self.syncStatus = "Reset Fehler: \(saveError.localizedDescription)"
                            completion(.failure(saveError))
                        } else {
                            self.syncStatus = "Cloud-Datenbank zurückgesetzt"
                            completion(.success(()))
                        }
                    }
                }
            } else if let ckError = error as? CKError, ckError.code == .unknownItem {
                let newRecord = CKRecord(recordType: self.recordType, recordID: self.recordID)
                newRecord[self.keyKeptImages] = "{}" as CKRecordValue
                newRecord[self.keyDeletedImages] = "[]" as CKRecordValue
                newRecord[self.keyDeletedCount] = 0 as CKRecordValue
                newRecord[self.keyFreedSpace] = 0 as CKRecordValue
                // Entfernt: newRecord[self.keyMediaMuted] = false as CKRecordValue
                newRecord[self.keyResetTimestamp] = currentTime as CKRecordValue
                
                self.database.save(newRecord) { savedRecord, saveError in
                    DispatchQueue.main.async {
                        if let saveError = saveError {
                            self.syncStatus = "Reset Fehler: \(saveError.localizedDescription)"
                            completion(.failure(saveError))
                        } else {
                            self.syncStatus = "Cloud-Datenbank zurückgesetzt"
                            completion(.success(()))
                        }
                    }
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    self.syncStatus = "Reset Fehler: \(error.localizedDescription)"
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func mergeAndSave(record: CKRecord) {
        let localKept = DatabaseManager.shared.getKeptImages()
        let localDeleted = DatabaseManager.shared.getDeletedImages()
        let localDeletedCount = DatabaseManager.shared.getDeletedCount()
        let localFreed = DatabaseManager.shared.getFreedSpace()
        // Entfernt: let localMediaMuted = UserDefaults.standard.bool(forKey: "mediaMuted")
        
        var remoteKept: [String: TimeInterval] = [:]
        if let jsonString = record[self.keyKeptImages] as? String,
           let data = jsonString.data(using: .utf8) {
            remoteKept = (try? JSONDecoder().decode([String: TimeInterval].self, from: data)) ?? [:]
        }
        
        var remoteDeleted: Set<String> = []
        if let jsonString = record[self.keyDeletedImages] as? String,
           let data = jsonString.data(using: .utf8) {
            remoteDeleted = (try? JSONDecoder().decode(Set<String>.self, from: data)) ?? []
        }
        
        let remoteDeletedCount = record[self.keyDeletedCount] as? Int ?? 0
        let remoteFreedInt = record[self.keyFreedSpace] as? Int ?? 0
        let remoteFreed = Int64(remoteFreedInt)
        // Entfernt: let remoteMediaMuted = record[self.keyMediaMuted] as? Bool ?? false
        
        let remoteResetTimestamp = record[self.keyResetTimestamp] as? TimeInterval ?? 0.0
        
        let isRemoteReset = remoteKept.isEmpty && remoteDeleted.isEmpty && remoteDeletedCount == 0 && remoteFreed == 0 && remoteResetTimestamp > 0
        
        var mergedKept: [String: TimeInterval] = [:]
        var mergedDeleted: Set<String> = []
        var mergedDeletedCount = 0
        var mergedFreed: Int64 = 0
        // Entfernt: var mergedMediaMuted = false
        
        if isRemoteReset {
            mergedKept = localKept.filter { $0.value > remoteResetTimestamp }
            mergedDeleted = []
            mergedDeletedCount = 0
            mergedFreed = 0
            // Entfernt: mergedMediaMuted = remoteMediaMuted
            DatabaseManager.shared.resetDatabase()
        } else {
            mergedKept = remoteKept
            for (key, localValue) in localKept {
                if let remoteValue = remoteKept[key] {
                    mergedKept[key] = max(localValue, remoteValue)
                } else {
                    if localValue > remoteResetTimestamp {
                        mergedKept[key] = localValue
                    }
                }
            }
            mergedDeleted = localDeleted.union(remoteDeleted)
            mergedDeletedCount = max(localDeletedCount, remoteDeletedCount)
            mergedFreed = max(localFreed, remoteFreed)
            // Entfernt: mergedMediaMuted = localMediaMuted || remoteMediaMuted
        }
        
        DatabaseManager.shared.setKeptImages(mergedKept)
        DatabaseManager.shared.setDeletedImages(mergedDeleted)
        DatabaseManager.shared.setDeletedCount(mergedDeletedCount)
        DatabaseManager.shared.setFreedSpace(mergedFreed)
        // Entfernt: UserDefaults.standard.set(mergedMediaMuted, forKey: "mediaMuted")
        
        if let keptData = try? JSONEncoder().encode(mergedKept),
           let keptString = String(data: keptData, encoding: .utf8) {
            record[self.keyKeptImages] = keptString as CKRecordValue
        }
        if let deletedData = try? JSONEncoder().encode(mergedDeleted),
           let deletedString = String(data: deletedData, encoding: .utf8) {
            record[self.keyDeletedImages] = deletedString as CKRecordValue
        }
        record[self.keyDeletedCount] = mergedDeletedCount as CKRecordValue
        record[self.keyFreedSpace] = mergedFreed as CKRecordValue
        // Entfernt: record[self.keyMediaMuted] = mergedMediaMuted as CKRecordValue
        
        let modifyOp = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        modifyOp.savePolicy = .changedKeys
        modifyOp.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.syncStatus = "Fehler: \(error.localizedDescription)"
                } else {
                    self.syncStatus = "Synchronisiert"
                }
            }
        }
        self.database.add(modifyOp)
    }
}
