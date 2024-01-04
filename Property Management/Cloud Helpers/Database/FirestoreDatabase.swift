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
    
    init() {
        db = Firestore.firestore()
    }
    
    func uploadPrivateVisit(_ visit: Visit) async throws {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("User is not in a team")
        }
        
        do {
            try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("visits").updateData(["uncategorized": FieldValue.arrayUnion([JSONEncoder().encode(visit)])])
            print("uploaded visit: \(visit)")
        } catch {
            throw FirestoreError("Error while uploading the visit")
        }
        
    }
    
    func getPrivateVisits() async throws -> [Visit] {
        let user = User.shared
        guard user.isLoggedIn() else {
            throw FirestoreError("User is not logged in")
        }
        guard let team = user.team else {
            throw FirestoreError("User is not in a team")
        }
        
        do {
            let visitdoc = try await db.collection("teams").document(team.id).collection(user.getUserEmail()).document("visits").getDocument()
            if let data = visitdoc.data()?["uncategorized"] as? [Data] {
                var arr: [Visit] = []
                for d in data {
                    arr.append(try JSONDecoder().decode(Visit.self, from: d))
                }
                return arr
            } else {
                throw FirestoreError("Error decoding")
            }
        } catch {
            throw FirestoreError("Error getting data")
        }
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
