//
//  AudioFeedback.swift
//  RetroAccess App
//
//  Created by Xia Su on 11/28/23.
//

import Foundation
//import Speech
import ARKit
enum AudioFeedbackType{
    case scanSuggestion, detectedObject,detectedIssue,issueDetails
}

class AudioFeedback{
    let content:String
    let type:AudioFeedbackType
    let uploadTime:Date
    let waitTimeDict=[AudioFeedbackType.scanSuggestion:2,
                      AudioFeedbackType.detectedObject:2.5,
                      AudioFeedbackType.detectedIssue:5,
                      AudioFeedbackType.issueDetails:1]
    var issue:AccessibilityIssue?
    public init(content: String, type: AudioFeedbackType, uploadTime: Date, issue:AccessibilityIssue?) {
        self.content = content
        self.type = type
        self.uploadTime = uploadTime
        self.issue=issue
    }
}
extension ViewController{
//     func requestSpeechAuthorization() {
//            SFSpeechRecognizer.requestAuthorization { authStatus in
//                DispatchQueue.main.async {
//                    switch authStatus {
//                    case .authorized:
//                        // User granted permission, start recognition
//                        self.speechAuthorized=true
//                        self.speak(content: "Audio assistance on. You will be hinted with scanning suggestions, detected objects and issues. For all issues, you can speak tell me more to hear about details.")
//                        self.initVoiceRecognition()
//                        
//                    case .denied, .restricted, .notDetermined:
//                        // Handle the case where user did not grant permission
//                        self.speak(content: "Failed to gain speech recognition permission. RASSAR will still give audio feedback but not taking voice commands.")
//                    @unknown default:
//                        break
//                    }
//                }
//            }
//        }
//    private func initVoiceRecognition() {
//            do {
//                try startAudioSession()
//            } catch {
//                // Handle errors (e.g., audio session could not be started)
//                self.speak(content: "Voice recognition failed.")
//            }
//        }
//    private func startAudioSession() throws {
//            let audioSession = AVAudioSession.sharedInstance()
//            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
//            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//        }
    
    func enqueueAudio(audioFeedback:AudioFeedback){
        //Queue the audio at end of queue
        if Settings.instance.BLVAssistance{
            audioQueue.append(audioFeedback)
            print("Enqueued "+audioFeedback.content)
            processNextUtterance()
        }
        
    }
    func enqueueAudioAsNext(audioFeedback:AudioFeedback){
        //Queue the audio next
        if Settings.instance.BLVAssistance{
            audioQueue.insert(audioFeedback, at: 0)
            processNextUtterance()
        }
    }
    public func speak(content:String){
        if Settings.instance.BLVAssistance{
            let utterance = AVSpeechUtterance(string: content)
            // Configure the utterance.
            utterance.rate = 0.57
            utterance.pitchMultiplier = 0.8
            utterance.postUtteranceDelay = 0.2
            utterance.volume = 0.8
            // Assign the voice to the utterance.
            utterance.voice = self.assistiveVoice
            voiceSynthesizer?.speak(utterance)
        }
    }
    func processNextUtterance() {
        guard !voiceSynthesizer!.isSpeaking, !audioQueue.isEmpty else { return }
            
            let currentTime = Date()
            let nextAudio = audioQueue.removeFirst()

            // Check if the utterance has timed out
        if currentTime.timeIntervalSince(nextAudio.uploadTime) <= Double(nextAudio.waitTimeDict[nextAudio.type]!){
            switch nextAudio.type {
            case .scanSuggestion:
                speak(content:nextAudio.content)
            case .detectedObject:
                speak(content:nextAudio.content)
            case .detectedIssue:
                speak(content:nextAudio.content)
                //enqueueAudioAsNext(audioFeedback: AudioFeedback(content: nextAudio.issue!.getDetails(), type: .issueDetails, uploadTime: Date(), issue: nextAudio.issue))
                //TODO: Add a audio feedback session after this
                //Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(stopVoiceRecognition), userInfo: nil, repeats: false)
                //try? startRecognition(audioFeedback: nextAudio)
                
            case .issueDetails:
                speak(content:nextAudio.content)
                //TODO: Add a audio feedback session after this
                //Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(stopVoiceRecognition), userInfo: nil, repeats: false)
                //try? startRecognition(audioFeedback: nextAudio)
                
            }
            
            } else {
                // Skip this utterance and try the next one
                processNextUtterance()
            }
        }
//    private func startRecognition(audioFeedback:AudioFeedback) throws {
//        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
//        AudioServicesPlaySystemSound (1113);//System sound for starting record
//        let inputNode = audioEngine.inputNode
//
//            guard let recognitionRequest = recognitionRequest else {
//                print("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
//                return
//            }
//
//            recognitionRequest.shouldReportPartialResults = true
//
//            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { [weak self] (result, error) in
//                if let result = result {
//                    let recognizedText = result.bestTranscription.formattedString
//                    // Do something with the recognized text
//                    switch audioFeedback.type{
//                    case .scanSuggestion:
//                        print("Unexpected situation! scan suggestion shouldn't be expecting voice command")
//                    case .detectedObject:
//                        print("Unexpected situation! detected object shouldn't be expecting voice command")
//                    case .detectedIssue:
//                        //Should be expecting "tell me more about it"
//                        if ["tell me more","tell me more about it"].contains(recognizedText.lowercased()){
//                            self!.stopVoiceRecognition()
//                            self!.enqueueAudioAsNext(audioFeedback: AudioFeedback(content: audioFeedback.issue!.getDetails(), type: .issueDetails, uploadTime: Date(), issue: audioFeedback.issue))
//                        }
//                    case .issueDetails:
//                        if ["remove","remove issue","remove this","remove this issue",
//                            "delete","delete issue","delete this","delete this issue"].contains(recognizedText.lowercased()){
//                            self!.stopVoiceRecognition()
//                            audioFeedback.issue?.cancel()
//                        }
//                    }
//                    print(recognizedText)
//                } else if let error = error {
//                    print("Error recognizing speech: \(error.localizedDescription)")
//                    return
//                }
//            })
//
//            let recordingFormat = inputNode.outputFormat(forBus: 0)
//            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
//                self.recognitionRequest?.append(buffer)
//            }
//
//            audioEngine.prepare()
//            try audioEngine.start()
//        }
//    @objc func stopVoiceRecognition() {
//        if recognitionTask != nil{
//            AudioServicesPlaySystemSound (1114);//System sound for stopping record
//                recognitionRequest?.endAudio()
//                recognitionRequest = nil
//                recognitionTask?.cancel()
//                recognitionTask = nil
//            }
//        }
}
extension ViewController: AVSpeechSynthesizerDelegate {
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        processNextUtterance()
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        processNextUtterance()
    }
}
