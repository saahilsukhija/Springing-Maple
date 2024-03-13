//
//  FirestoreDatabase.swift
//  Property Management
//
//  Created by Saahil Sukhija on 12/30/23.
//
import FirebaseCore
import FirebaseFirestore

class FirestoreDatabase {
    
    //Singleton Instance
    static let shared: FirestoreDatabase = {
        let instance = FirestoreDatabase()
        // setup code
        return instance
    }()
    
    private var db: Firestore!
    private var disableUpdates: Bool!
    
    init() {
        db = Firestore.firestore()
        disableUpdates = false
    }
    
    func uploadUserDetails() async throws {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User not logged in")
        }
        do {
            try await db.collection("users").document(user.getUserEmail()).setData(["email" : user.getUserEmail(), "name" : user.getUserName(), "team" : user.team?.id ?? "10000"])
        } catch {
            throw FirestoreError("An unknown error occured")
        }
    }
    
    func disableUpdatesTemporarily(/*for seconds: Int = 5*/) {
        disableUpdates = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.disableUpdates = false
        }
    }
    
    
    
    struct FirestoreError: LocalizedError {
        let description: String
        
        init(_ description: String) {
            self.description = description
        }
        
        var errorDescription: String? {
            description
        }
        
    }

}


//MARK: WORKS
extension FirestoreDatabase {
    
    func uploadPrivateWork(_ work: Work) async throws {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("User is not in a team")
        }
        
        do {
            if try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("works").getDocument().exists == false {
                try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("works").setData(["uncategorized": [JSONEncoder().encode(work)]])
            }
            else {
                try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("works").updateData(["uncategorized": FieldValue.arrayUnion([JSONEncoder().encode(work)])])
            }
            print("uploaded work: \(work)")
        } catch {
            throw FirestoreError("Error while uploading the work")
        }
        
    }
    
    func uploadRegisteredWork(_ registeredWork: RegisteredWork) async throws {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("User is not in a team")
        }
        
        do {
            disableUpdatesTemporarily()
            if try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("works").getDocument().exists == false {
                try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("works").setData(["registered": [JSONEncoder().encode(registeredWork)]])
                
                print("DNE")
            }
            else {
                try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("works").updateData(["registered": FieldValue.arrayUnion([JSONEncoder().encode(registeredWork)])])
                print("exists")
            }
            try await incrementDailyCounter()
            print("uploaded registered work: \(registeredWork)")
        } catch {
            throw FirestoreError("Error while uploading the registered work")
        }
    }
    
    func getPrivateWorks() async throws -> [Work] {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("User is not in a team")
        }
        
        do {
            let workdoc = try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("works").getDocument()
            if let data = workdoc.data()?["uncategorized"] as? [Data] {
                var arr: [Work] = []
                for w in data {
                    arr.append(try JSONDecoder().decode(Work.self, from: w))
                }
                return arr
            } else {
                throw FirestoreError("Error decoding")
            }
        } catch {
            throw FirestoreError("Error getting data")
        }
    }
    
    func registerWork(from works: [Work], work: Work, to registeredWork: RegisteredWork) async throws {
        do {
            try await uploadRegisteredWork(registeredWork)
            try await removePrivateWork(work, from: works)
        } catch {
            throw FirestoreError(error.localizedDescription)
        }
    }
    
    func removePrivateWork(_ work: Work, from ws: [Work]) async throws {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("User is not in a team")
        }
        
        var works = ws
        works.removeAll { w in
            return work == w
        }
        var stringified: [Data] = []
        for work in works {
            try? stringified.append(JSONEncoder().encode(work))
        }
        
        do {
            try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("works").setData(["uncategorized": stringified], merge: true)
            print("removed work: \(work)")
        } catch {
            throw FirestoreError("Error while removing the work")
        }
    }
    
    
    func addNotificationForPrivateWorks() throws {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("User is not in a team")
        }
        
        db.collection("teams").document(team.id).collection(user.getUserEmail()).document("works").addSnapshotListener { snapshot, error in
            
            if self.disableUpdates {
                print("disabled!")
                return
            }
            
            if let error = error {
                print(error.localizedDescription)
            }
            else {
                if let data = snapshot?.data()?["uncategorized"] as? [Data] {
                    var arr: [Work] = []
                    do {
                        for d in data {
                            arr.append(try JSONDecoder().decode(Work.self, from: d))
                        }
                        NotificationCenter.default.post(name: .cloudWorkDetected, object: nil, userInfo: ["works" : arr])
                    } catch {
                        print("error decoding")
                    }
                    
                } else {
                    //throw FirestoreError("Error decoding")
                }
            }
        }
    }
}


//MARK: DRIVES
extension FirestoreDatabase {
    
    func uploadPrivateDrive(_ drive: Drive) async throws {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("User is not in a team")
        }
        
        do {
            if try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("drives").getDocument().exists == false {
                try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("drives").setData(["uncategorized": [JSONEncoder().encode(drive)]])
            }
            else {
                try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("drives").updateData(["uncategorized": FieldValue.arrayUnion([JSONEncoder().encode(drive)])])
            }
            print("uploaded drive: \(drive)")
        } catch {
            throw FirestoreError("Error while uploading the drive")
        }
        
    }
    
    func uploadRegisteredDrive(_ registeredDrive: RegisteredDrive) async throws {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("User is not in a team")
        }
        
        do {
            disableUpdatesTemporarily()
            if try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("drives").getDocument().exists == false {
                try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("drives").setData(["registered": [JSONEncoder().encode(registeredDrive)]])
                print("DNE")
            }
            else {
                try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("drives").updateData(["registered": FieldValue.arrayUnion([JSONEncoder().encode(registeredDrive)])])
                print("exists")
            }
            try await incrementDailyCounter()
            print("uploaded registered drive: \(registeredDrive)")
        } catch {
            throw FirestoreError("Error while uploading the registered drive")
        }
    }
    
    func getPrivateDrives() async throws -> [Drive] {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("User is not in a team")
        }
        
        do {
            let drivedoc = try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("drives").getDocument()
            if let data = drivedoc.data()?["uncategorized"] as? [Data] {
                var arr: [Drive] = []
                for d in data {
                    arr.append(try JSONDecoder().decode(Drive.self, from: d))
                }
                return arr
            } else {
                throw FirestoreError("Error decoding")
            }
        } catch {
            throw FirestoreError("Error getting data")
        }
    }
    
    func registerDrive(from drives: [Drive], drive: Drive, to registeredDrive: RegisteredDrive) async throws {
        do {
            try await uploadRegisteredDrive(registeredDrive)
            try await removePrivateDrive(drive, from: drives)
        } catch {
            throw FirestoreError(error.localizedDescription)
        }
    }
    
    func removePrivateDrive(_ drive: Drive, from ds: [Drive]) async throws {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("User is not in a team")
        }
        
        var drives = ds
        drives.removeAll { d in
            return drive == d
        }
        var stringified: [Data] = []
        for drive in drives {
            try? stringified.append(JSONEncoder().encode(drive))
        }
        
        do {
            try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("drives").setData(["uncategorized": stringified], merge: true)
            print("removed drive: \(drive)")
        } catch {
            throw FirestoreError("Error while removing the drive")
        }
    }
    
    
    func addNotificationForPrivateDrives() throws {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("User is not in a team")
        }
        
        db.collection("teams").document(team.id).collection(user.getUserEmail()).document("drives").addSnapshotListener { snapshot, error in
            
            if self.disableUpdates {
                print("disabled!")
                return
            }
            
            if let error = error {
                print(error.localizedDescription)
            }
            else {
                if let data = snapshot?.data()?["uncategorized"] as? [Data] {
                    var arr: [Drive] = []
                    do {
                        for d in data {
                            arr.append(try JSONDecoder().decode(Drive.self, from: d))
                        }
                        NotificationCenter.default.post(name: .cloudDriveDetected, object: nil, userInfo: ["drives" : arr])
                    } catch {
                        print("error decoding")
                    }
                    
                } else {
                    //throw FirestoreError("Error decoding")
                }
            }
        }
    }
}

//MARK: DAILY
extension FirestoreDatabase {
    func incrementDailyCounter() async throws {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("User is not in a team")
        }
        
        do {
            let doc = db.collection("teams").document(team.id).collection(user.getUserEmail()).document("daily")
            if try await doc.getDocument().exists == false {
                try await doc.setData(["counter": 0])
            }
           
            try await doc.updateData([
              "counter": FieldValue.increment(Int64(1))
            ])
            print("increased counter")
        } catch {
            throw FirestoreError("Error while incrementing the counter")
        }
        
    }
    
    func getDailyCounter() async throws -> Int {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("User is not in a team")
        }
        
        do {
            let doc = db.collection("teams").document(team.id).collection(user.getUserEmail()).document("daily")
            if try await doc.getDocument().exists == false {
                return 0
            }
           
            return try await doc.getDocument().get("counter") as! Int
        } catch {
            throw FirestoreError("Error while getting the counter")
        }
    }
    
    func resetDailyCounter() async throws {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("User is not in a team")
        }
        
        do {
            let doc = db.collection("teams").document(team.id).collection(user.getUserEmail()).document("daily")
                try await doc.setData(["counter": 0])
            
            print("reset counter")
        } catch {
            throw FirestoreError("Error while resetting the counter")
        }
    }
}
