//
//  MemoryItem.swift
//  Taya-Prototype-Victor
//
//  Created by Modi (Victor) Li.
//

import Foundation
import SwiftData

@Model
final class MemoryItem {
    var id: UUID
    var title: String
    var category: String
    var actionItems: [String]
    var mood: String
    var transcription: String
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        actionItems: [String],
        mood: String,
        transcription: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.actionItems = actionItems
        self.mood = mood
        self.transcription = transcription
        self.createdAt = createdAt
    }
    
    convenience init(from analysis: TranscriptionAnalysis, transcription: String) {
        self.init(
            title: analysis.title,
            category: analysis.category,
            actionItems: analysis.action_items,
            mood: analysis.mood,
            transcription: transcription
        )
    }
}
