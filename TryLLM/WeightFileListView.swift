//
//  WeightFileListView.swift
//  TryLLM
//
//  Created by 黃軒和 on 2024/5/29.
//

import SwiftUI

struct WeightFileListView: View {
    let tempPath = NSTemporaryDirectory()
    @State var modelsUrl: URL?
    @State var fileList = [""]
    @State var showAlert = false
    
    @State var weightList = [""]
    
    var body: some View {
        VStack {
            Text(tempPath)
            List{
                ForEach(fileList, id: \.self){ file in
                    Button {
                        showAlert = true
                    } label: {
                        Text(file)
                    }
                    .alert("delete the file:\n\(file)", isPresented: $showAlert){
                        Button("Cancel") {
                            
                        }
                        Button("Accept") {
                            try! FileManager.default.removeItem(atPath: tempPath + file)
                            fileList = try! FileManager.default.contentsOfDirectory(atPath: tempPath)
                        }
                    }
                }
            }
            Text(modelsUrl?.path ?? "no model")
            List{
                ForEach(weightList, id: \.self){
                    weight in
                    Text(weight)
                }
            }
        }
        .onAppear(){
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let downloadBase = documents.appending(component: "huggingface")
            modelsUrl = downloadBase.appending(component: "models").appending(component: "mlx-community/gemma-1.1-2b-it-4bit")
            fileList = try! FileManager.default.contentsOfDirectory(atPath: tempPath)
            do {
                weightList = try FileManager.default.contentsOfDirectory(atPath: modelsUrl!.path)
            } catch {
                print("error")
            }
            for file in fileList {
                print(file)
                print("done")
            }
        }
    }
   
}

#Preview {
    WeightFileListView()
}
