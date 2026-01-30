//
//  AudioRecordingManager.swift
//  Taya-Prototype-Victor
//
//  Created by Modi (Victor) Li.
//

import SwiftUI
import AVFoundation
import Speech
import DSWaveformImage
import DSWaveformImageViews

@MainActor
@Observable
class AudioRecordingManager {
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    var isRecording = false
    var audioSamples: [Float] = []
    var currentRecordingURL: URL?
    var currentTime: TimeInterval = 0
    var transcribedText: String?
    var isTranscribing = false
    var transcriptionSuccess = false
    var transcriptionError: String?
    
    var currentAnalysis: TranscriptionAnalysis?
    var analysisComplete = false
    var analysisError: String?
    
    private let maxSamples = 100
    
    init() {
        setupAudioSession()
        requestSpeechRecognitionPermission()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func requestSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Speech recognition authorized")
            case .denied:
                print("Speech recognition denied")
            case .restricted:
                print("Speech recognition restricted")
            case .notDetermined:
                print("Speech recognition not determined")
            @unknown default:
                print("Unknown authorization status")
            }
        }
    }
    
    func startRecording() {
        reset()
                
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        let fileURL = tempDir.appendingPathComponent(fileName)
        currentRecordingURL = fileURL
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            isRecording = true
            currentTime = 0
            audioSamples = Array(repeating: 0, count: maxSamples)
            
            // Start metering timer for real-time updates
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                Task { @MainActor [weak self] in
                    self?.updateMetering()
                }
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        
        // Start transcription after recording stops
        if let url = currentRecordingURL {
            transcribeAudio(url: url)
        }
    }
    
    private func updateMetering() {
        guard let recorder = audioRecorder else { return }
        
        recorder.updateMeters()
        currentTime = recorder.currentTime
        
        // Get the power level (in decibels)
        let power = recorder.averagePower(forChannel: 0)
        
        // Convert decibels to normalized value (0.0 to 1.0)
        // -160 dB is effectively silence, 0 dB is max
        let normalizedValue = pow(10, power / 20)
        
        // Add to samples array and maintain fixed size
        audioSamples.append(normalizedValue)
        if audioSamples.count > maxSamples {
            audioSamples.removeFirst()
        }
    }
    
    private func transcribeAudio(url: URL) {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            transcriptionError = "Speech recognition is not available"
            return
        }
        
        isTranscribing = true
        transcribedText = ""
        transcriptionError = nil
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation
        
        recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let error = error {
                    self.transcriptionError = "Transcription failed: \(error.localizedDescription)"
                    self.isTranscribing = false
                    return
                }
                
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        self.isTranscribing = false
                        self.transcriptionSuccess = true
                    }
                }
            }
        }
    }
    
    var isAnalyzing = false
    
    func analyzeWithLLM() {
        
        guard let transcribedText, !transcribedText.isEmpty else {
            return
        }
        
        isAnalyzing = true
        currentAnalysis = nil
        analysisComplete = false
        analysisError = nil
        
        APICall(apiItem: OpenAITranscriptionAnalysisAPI(), requestData: .init(transcribedText: transcribedText))
            .onSuccess { [weak self] response in
                guard let self else { return }
                
                if let jsonText = response.output.first?.content.first?.text,
                   let jsonData = jsonText.data(using: .utf8) {
                    do {
                        let analysis = try JSONDecoder().decode(TranscriptionAnalysis.self, from: jsonData)
                        self.currentAnalysis = analysis
                        self.analysisComplete = true
                    } catch {
                        self.analysisError = "Failed to parse analysis: \(error.localizedDescription)"
                    }
                } else {
                    self.analysisError = "Failed to get analysis response"
                }
                self.isAnalyzing = false
            }
            .onError { [weak self] error in
                self?.analysisError = "Analysis failed: \(error)"
                self?.isAnalyzing = false
            }
            .execute()
    }
    
    func reset() {
        transcribedText = ""
        transcriptionSuccess = false
        transcriptionError = nil
        currentAnalysis = nil
        analysisComplete = false
        analysisError = nil
        audioSamples = []
        currentTime = 0
    }
    
}
