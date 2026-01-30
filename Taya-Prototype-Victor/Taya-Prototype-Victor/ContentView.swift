//
//  ContentView.swift
//  Taya-Prototype-Victor
//
//  Created by Modi (Victor) Li.
//

import SwiftUI
import SwiftData
import DSWaveformImage
import DSWaveformImageViews

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MemoryItem.createdAt, order: .reverse) private var memories: [MemoryItem]
    
    @State private var audioRecordingManager = AudioRecordingManager()
    @State private var showRecordingSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                
                if memories.isEmpty {
                    ContentUnavailableView(
                        "No Memories",
                        systemImage: "document",
                        description: Text("Tap the record button to capture your first thought")
                    )
                } else {
                    List {
                        ForEach(memories) { memory in
                            MemoryCard(from: memory)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteMemory(memory)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteMemory(memory)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .contentMargins(.bottom, 120) // Space for the record button
                }
                
                VStack {
                    Spacer()
                    
                    Button {
                        audioRecordingManager.startRecording()
                        showRecordingSheet = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 20))
                            Text("Record")
                                .font(.headline)
                        }
                        .frame(width: 160, height: 56)
                    }
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.capsule)
                    .shadow(color: .accentColor.opacity(0.3), radius: 12, x: 0, y: 6)
                    .sensoryFeedback(.selection, trigger: audioRecordingManager.isRecording)
                    .padding(.bottom, 20)
                }
            }
            .sheet(isPresented: $showRecordingSheet) {
                RecordingSheetView(
                    audioRecordingManager: audioRecordingManager,
                    onSave: { analysis, transcription in
                        saveMemory(analysis: analysis, transcription: transcription)
                        showRecordingSheet = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .navigationTitle("Memories")
        }
    }
    
    private func saveMemory(analysis: TranscriptionAnalysis, transcription: String) {
        let memory = MemoryItem(from: analysis, transcription: transcription)
        modelContext.insert(memory)
    }
    
    private func deleteMemory(_ memory: MemoryItem) {
        modelContext.delete(memory)
    }
}


#Preview {
    ContentView()
}
