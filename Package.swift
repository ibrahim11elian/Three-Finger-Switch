// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "ThreeFingerSwitch",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "ThreeFingerSwitch", targets: ["ThreeFingerSwitch"]),
    .executable(name: "RecognizerChecks", targets: ["RecognizerChecks"]),
  ],
  targets: [
    .target(
      name: "ThreeFingerSwitchCore",
      path: "Sources/ThreeFingerSwitchCore"
    ),
    .executableTarget(
      name: "ThreeFingerSwitch",
      dependencies: ["ThreeFingerSwitchCore"],
      path: "Sources/ThreeFingerSwitch"
    ),
    .executableTarget(
      name: "RecognizerChecks",
      dependencies: ["ThreeFingerSwitchCore"],
      path: "Checks/RecognizerChecks"
    ),
  ]
)
