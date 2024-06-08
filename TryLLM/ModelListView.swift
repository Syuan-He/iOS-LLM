//
//  WeightFileListView.swift
//  TryLLM
//
//  Created by 黃軒和 on 2024/5/29.
//

import SwiftUI

struct ModelListView: View {
    let tempPath = NSTemporaryDirectory()
    @State var modelsUrl: URL?
    @State var weightUrl: URL?
    @State var fileList = [""]
    @State var showAlert = false
    
    @State var modelList = [""]
    
    var body: some View {
        VStack {
            Text(tempPath)
            if !fileList.isEmpty {
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
            } else {
                Text("no file")
            }
            
            Text(modelsUrl?.path ?? "no model")
            List{
                ForEach(modelList, id: \.self){
                    modelName in
                    NavigationLink {
                        if let modelPath = modelsUrl {
                            ModelContentView(modelPath: modelPath.path, weightPath: modelName)
                        }else{
                            Text("no model")
                        }
                    } label: {
                        Text(modelName)
                    }
                    
                }
            }
        }
        .onAppear(){
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let downloadBase = documents.appending(component: "huggingface")
            modelsUrl = downloadBase
                .appending(component: "models")
                .appending(component: "mlx-community")
            fileList = try! FileManager.default.contentsOfDirectory(atPath: tempPath)
            do {
                modelList = try FileManager.default.contentsOfDirectory(atPath: modelsUrl!.path)
            } catch {
                print("error: weightList")
            }
        }
    }
   
}

#Preview {
    ModelListView()
}
