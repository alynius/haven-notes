import Foundation
import Speech
import AVFoundation

@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var isAvailable: Bool = false
    @Published var errorMessage: String?

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        isAvailable = speechRecognizer?.isAvailable ?? false
    }

    func requestPermission() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            errorMessage = "Speech recognition not authorized"
            return false
        }

        let audioStatus: Bool
        #if os(iOS)
        if #available(iOS 17.0, *) {
            audioStatus = await AVAudioApplication.requestRecordPermission()
        } else {
            audioStatus = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
        #else
        audioStatus = await AVCaptureDevice.requestAccess(for: .audio)
        #endif

        guard audioStatus else {
            errorMessage = "Microphone access not granted"
            return false
        }

        return true
    }

    func startRecording() async {
        guard await requestPermission() else { return }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition unavailable"
            return
        }

        stopRecording()

        do {
            #if os(iOS)
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            #endif

            let audioEngine = AVAudioEngine()
            self.audioEngine = audioEngine

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true

            if speechRecognizer.supportsOnDeviceRecognition {
                request.requiresOnDeviceRecognition = true
            }

            self.recognitionRequest = request

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            guard recordingFormat.channelCount > 0 else {
                errorMessage = "No microphone available"
                return
            }

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            isRecording = true
            transcript = ""

            recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }

                    if let result = result {
                        self.transcript = result.bestTranscription.formattedString
                    }

                    if error != nil || (result?.isFinal ?? false) {
                        self.stopRecording()
                    }
                }
            }

        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            stopRecording()
        }
    }

    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }

    func toggleRecording() async {
        if isRecording {
            stopRecording()
        } else {
            await startRecording()
        }
    }
}
