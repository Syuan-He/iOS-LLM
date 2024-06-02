// Copyright © 2024 Apple Inc.
//
//  DLModel.swift
//  TryLLM
//
//  Created by 黃軒和 on 2024/5/21.
//

import Foundation
import MLXLLM
import Hub
import MLX
import MLXRandom
import Tokenizers

@Observable
class LLMEvaluator {

    @MainActor
    var running = false

    var output = ""
    var modelInfo = ""
    var stat = ""

    /// this controls which model loads -- phi4bit is one of the smaller ones so this will fit on
    /// more devices
    let modelConfiguration = ModelConfiguration(
        id: "mlx-community/gemma-1.1-2b-it-4bit",
        overrideTokenizer: "PreTrainedTokenizer"
    ) { prompt in
        "<start_of_turn>user \(prompt)<end_of_turn><start_of_turn>model"
    }

    /// parameters controlling the output
    let generateParameters = GenerateParameters(temperature: 0.6)
    let maxTokens = 240

    /// update the display every N tokens -- 4 looks like it updates continuously
    /// and is low overhead.  observed ~15% reduction in tokens/s when updating
    /// on every token
    let displayEveryNTokens = 4

    enum LoadState {
        case idle
        case loaded(LLMModel, Tokenizers.Tokenizer)
    }

    var loadState = LoadState.idle

    /// load and return the model -- can be called multiple times, subsequent calls will
    /// just return the loaded model
    func load() async throws -> (LLMModel, Tokenizers.Tokenizer) {
        switch loadState {
        case .idle:
            let (model, tokenizer) = try await getModel()
            
            self.modelInfo =
                "Loaded \(modelConfiguration.id).  Weights: \(MLX.GPU.activeMemory / 1024 / 1024)M"
//            print(self.modelInfo)
            loadState = .loaded(model, tokenizer)
            return (model, tokenizer)

        case .loaded(let model, let tokenizer):
            return (model, tokenizer)
        }
    }
    
    private func getModel() async throws -> (LLMModel, Tokenizer){
        
        // limit the buffer cache
        MLX.GPU.set(cacheLimit: 20 * 1024 * 1024 * 1024)
        do {
            let (model, tokenizer) = try await MLXLLM.load(configuration: modelConfiguration) {
                [modelConfiguration] progress in
                DispatchQueue.main.sync {
                    self.modelInfo =
                    "Downloading \(modelConfiguration.name): \(Int(progress.fractionCompleted * 100))%"
                }
                //                print("\(progress)")
            }
            
            return (model, tokenizer)
        } catch {
            print(error)
            
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let downloadBase = documents.appending(component: "huggingface")
            let modelWeightDir: String
            switch modelConfiguration.id{
            case .id(let id):
                modelWeightDir = id
            case .directory(let directory):
                modelWeightDir = directory.lastPathComponent
            }

            let rewriteModelConfig = ModelConfiguration(
                directory: downloadBase.appending(path: "models").appending(path: modelWeightDir),
                overrideTokenizer: "PreTrainedTokenizer"
            ) { prompt in
                "<start_of_turn>user \(prompt)<end_of_turn><start_of_turn>model"
            }
            print("Ready to load model.")
            let (model, tokenizer) = try await MLXLLM.load(configuration: rewriteModelConfig){
                [modelConfiguration] progress in
                DispatchQueue.main.sync {
                    self.modelInfo =
                    "Loading \(modelConfiguration.name): \(Int(progress.fractionCompleted * 100))%"
                }
            }
            print ("Model loaded.")
            return (model, tokenizer)
        }
    }

    func generate(prompt: String) async {
        let canGenerate = await MainActor.run {
            if running {
                return false
            } else {
                running = true
                self.output = ""
                return true
            }
        }

        guard canGenerate else { return }

        do {
            let (model, tokenizer) = try await load()
            // augment the prompt as needed
            let prompt = modelConfiguration.prepare(prompt: prompt)
            let promptTokens = tokenizer.encode(text: prompt)

            // each time you generate you will get something new
            MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))

            let result = await MLXLLM.generate(
                promptTokens: promptTokens, parameters: generateParameters, model: model,
                tokenizer: tokenizer
            ) { tokens in
                // update the output -- this will make the view show the text as it generates
                if tokens.count % displayEveryNTokens == 0 {
                    let text = tokenizer.decode(tokens: tokens)
                    await MainActor.run {
                        self.output = text
                    }
                }

                if tokens.count >= maxTokens {
                    return .stop
                } else {
                    return .more
                }
            }

            // update the text if needed, e.g. we haven't displayed because of displayEveryNTokens
            await MainActor.run {
                if result.output != self.output {
                    self.output = result.output
                }
                running = false
                self.stat = " Tokens/second: \(String(format: "%.3f", result.tokensPerSecond))"
            }

        } catch {
            await MainActor.run {
                running = false
                output = "Failed: \(error)"
            }
        }
    }
}
