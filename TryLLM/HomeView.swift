// Copyright © 2024 Apple Inc.
//
//  HomeView.swift
//  TryLLM
//
//  Created by 黃軒和 on 2024/5/24.
//

import SwiftUI
import MarkdownUI

struct HomeView: View {
    @State var prompt = "早安"
    @State var llm: LocalLLM
    enum displayStyle: String, CaseIterable, Identifiable {
        case plain, markdown
        var id: Self { self }
    }
    @State private var selectedDisplayStyle = displayStyle.markdown
    @State var chatHistory = [[String]]()
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                HStack {
                    Text(llm.modelInfo)
                        .textFieldStyle(.roundedBorder)
                    
                    Spacer()
                    
                    Text(llm.stat)
                }
                HStack {
                    Spacer()
                    if llm.running {
                        ProgressView()
                            .frame(maxHeight: 20)
                        Spacer()
                    }
                    Picker("", selection: $selectedDisplayStyle) {
                        ForEach(displayStyle.allCases, id: \.self) { option in
                            Text(option.rawValue.capitalized)
                                .tag(option)
                        }
                        
                    }
                    .pickerStyle(.segmented)
#if os(visionOS)
                    .frame(maxWidth: 250)
#else
                    .frame(maxWidth: 150)
#endif
                }
            }
            
            // show the model output
            ScrollView(.vertical) {
                ScrollViewReader { sp in
                    Group {
                        ForEach(chatHistory, id: \.self) { item in
                            if item[0] == "user" {
                                HStack {
                                    Spacer()
                                    Text(item[1])
                                        .textSelection(.enabled)
                                }
                            } else {
                                HStack {
                                    if selectedDisplayStyle == .plain {
                                        Text(item[1])
                                            .textSelection(.enabled)
                                    } else {
                                        Markdown(item[1])
                                            .textSelection(.enabled)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        HStack {
                            if selectedDisplayStyle == .plain {
                                Text(llm.output)
                                    .textSelection(.enabled)
                            } else {
                                Markdown(llm.output)
                                    .textSelection(.enabled)
                            }
                            Spacer()
                        }
                    }
                    .onChange(of: llm.output) { _, _ in
                        sp.scrollTo("bottom")
                    }
                    
                    Spacer()
                        .frame(width: 1, height: 1)
                        .id("bottom")
                }
            }
            
            HStack {
                TextField("prompt", text: $prompt)
                    .onSubmit(generate)
                    .disabled(llm.running)
                #if os(visionOS)
                    .textFieldStyle(.roundedBorder)
                #endif
                Button("generate", action: generate)
                    .disabled(llm.running)
            }
        }
        #if os(visionOS)
        .padding(40)
        #else
        .padding()
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        copyToClipboard(llm.output)
                    }
                } label: {
                    Label("Copy Output", systemImage: "doc.on.doc.fill")
                }
                .disabled(llm.output == "")
                .labelStyle(.titleAndIcon)
            }
        }
    }
    
    private func generate() {
        if prompt != "" {
            if llm.output != "" {
                chatHistory.append(["model", llm.output])
            }
            chatHistory.append(["user", prompt])
            prompt = ""
            Task {
                await llm.generate(prompts: chatHistory)
            }
        }
    }
    
    private func copyToClipboard(_ string: String) {
#if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
#else
        UIPasteboard.general.string = string
#endif
    }
    
}

#Preview {
    HomeView(llm: LocalLLM())
}
