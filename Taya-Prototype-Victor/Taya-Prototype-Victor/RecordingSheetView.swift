//
//  RecordingSheetView.swift
//  Taya-Prototype-Victor
//
//  Created by Modi (Victor) Li.
//

import SwiftUI

struct RecordingSheetView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var audioRecordingManager: AudioRecordingManager
    let onSave: (TranscriptionAnalysis, String) -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Timer
                    Text(String(format: "%.1fs", audioRecordingManager.currentTime))
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .foregroundStyle(audioRecordingManager.isRecording ? .primary : .secondary)
                        .contentTransition(.numericText())
                        .animation(.default, value: audioRecordingManager.currentTime)
                    
                    // Waveform
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                        
                        RealtimeWaveformView(
                            samples: audioRecordingManager.audioSamples,
                            color: audioRecordingManager.isRecording ? .accentColor : .gray
                        )
                        .padding(12)
                    }
                    .frame(height: 100)
                    
                    Button {
                        if audioRecordingManager.isRecording {
                            audioRecordingManager.stopRecording()
                        } else {
                            audioRecordingManager.startRecording()
                        }
                    } label: {
                        Image(systemName: audioRecordingManager.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                            .frame(width: 80, height: 80)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(audioRecordingManager.isRecording ? .red : .accentColor)
                    .shadow(color: (audioRecordingManager.isRecording ? Color.red : Color.accentColor).opacity(0.4), radius: 6, x: 0, y: 4)
                    .sensoryFeedback(.selection, trigger: audioRecordingManager.isRecording)
                    
                    
                    if !audioRecordingManager.isRecording {
                        TranscriptionView(audioRecordingManager: audioRecordingManager)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    if audioRecordingManager.transcriptionSuccess && !audioRecordingManager.isRecording {
                        VStack(spacing: 10) {
                            if audioRecordingManager.isAnalyzing {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                    Text("Analyzing your thoughts...")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(40)
                                .background {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemGray6))
                                }
                            } else if let error = audioRecordingManager.analysisError {
                                VStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.red)
                                    Text(error)
                                        .font(.subheadline)
                                        .foregroundStyle(.red)
                                        .multilineTextAlignment(.center)
                                    Button("Retry") {
                                        audioRecordingManager.analyzeWithLLM()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(24)
                                .background {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemGray6))
                                }
                            } else if let analysis = audioRecordingManager.currentAnalysis,
                                      let transcription = audioRecordingManager.transcribedText {
                                
                                HStack {
                                    Text("Memory Card")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                
                                // Show memory card preview
                                MemoryCard(from: analysis, transcription: transcription)
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding()
                .animation(.spring(duration: 0.4), value: audioRecordingManager.isRecording)
                .animation(.spring(duration: 0.4), value: audioRecordingManager.transcriptionSuccess)
                .animation(.spring(duration: 0.4), value: audioRecordingManager.analysisComplete)
                .animation(.spring(duration: 0.4), value: audioRecordingManager.analysisError)
            }
            .onChange(of: audioRecordingManager.transcriptionSuccess) { _, success in
                if success {
                    audioRecordingManager.analyzeWithLLM()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if audioRecordingManager.isRecording {
                            audioRecordingManager.stopRecording()
                        }
                        dismiss()
                    }
                }
                if let analysis = audioRecordingManager.currentAnalysis,
                   let transcription = audioRecordingManager.transcribedText {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            onSave(analysis, transcription)
                        } label: {
                            Text("Save")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
            }
        }
        .interactiveDismissDisabled()
    }
}

struct RealtimeWaveformView: View {
    
    let samples: [Float]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midHeight = height / 2
                
                guard !samples.isEmpty else { return }
                
                let stepWidth = width / CGFloat(samples.count - 1)
                
                // Draw waveform
                for (index, sample) in samples.enumerated() {
                    let x = CGFloat(index) * stepWidth
                    let amplitude = CGFloat(sample) * midHeight * 0.8
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: midHeight - amplitude))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: midHeight - amplitude))
                    }
                }
                
                // Mirror for bottom half
                for (index, sample) in samples.enumerated().reversed() {
                    let x = CGFloat(index) * stepWidth
                    let amplitude = CGFloat(sample) * midHeight * 0.8
                    path.addLine(to: CGPoint(x: x, y: midHeight + amplitude))
                }
                
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [color.opacity(0.8), color.opacity(0.4)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
}

struct TranscriptionView: View {
    
    var audioRecordingManager: AudioRecordingManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Transcription")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                
                VStack {
                    if audioRecordingManager.isTranscribing {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Transcribing...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = audioRecordingManager.transcriptionError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.body)
                            .padding()
                    } else {
                        if !audioRecordingManager.isRecording, let transcribedText = audioRecordingManager.transcribedText  {
                            if transcribedText == "" {
                                Text("No speech detected")
                                    .foregroundColor(.secondary)
                                    .font(.body)
                                    .padding()
                            } else {
                                Text(transcribedText)
                                    .font(.body)
                                    .padding()
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    
                    
                }
            }
            .frame(height: 120)
        }
    }
    
}

