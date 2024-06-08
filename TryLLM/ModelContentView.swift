//
//  WeightFileView.swift
//  TryLLM
//
//  Created by 黃軒和 on 2024/6/7.
//

import SwiftUI

struct ModelContentView: View {
    let modelPath: String
    let weightPath: String
    @State private var contentList = [""]
    
    var body: some View {
        List {
            ForEach(contentList, id: \.self) { content in
                Text(content)
            }
        }
            .onAppear(){
                do {
                    contentList = try FileManager.default.contentsOfDirectory(atPath: "\(modelPath)/\(weightPath)")
                } catch {
                    print("error: contentList")
                }
            }
    }
}

#Preview {
    ModelContentView(modelPath: "", weightPath: "")
}
