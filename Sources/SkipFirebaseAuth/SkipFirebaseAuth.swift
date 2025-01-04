// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP
import SkipFoundation
import SkipFirebaseCore
import kotlinx.coroutines.tasks.await
import android.net.Uri

// https://firebase.google.com/docs/reference/swift/firebaseauth/api/reference/Classes/Auth
// https://firebase.google.com/docs/reference/android/com/google/firebase/auth/FirebaseAuth

public final class Auth {
    public let platformValue: com.google.firebase.auth.FirebaseAuth

    public init(platformValue: com.google.firebase.auth.FirebaseAuth) {
        self.platformValue = platformValue
    }

    public static func auth() -> Auth {
        Auth(platformValue: com.google.firebase.auth.FirebaseAuth.getInstance())
    }

    public static func auth(app: FirebaseApp) -> Auth {
        Auth(platformValue: com.google.firebase.auth.FirebaseAuth.getInstance(app.app))
    }

    public var app: FirebaseApp {
        FirebaseApp(app: platformValue.getApp())
    }

    public var currentUser: User? {
        guard let user = platformValue.currentUser else { return nil }
        return User(user)
    }

    public func signIn(withEmail email: String, password: String) async throws -> AuthDataResult {
        let result = platformValue.signInWithEmailAndPassword(email, password).await()
        return AuthDataResult(result)
    }

    public func createUser(withEmail email: String, password: String) async throws -> AuthDataResult {
        let result = platformValue.createUserWithEmailAndPassword(email, password).await()
        return AuthDataResult(result)
    }

    public func signOut() throws {
        platformValue.signOut()
    }

    public func sendPasswordReset(withEmail email: String) async throws {
        platformValue.sendPasswordResetEmail(email).await()
    }

    public func signInAnonymously() async throws -> AuthDataResult {
        let result = platformValue.signInAnonymously().await()
        return AuthDataResult(result)
    }

     public func useEmulator(withHost host: String, port: Int) {
        platformValue.useEmulator(host, port)
     }

    public func addStateDidChangeListener(_ listener: @escaping (Auth, User?) -> Void) -> AuthStateListener {
        let stateListener = com.google.firebase.auth.FirebaseAuth.AuthStateListener { auth in
            let user = auth.currentUser != nil ? User(auth.currentUser!) : nil
            listener(Auth(platformValue: auth), user)
        }
        platformValue.addAuthStateListener(stateListener)
        return AuthStateListener(platformValue: stateListener)
    }

    public func removeStateDidChangeListener(_ listenerHandle: NSObjectProtocol) {
        platformValue.removeAuthStateListener((listenerHandle as AuthStateListener).platformValue)
    }
}

public class AuthDataResult: KotlinConverting<com.google.firebase.auth.AuthResult> {
    public let platformValue: com.google.firebase.auth.AuthResult

    public init(_ platformValue: com.google.firebase.auth.AuthResult) {
        self.platformValue = platformValue
    }

    public override func kotlin(nocopy: Bool = false) -> com.google.firebase.auth.AuthResult {
        platformValue
    }

    public var description: String {
        platformValue.toString()
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.platformValue == rhs.platformValue
    }

    public var user: User {
        User(platformValue.user!)
    }
}

public class AuthStateListener: NSObjectProtocol {
    public let platformValue: com.google.firebase.auth.FirebaseAuth.AuthStateListener

    public init(platformValue: com.google.firebase.auth.FirebaseAuth.AuthStateListener) {
        self.platformValue = platformValue
    }
}

public class User: KotlinConverting<com.google.firebase.auth.FirebaseUser> {
    public let platformValue: com.google.firebase.auth.FirebaseUser

    public init(_ platformValue: com.google.firebase.auth.FirebaseUser) {
        self.platformValue = platformValue
    }

    public override func kotlin(nocopy: Bool = false) -> com.google.firebase.auth.FirebaseUser {
        platformValue
    }

    public var description: String {
        platformValue.toString()
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.platformValue == rhs.platformValue
    }

    public var isAnonymous: Bool {
        platformValue.isAnonymous
    }

    public var providerID: String? {
        platformValue.providerId
    }

    public var uid: String {
        platformValue.uid
    }

    public var displayName: String? {
        platformValue.displayName
    }

    public var photoURL: URL? {
        guard let uri = platformValue.photoUrl else { return nil }
        return URL(string: uri.toString())!
    }

    public var email: String? {
        platformValue.email
    }

    public var phoneNumber: String? {
        platformValue.phoneNumber
    }

    public func createProfileChangeRequest() -> UserProfileChangeRequest {
        return UserProfileChangeRequest(self)
    }

    public func delete() async throws {
        platformValue.delete().await()
    }
}

public class UserProfileChangeRequest/*: KotlinConverting<com.google.firebase.auth.UserProfileChangeRequest>*/ {
    var user: User

    fileprivate init(user: User) {
        self.user = user
    }

    public var displayName: String?

    public func commitChanges() async throws {
        let builder = com.google.firebase.auth.UserProfileChangeRequest.Builder()

        if let displayName {
            builder.setDisplayName(displayName)
        }

        let platformChangeRequest: com.google.firebase.auth.UserProfileChangeRequest = builder.build()

        user.platformValue.updateProfile(platformChangeRequest).await()
    }
}

#endif
