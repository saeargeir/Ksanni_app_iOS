// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "KsanniApp",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "KsanniApp",
            targets: ["KsanniApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.0"),
    ],
    targets: [
        .target(
            name: "KsanniApp",
            dependencies: [
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                "Alamofire"
            ]),
        .testTarget(
            name: "KsanniAppTests",
            dependencies: ["KsanniApp"]),
    ]
)