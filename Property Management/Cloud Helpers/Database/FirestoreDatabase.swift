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
            if let team = user.team?.id, user.team?.id != "0" {
                try await db.collection("users").document(user.getUserEmail()).setData(["email" : user.getUserEmail(), "name" : user.getUserName(), "team" : team])
            } else {
                try await db.collection("users").document(user.getUserEmail()).setData(["email" : user.getUserEmail(), "name" : user.getUserName()])
            }
        } catch {
            throw FirestoreError("An unknown error occured")
        }
    }
    
    func deleteUser() async throws {
        
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User not logged in")
        }
        do {
            try await db.collection("users").document(user.getUserEmail()).delete()
            
            guard let team = user.team else {
                return
            }
            let collection = db.collection("teams").document(team.id).collection(user.getUserEmail())
            
            if try await collection.document("daily").getDocument().exists {
                try await collection.document("daily").delete()
            }
            if try await collection.document("drives").getDocument().exists {
                try await collection.document("drives").delete()
            }
            if try await collection.document("works").getDocument().exists {
                try await collection.document("works").delete()
            }
            
            
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
            try await incrementDailyCounter(.work)
            print("uploaded work: \(work)")
        } catch {
            throw FirestoreError("Error while uploading the work")
        }
        
        GoogleSheetAssistant.shared.appendUnregisteredWorkToSpreadsheet(work)
        
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
               // print("exists")
            }
            try await checkForDriveUpload(registeredWork)
            print("uploaded registered work: \(registeredWork)")
        } catch {
            throw FirestoreError("Error while uploading the registered work")
        }
    }
    
    func checkForDriveUpload(_ registeredWork: RegisteredWork) async throws {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let drive = PendingDriveQueue.shared.getDrive(finalTime: registeredWork.initialDate, finalPlace: registeredWork.initialPlace ?? "", remove: false) else {
            //print ("NO PENDING DRIVE ASSOCIATED WITH WORK")
            return
        }
        
        let registeredDrive = RegisteredDrive(from: drive, ticketNumber: registeredWork.ticketNumber ?? "", notes: registeredWork.notes ?? "")
        try await uploadRegisteredDrive(registeredDrive)
        
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
            throw FirestoreError("Error getting works")
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
                //print("disabled!")
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
    
    func getRegisteredWorks() async throws -> [Work] {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("User is not in a team")
        }
        
        do {
            let workdoc = try await db.collection("teams").document(team.id).collection("sukhija@gmail.com").document("works").getDocument()
            if let data = workdoc.data()?["registered"] as? [Data] {
                var arr: [Work] = []
                for w in data {
                    arr.append(try JSONDecoder().decode(Work.self, from: w))
                }
                return arr
            } else {
                throw FirestoreError("Error decoding")
            }
        } catch {
            throw FirestoreError("Error getting works")
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
            try await incrementDailyCounter(.drive)
            print("uploaded drive: \(drive)")
        } catch {
            throw FirestoreError("Error while uploading the drive")
        }
        
        GoogleSheetAssistant.shared.appendUnregisteredDriveToSpreadsheet(drive)
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
               // print("exists")
            }
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
            throw FirestoreError("Error getting drives")
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
                //print("disabled!")
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
    func incrementDailyCounter(_ type: CounterType) async throws {
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
                try await doc.setData(["counter": 0, "drive": 0, "work": 0])
            }
           
            if type == .drive {
                try await doc.updateData([
                  "drive": FieldValue.increment(Int64(1))
                ])
            }
            if type == .work {
                try await doc.updateData([
                  "work": FieldValue.increment(Int64(1))
                ])
            }
            try await doc.updateData([
              "counter": FieldValue.increment(Int64(1))
            ])
            print("increased counter")
        } catch {
            throw FirestoreError("Error while incrementing the counter")
        }
        
    }
    
    func getDailyCounter(_ type: CounterType) async throws -> Int {
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
           
            
            return try await doc.getDocument().get(type.rawValue) as? Int ?? 0
        } catch {
            throw FirestoreError("Error while getting the counter")
        }
    }
    
    func resetDailyCounters() async throws {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("User is not in a team")
        }
        
        do {
            let doc = db.collection("teams").document(team.id).collection(user.getUserEmail()).document("daily")
            try await doc.setData(["counter": 0, "drive": 0, "work": 0])
            
            print("reset counter")
        } catch {
            throw FirestoreError("Error while resetting the counter")
        }
    }
    
    enum CounterType: String {
        
        case drive = "drive"
        case work = "work"
        case general = "counter"
    }
}

//MARK: TEAM
extension FirestoreDatabase {
    
    
    func getUserTeam() async throws -> Team? {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User not logged in")
        }
        do {
            let team = try await db.collection("users").document(user.getUserEmail()).getDocument().get("team") as? String
            if let team = team {
                let t = try await getTeam(from: team)
                try? UserDefaults.standard.set(object: t, forKey: "user_team")
                return t
            } else {
                return nil
            }
        } catch {
            throw FirestoreError("An unknown error occured")
        }
    }
    
    func getTeam(from id: String) async throws -> Team {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User not logged in")
        }
        do {
            let doc = try await db.collection("teams").document(id).getDocument()
            guard let name = doc.get("name") as? String else {
                throw FirestoreError("No name for team")
            }
            guard let spreadsheetid = doc.get("spreadsheetID") as? String else {
                throw FirestoreError("No spreadsheetID for team")
            }
            let t = Team(id, name: name, spreadsheetID: spreadsheetid)
            try? UserDefaults.standard.set(object: t, forKey: "user_team")
            return t
        } catch {
            throw FirestoreError("An unknown error occured")
        }
    }
    
    
    func teamDoesExist(_ team: String) async throws -> Bool {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        do {
            let doc = try await db.collection("teams").document(team).getDocument()
            if doc.exists {
                return true
            } else {
                return false
            }
            
        } catch {
            print("hmm")
            return false
        }
        
    }
    
    func uploadTeamDetails(_ team: Team) async throws {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let name = team.name else {
            throw FirestoreError("No team name given")
        }
        let spreadsheetID = team.spreadsheetID ?? ""
        
        do {
            let doc = db.collection("teams").document(team.id)
            try await doc.setData(["name" : name, "spreadsheetID" : spreadsheetID])
        } catch {
            throw FirestoreError("Error uploading team details")
        }
        
    }
    
    func leaveCurrentTeam() async throws {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("No team given")
        }
        
        
        do {
            let doc = db.collection("users").document(user.getUserEmail())
            try await doc.updateData([
                "team": FieldValue.delete(),
            ])
            User.shared.team = nil
            UserDefaults.standard.removeObject(forKey: "user_team")
        } catch {
            throw FirestoreError("Error removing team details")
        }
    }
    
    func getEmails(in team: Team) async throws -> [String] {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        
        do {
            let doc = try await db.collection("teams").document(team.id).getDocument()
            //print(doc.data())
            return ["Unable to retrieve"]; #warning("Does not work.")
        } catch {
            throw FirestoreError("Error removing team details")
        }
    }
}

extension FirestoreDatabase {
    
    func getName(from email: String) async throws -> String {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        
        
        do {
            let doc = try await db.collection("users").document(email).getDocument()
            let name = doc.get("name")
            guard let name = name as? String else {
                throw FirestoreError("Unexpected error")
            }
            return name
        } catch {
            throw FirestoreError("Error removing team details")
        }
    }
}
