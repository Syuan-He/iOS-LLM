//
//  TryLLMApp.swift
//  TryLLM
//
//  Created by 黃軒和 on 2024/5/21.
//

import SwiftUI

@main
struct TryLLMApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().environment(DeviceStat())
        }
    }
}
