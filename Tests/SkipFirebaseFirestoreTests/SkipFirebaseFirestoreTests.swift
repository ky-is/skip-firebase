// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import XCTest
import OSLog
import Foundation

#if !SKIP
import FirebaseCore
import FirebaseFirestore
#else
import SkipFirebaseCore
import SkipFirebaseFirestore
#endif

let logger: Logger = Logger(subsystem: "SkipFirebaseFirestoreTests", category: "Tests")

var appName: String = "SkipFirebaseDemo"

// NOTE: we have @MainActor on SkipFirebaseFirestoreTests to force non-concurrent test execution in order to avoid errors like this:
//
// Test Suite 'Selected tests' started at 2024-11-07 12:54:30.612.Test Suite 'skip-firebasePackageTests.xctest' started at 2024-11-07 12:54:30.614.Test Suite 'SkipFirebaseFirestoreTests' started at 2024-11-07 12:54:30.614.Test Case '-[SkipFirebaseFirestoreTests.SkipFirebaseFirestoreTests test_exists_trueForExistentDocument]' started.2024-11-07 12:54:30.823 xctest[15414:52946] *** Assertion failure in void firebase::firestore::core::FirestoreClient::Initialize(const User &, const Settings &)(), /var/folders/4b/7k50gk0j4f5bjk3799wdt8nw0000gn/T/ZipRelease/2024-10-14T13-23-42/project-macos/Pods/FirebaseFirestoreInternal/Firestore/core/src/core/firestore_client.cc:2172024-11-07 12:54:30.900 xctest[15414:52946] *** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'FIRESTORE INTERNAL ASSERTION FAILED: Failed to open DB: Internal: Failed to open LevelDB database at /Users/runner/Library/Application Support/firestore/SkipFirebaseDemo/skip-firebase-demo/main: LevelDB error: IO error: lock /Users/runner/Library/Application Support/firestore/SkipFirebaseDemo/skip-firebase-demo/main/LOCK: Resource temporarily unavailable (expected created.ok())'


@MainActor final class SkipFirebaseFirestoreTests: XCTestCase {

    /// App needs to be initialized in setUp and cleaned up in tearDown
    fileprivate static var app: FirebaseApp?
    fileprivate static var db: Firestore?

    // runtestFirestoreBundles$SkipFirebaseFirestore_debugUnitTest kotlinx.coroutines.test.UncompletedCoroutinesError: After waiting for 10s, the test coroutine is not completing, there were active child jobs: [DispatchedCoroutine{Active}@3816ef2f]
    // Suppressed: org.robolectric.android.internal.AndroidTestEnvironment$UnExecutedRunnablesException: Main looper has queued unexecuted runnables. This might be the cause of the test failure. You might need a shadowOf(Looper.getMainLooper()).idle() call

    var app: FirebaseApp { Self.app! }
    var db: Firestore { Self.db! }

    override func setUp() {
        if Self.app != nil {
            return
        }

        // this is generally loaded from the system's GoogleService-Info.plist / google-services.json using the default constructor, but for the sake of the test case we manually set it up here
        let options = FirebaseOptions(googleAppID: "1:599015466373:ios:918f07f9e07f56b03890ec", gcmSenderID: "599015466373")

        XCTAssertNil(options.apiKey)
        XCTAssertNil(options.projectID)
        XCTAssertNil(options.storageBucket)
        XCTAssertNil(options.databaseURL)
        #if !SKIP // TODO: add options to FirebaseOptions
        XCTAssertNil(options.appGroupID)
        XCTAssertNil(options.clientID)
        XCTAssertNil(options.deepLinkURLScheme)
        #endif

        options.projectID = "skip-firebase-demo"
        options.storageBucket = "skip-firebase-demo.appspot.com"

        options.apiKey = ProcessInfo.processInfo.environment["SKIP_FIREBASE_API_KEY"] ?? String(data: Data(base64Encoded: "QUl6YVN5QzV2bDFNYUc2S0hMOU15V1kyWGhxTHZCdVJsVEhrc3lR")!, encoding: .utf8)
        if options.apiKey == nil {
            fatalError("no api key set in SKIP_FIREBASE_API_KEY environment")
        }

        if ({ 0 == 1 }())  {
            // these are just to validate the existance of the API
            FirebaseApp.configure()
            FirebaseApp.configure(options: options)
        }

        FirebaseApp.configure(name: appName, options: options)

        // the app is registered statically, so check to see if it has been registered
        if let app = FirebaseApp.app(name: appName) {
            app.isDataCollectionDefaultEnabled = false
            Self.app = app
            Self.db = Firestore.firestore(app: app, database: "(default)")
        } else {
            fatalError("unable to load FirebaseApp.app(name: \"\(appName)\")")
        }
    }

    #if SKIP
    override func tearDown() throws {
        //FirebaseApp.app(name: appName)?.delete()

        // needed or else: Suppressed: org.robolectric.android.internal.AndroidTestEnvironment$UnExecutedRunnablesException: Main looper has queued unexecuted runnables. This might be the cause of the test failure. You might need a shadowOf(Looper.getMainLooper()).idle() call.
        //org.robolectric.Shadows.shadowOf(android.os.Looper.getMainLooper()).idle()
    }
    #else
    override func tearDown() async throws {
        //await FirebaseApp.app(name: appName)?.delete()
    }
    #endif

    /// This is never invoked, it is just to validate API parity
    private func validateFirebaseWrapperAPI() async throws {
        //let db: Firestore = Firestore.firestore(app: self.app)

        let cityDocumentFromRoot = db.document("cities/nyc")
        XCTAssertEqual(cityDocumentFromRoot.documentID, "nyc")

        let colRef: CollectionReference = db.collection("")
        let _: Firestore = colRef.firestore
        let _: String = colRef.collectionID
        let dref: DocumentReference? = colRef.parent
        let _ = dref?.path
        let _ = dref?.parent

        let _: String = colRef.path
        let _ = colRef.document()
        let _ = colRef.collectionID
        let _ = colRef.parent
        let _ = colRef.path
        try await colRef.addDocument(data: ["x": 0.0])

        let aq: AggregateQuery = colRef.count
        let _ = aq.query

        let aqs: AggregateQuerySnapshot = try await aq.getAggregation(source: AggregateSource.server)
        let _ = aqs.count
        let _: AggregateQuery = aqs.query

        let af: AggregateField = AggregateField.average("ABC")
        let _ = aqs.get(af)


        let _: Query = colRef.limit(to: 10)

        let _: Query = colRef.order(by: "x")
        let _: Query = colRef.order(by: "x", descending: true)

        let _: Query = colRef.whereFilter(Filter())
        let _: Query = colRef.whereFilter(Filter.orFilter([
            Filter.whereField("foo", isEqualTo: "bar"),
            Filter.whereField("foo", isNotEqualTo: "bar")
        ]))

        let _: Query = colRef.whereField("x", in: ["x"])
        //let _: Query = colRef.whereField("x", notIn: ["x"])
        let _: Query = colRef.whereField("x", isEqualTo: "x")
        let _: Query = colRef.whereField("x", arrayContains: "x")
        let _: Query = colRef.whereField("x", arrayContainsAny: ["x"])
        let _: Query = colRef.whereField("x", isGreaterThan: "x")
        let _: Query = colRef.whereField("x", isGreaterThanOrEqualTo: "x")
        let _: Query = colRef.whereField("x", isNotEqualTo: "x")
        let _: Query = colRef.whereField("x", isLessThanOrEqualTo: "x")
        let _: Query = colRef.whereField("x", isLessThan: "x")

        let fp: FieldPath = FieldPath(["x", "y"])
        let _: Query = colRef.whereField(fp, in: ["x"])
        //let _: Query = colRef.whereField(fp, notIn: ["x"])
        let _: Query = colRef.whereField(fp, isEqualTo: "x")
        let _: Query = colRef.whereField(fp, arrayContains: "x")
        let _: Query = colRef.whereField(fp, arrayContainsAny: ["x"])
        let _: Query = colRef.whereField(fp, isGreaterThan: "x")
        let _: Query = colRef.whereField(fp, isGreaterThanOrEqualTo: "x")
        let _: Query = colRef.whereField(fp, isNotEqualTo: "x")
        let _: Query = colRef.whereField(fp, isLessThanOrEqualTo: "x")
        let _: Query = colRef.whereField(fp, isLessThan: "x")


        let listenerRef: ListenerRegistration = colRef.addSnapshotListener { snap, error in
            if let snap = snap {
                let _: [DocumentChange] = snap.documentChanges
                let _: [DocumentChange] = snap.documentChanges(includeMetadataChanges: true)
                let _: [QueryDocumentSnapshot] = snap.documents
                let _: Query = snap.query
                let _: Int = snap.count
                let _: Bool = snap.isEmpty
                let _: SnapshotMetadata = snap.metadata
            }
        }
        listenerRef.remove()

        let docRef: DocumentReference = colRef.document("")
        let _: Firestore = docRef.firestore
        let _: String = docRef.documentID
        let _: String = docRef.path
        let _: CollectionReference = docRef.parent

        try await db.disableNetwork()
        try await db.enableNetwork()

        try await db.clearPersistence()
        try await db.terminate()

        //try await db.terminate()
        //_ = try await db.runTransaction { transaction, errorPtr in
        //    transaction.setData([:], forDocument: bos)
        //}

        // test encodable API variants
        //try citiesRef.addDocument(from: ["dict": "value"])
        //try citiesRef.addDocument(from: ["array", "value"])
    }

    func testFirestore() async throws {
        XCTAssertEqual(appName, self.app.name)

        let citiesRef = db.collection("cities")

        do {
            let snapshot = try await citiesRef.getDocuments()
            for document in snapshot.documents {
                logger.log("read citiesRef: \(document.documentID) => \(document.data())")
            }
        }

        let ts = Timestamp(seconds: 12345, nanoseconds: 100_000_000)
        XCTAssertEqual(12345, ts.seconds)
        XCTAssertEqual(100_000_000, ts.nanoseconds)
        XCTAssertEqual(12345.1, ts.dateValue().timeIntervalSince1970, accuracy: 0.001)

        let bos: DocumentReference = citiesRef.document("BOS")

        var listenerChanges = 0
        let docListener: ListenerRegistration = bos.addSnapshotListener(includeMetadataChanges: true) { snapshot, error in
            listenerChanges += 1
        }
        defer { docListener.remove() }

        XCTAssertEqual(0, listenerChanges)
        try await bos.setData(Self.bostonData)
        if !isJava { // doesn't fire immediately on Android
            XCTAssertEqual(3, listenerChanges)
        }

        let bdoc: DocumentSnapshot = try await bos.getDocument()
        XCTAssertEqual("Boston", bdoc.get("name") as? String)

        XCTAssertNotNil(bdoc.get("regions"))

        // SKIP NOWARN
        XCTAssertEqual(["east_coast", "new_england"], bdoc.get("regions") as? [String])

        XCTAssertNotNil(bdoc.get("time"))
        XCTAssertEqual(Timestamp(date: Date(timeIntervalSince1970: 1234)), bdoc.get("time") as? Timestamp)

        XCTAssertEqual(555000, bdoc.get("population") as? Int64)
        let bosData: [String: Any] = ["population": 675000]
        try await bos.updateData(bosData)

        XCTAssertEqual(555000, bdoc.get("population") as? Int64)
        let bdoc2 = try await bos.getDocument()
        XCTAssertEqual(675000, bdoc2.get("population") as? Int64)

        try await citiesRef.document("LA").setData([
            "name": "Los Angeles",
            "state": "CA",
            "country": "USA",
            "capital": false,
            "population": 3900000,
            "regions": ["west_coast", "socal"]
        ])
        try await citiesRef.document("DC").setData([
            "name": "Washington D.C.",
            "country": "USA",
            "capital": true,
            "population": 680000,
            "regions": ["east_coast"]
        ])
        try await citiesRef.document("TOK").setData([
            "name": "Tokyo",
            "country": "Japan",
            "capital": true,
            "population": 9000000,
            "regions": ["kanto", "honshu"]
        ])
        try await citiesRef.document("BJ").setData([
            "name": "Beijing",
            "country": "China",
            "capital": true,
            "population": 21500000,
            "regions": ["jingjinji", "hebei"]
        ])

        do {
            let snapshot: QuerySnapshot = try await citiesRef.getDocuments()
            for document in snapshot.documents {
                logger.log("read citiesRef: \(document.documentID) => \(document.data())")
            }
        }

        XCTAssertEqual(appName, self.app.name)

        let tblref = db.collection("testFirestoreQuery")
        let doc = try await tblref.addDocument(data: [
            "when": Date.now.timeIntervalSince1970
        ])
        logger.log("testFirestoreQuery: id=\(doc.documentID)")

        var changes = 0
        let reg = tblref.addSnapshotListener(includeMetadataChanges: true, listener: { querySnapshot, error in
            changes += 1
            guard let querySnapshot else {
                return XCTFail("no query snapshot")
            }
            logger.log("querySnapshot: \(querySnapshot)")
            for diff in querySnapshot.documentChanges {
                logger.log("  diff: \(diff)")
            }
        })
        defer { reg.remove() }

        let when = Date.now.timeIntervalSince1970
        XCTAssertEqual(0, changes)

        let doc2Ref = try await tblref.addDocument(data: [
            "when": when
        ])
        if !isJava { // doesn't fire immediately on Android
            XCTAssertEqual(2, changes)
        }

        let doc2 = try await doc2Ref.getDocument()
        XCTAssertEqual(when, doc2.get("when") as? Double)

        try await assertExistsFalseForNonExistentDocument()

        try await assertExistsTrueForExistentDocument()
    }

    // test disabled because we cannot seem to have multiple simultaneous firebase setups running
    func DISABLEDtestFirestoreBundles() async throws {

        // see Resources/ firestore_bundle-1.json, firestore_bundle-2.json, firestore_bundle-3.json
        let bundle1 = try Data(contentsOf: XCTUnwrap(Bundle.module.url(forResource: "firestore_bundle-1", withExtension: "json")))

        let data = bundle1

        // the name of the app must match the bundle to be loaded, or else:
        // 10.19.1 - [FirebaseFirestore][I-FST000001] Failed to GetNextElement() from bundle with error Resource name is not valid for current instance: projects/react-native-firebase-testing/databases/(default)/documents

        let appName = "react-native-firebase-testing"

        let options = FirebaseOptions(googleAppID: self.app.options.googleAppID, gcmSenderID: self.app.options.gcmSenderID)
        options.projectID = appName
        options.storageBucket = appName + ".appspot.com"

        options.apiKey = self.app.options.apiKey
        if options.apiKey == nil {
            fatalError("no api key set in SKIP_FIREBASE_API_KEY environment")
        }

        FirebaseApp.configure(name: appName, options: options)

        // the app is registered statically, so check to see if it has been registered
        let cacheApp = try XCTUnwrap(FirebaseApp.app(name: appName))

        let store = Firestore.firestore(app: cacheApp)

        let progress: LoadBundleTaskProgress = try await store.loadBundle(data)
        XCTAssertEqual(12, progress.totalDocuments)

        let cacheQuery = await store.getQuery(named: "named-bundle-test-1")
        // SKIP NOWARN
        let docs = try await XCTUnwrap(cacheQuery).getDocuments(source: FirestoreSource.cache)
        XCTAssertEqual(12, docs.count)

        // SKIP NOWARN
        await cacheApp.delete()
    }

    func assertExistsFalseForNonExistentDocument() async throws {
        XCTAssertEqual(appName, self.app.name)
        let citiesRef = db.collection("cities")
        let bos = citiesRef.document("BOS")
        try await bos.setData(Self.bostonData)
        let ref = citiesRef.document("NON_EXISTENT_DOCUMENT")
        do {
            let snapshot = try await ref.getDocument()
            XCTAssertFalse(snapshot.exists)
            XCTAssertNil(snapshot.data())
        }
        do {
            try await ref.updateData(Self.bostonData)
            XCTFail("updateData should throw on non-existent document")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, FirestoreErrorDomain)
            XCTAssertEqual(nsError.code, FirestoreErrorCode.notFound.rawValue)
        }
    }

    func assertExistsTrueForExistentDocument() async throws {
        XCTAssertEqual(appName, self.app.name)
        let citiesRef = db.collection("cities")
        let bos = citiesRef.document("BOS")
        try await bos.setData(Self.bostonData)
        let ref = citiesRef.document("BOS")
        do {
            let snapshot = try await ref.getDocument()
            XCTAssertTrue(snapshot.exists)
        }
    }
}

extension SkipFirebaseFirestoreTests {
    private static let bostonData: [String : Any] = [
        "name": "Boston",
        "state": "MA",
        "country": "USA",
        "capital": false,
        "population": 555000,
        "regions": ["east_coast", "new_england"],
        "time": Timestamp(date: Date(timeIntervalSince1970: 1234))
    ]
}

struct TestData : Codable, Hashable {
    var testModuleName: String
}
