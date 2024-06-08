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
    @Environment(\.dismiss) var dismiss
    @State private var isAlertPresented = false
    
    var body: some View {
        Button{
            isAlertPresented = true
        } label: {
            Text("Delete Model")
        }
        .alert("Delete the Model: \n\(weightPath)", isPresented: $isAlertPresented) {
            Button("Cancel") {
                
            }
            Button("Accept") {
                try! FileManager.default.removeItem(atPath: "\(modelPath)/\(weightPath)")
                dismiss()
            }
        }
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
