// Copyright © 2024 Apple Inc.
//
//  ContentView.swift
//  TryLLM
//
//  Created by 黃軒和 on 2024/5/21.
//

import SwiftUI
import MarkdownUI
import Metal
import MLX

struct ContentView: View {
    @State var llm = LocalLLM()
    @Environment(DeviceStat.self) private var deviceStat
    @State var modelConfigList = ModelConfigurationId.gemma1_1
    
    var body: some View {
        NavigationStack{
            TabView{
                HomeView(llm: llm)
                    .tabItem { Label("Home", systemImage: "house") }
                ModelListView()
                    .tabItem { Label("Weights", systemImage: "folder") }
            }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Picker(selection: $modelConfigList) {
                            ForEach(ModelConfigurationId.allCases) { modelConfig in
                                Text(modelConfig.rawValue)
                            }
                        } label: {
                        }
                    }
                    ToolbarItem {
                        Label(
                            "Memory Usage: \(deviceStat.gpuUsage.activeMemory.formatted(.byteCount(style: .memory)))",
                            systemImage: "info.circle.fill"
                        )
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal)
                        .help(
                            Text(
                            """
                            Active Memory: \(deviceStat.gpuUsage.activeMemory.formatted(.byteCount(style: .memory)))/\(GPU.memoryLimit.formatted(.byteCount(style: .memory)))
                            Cache Memory: \(deviceStat.gpuUsage.cacheMemory.formatted(.byteCount(style: .memory)))/\(GPU.cacheLimit.formatted(.byteCount(style: .memory)))
                            Peak Memory: \(deviceStat.gpuUsage.peakMemory.formatted(.byteCount(style: .memory)))
                            """
                            )
                        )
                    }
                    
                }
                .task {
                    //pre-load the weights on launch to speed up the first generation
                    _ = try? await llm.load()
                }
                .onChange(of: modelConfigList) {
                    llm.ChangeConfig(modelConfigList)
                    if !llm.running{
                        Task{
                            _ = try? await llm.load()
                        }
                    }
                }
        }
    }
}

//#Preview {
//    ContentView()
//}
