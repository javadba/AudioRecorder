//
//  AppDelegate.swift
//  AudioRecorder2
//

import UIKit
import Backtrace

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        Backtrace.install()
        return true
    }

}

