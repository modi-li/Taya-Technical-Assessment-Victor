# Taya Technical Assessment

Name: Modi (Victor) Li

[Loop Video](https://www.loom.com/share/cbf0ad1651b34eeb97f1d63a80b55447)

Note: Enter your OpenAI API key in [Secrets.swift](Taya-Prototype-Victor/Taya-Prototype-Victor/Secrets.swift) before running the app.

## Storage: SwiftData

I chose SwiftData because it's the latest modern technology for storing persistent data locally in a native iOS app and it supports Swift's modern concurrency features.

## How I handled the SwiftUI transition from "Recording" to "Result"

1. Recording ends
2. The transcription view shows
   - displays a loading progress view when transcribing
3. The memory card view shows
   - displays a loading progress view when analyzing the transcription (OpenAI API call)

## AI Workflow

I used Cursor for generating and refactoring code and use Xcode for building and running the app.

## How I handled noise in the transcripts with prompts?

Here are the system and user prompts I used for calling OpenAI's API:

### System prompt:

```
You are an assistant that analyzes voice transcriptions and extracts structured information.

The transcription may contain filler words (um, uh, like), repetitions, or minor transcription errors. Filter these out and focus on the actual message.

IMPORTANT: Short or simple messages like "Hello", "Thanks", or "Buy milk" are VALID content, not noise. Only treat transcriptions as unclear if they contain actual nonsensical text that has no recognizable words or meaning.

Respond with JSON only.
```

### User prompt:

```
Analyze this voice transcription and extract:
- A short poetic title summarizing the content
- A category (Shopping, Learning, Meeting, Personal, Work, Health, Travel, Entertainment)
- Action items as specific tasks (only include clear, actionable items). If no action items are found, return an empty array.
- Overall mood/sentiment

Transcription: \(transcribedText)
```

Model used: GPT-4o-mini
