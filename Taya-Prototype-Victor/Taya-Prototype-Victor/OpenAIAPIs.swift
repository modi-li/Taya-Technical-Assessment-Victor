//
//  OpenAIAPIs.swift
//  Taya-Prototype-Victor
//
//  Created by Modi (Victor) Li.
//

import Foundation
import Alamofire

struct OpenAITranscriptionAnalysisAPI: APIItem {
    
    let url = "https://api.openai.com/v1/responses"
    
    let httpMethod: HTTPMethod = .post
    
    let authRequired = false
    
    struct RequestData: Encodable {
        let model: String = "gpt-4o-mini"
        let input: [InputMessage]
        let text: TextFormat
        
        struct InputMessage: Encodable {
            let role: String
            let content: String
        }
        
        struct TextFormat: Encodable {
            let format: Format
            
            struct Format: Encodable {
                let type: String
                let schema: JSONSchema
                let name: String
                
                struct JSONSchema: Encodable {
                    let type: String
                    let properties: Properties
                    let required: [String]
                    let additionalProperties: Bool
                    
                    struct Properties: Encodable {
                        let title: SchemaProperty
                        let category: SchemaProperty
                        let action_items: ArrayProperty
                        let mood: SchemaProperty
                        
                        struct SchemaProperty: Encodable {
                            let type: String
                            let description: String
                        }
                        
                        struct ArrayProperty: Encodable {
                            let type: String
                            let description: String
                            let items: ItemType
                            
                            struct ItemType: Encodable {
                                let type: String
                            }
                        }
                    }
                }
            }
        }
        
        init(transcribedText: String) {
            self.input = [
                InputMessage(
                    role: "system",
                    content: """
                    You are an assistant that analyzes voice transcriptions and extracts structured information.
                    
                    The transcription may contain filler words (um, uh, like), repetitions, or minor transcription errors. Filter these out and focus on the actual message.
                    
                    IMPORTANT: Short or simple messages like "Hello", "Thanks", or "Buy milk" are VALID content, not noise. Only treat transcriptions as unclear if they contain actual nonsensical text that has no recognizable words or meaning.
                    
                    Respond with JSON only.
                    """
                ),
                InputMessage(
                    role: "user",
                    content: """
                    Analyze this voice transcription and extract:
                    - A short poetic title summarizing the content
                    - A category (Shopping, Learning, Meeting, Personal, Work, Health, Travel, Entertainment)
                    - Action items as specific tasks (only include clear, actionable items). If no action items are found, return an empty array.
                    - Overall mood/sentiment
                    
                    Transcription: \(transcribedText)
                    """
                )
            ]
            self.text = TextFormat(
                format: .init(
                    type: "json_schema",
                    schema: .init(
                        type: "object",
                        properties: .init(
                            title: .init(type: "string", description: "A short, poetic summary title"),
                            category: .init(type: "string", description: "Auto-tagging category like Shopping, Learning, Meeting, etc."),
                            action_items: .init(
                                type: "array",
                                description: "An array of specific tasks extracted from the transcription",
                                items: .init(type: "string")
                            ),
                            mood: .init(type: "string", description: "A sentiment string describing the overall mood")
                        ),
                        required: ["title", "category", "action_items", "mood"],
                        additionalProperties: false
                    ),
                    name: "transcription_analysis"
                )
            )
        }
    }
    
    struct ResponseData: Decodable {
        let output: [OutputItem]
        
        struct OutputItem: Decodable {
            let content: [OutputContent]
            
            struct OutputContent: Decodable {
                let text: String
            }
        }
    }
}

// MARK: - Transcription Analysis Result Model

struct TranscriptionAnalysis: Codable {
    let title: String
    let category: String
    let action_items: [String]
    let mood: String
}
