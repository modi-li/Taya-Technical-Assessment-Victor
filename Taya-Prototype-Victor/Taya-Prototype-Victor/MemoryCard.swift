//
//  MemoryCard.swift
//  Taya-Prototype-Victor
//
//  Created by Modi (Victor) Li.
//

import SwiftUI

struct MemoryCard: View {
    
    let title: String
    let category: String
    let mood: String
    let actionItems: [String]
    let transcription: String
    
    init(
        title: String,
        category: String,
        mood: String,
        actionItems: [String],
        transcription: String,
    ) {
        self.title = title
        self.category = category
        self.mood = mood
        self.actionItems = actionItems
        self.transcription = transcription
    }
    
    init(from item: MemoryItem) {
        self.title = item.title
        self.category = item.category
        self.mood = item.mood
        self.actionItems = item.actionItems
        self.transcription = item.transcription
    }
    
    init(from analysis: TranscriptionAnalysis, transcription: String) {
        self.title = analysis.title
        self.category = analysis.category
        self.mood = analysis.mood
        self.actionItems = analysis.action_items
        self.transcription = transcription
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Spacer()
                
                Text(category)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .foregroundStyle(.secondary)
                    .clipShape(Capsule())
                    .padding(.leading, 4)
            }
            
            HStack(spacing: 8) {
                Text("Mood:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Text(mood)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                if actionItems.isEmpty {
                    Text("No Action Items")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Action Items")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(actionItems.prefix(3), id: \.self) { item in
                                HStack(spacing: 8) {
                                    Image(systemName: "circle")
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundStyle(.secondary)
                                    Text(item)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                }
                            }
                        }
                        
                        if actionItems.count > 3 {
                            Text("+\(actionItems.count - 3) more")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 16)
                        }
                    }
                }
            }
            
            if !transcription.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Transcription")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text(transcription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MemoryCard(
            title: "Morning Coffee Reflections",
            category: "Personal",
            mood: "Calm and thoughtful",
            actionItems: [
                "Buy more coffee beans",
                "Try the new cafe downtown",
                "Call mom about weekend plans"
            ],
            transcription: "I was just thinking about how nice it is to have a quiet morning with my coffee..."
        )
    }
    .padding()
}
