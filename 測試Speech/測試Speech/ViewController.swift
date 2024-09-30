//
//  ViewController.swift
//  測試Speech
//
//  Created by Yin Bob on 2024/9/27.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    let button: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("點擊開始講話", for: .normal)
        btn.addTarget(self, action: #selector(startListening), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    let textView:UITextView = {
        let textView = UITextView()
        textView.font = UIFont(name: "HelveticaNeue-Bold", size: 18)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    // 建立了一個 SFSpeechRecognizer 物件，並指定其 locale identifier 為 en-US，也就是通知語音識別器用戶所使用的語言。這個對象將用於語音識別。
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-TW"))
    
    // 物件負責發起語音識別請求。它為語音識別器指定一個音頻輸入源。
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    // 這個物件用於保存發起語音識別請求后的返回值。通過這個物件，你可以取消或中止當前的語音識別任務。
    var recognitionTask: SFSpeechRecognitionTask?
    
    // 這個物件引用了語音引擎。它負責提供錄音輸入。
    let audioEngine = AVAudioEngine()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // 檢查語音識別可用性
        speechRecognizer?.delegate = self
        
        // MARK: SFSpeechRecognizerDelegate 方法
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.button.isEnabled = true
                default:
                    self.button.isEnabled = false
                    self.textView.text = "語音識別權限被拒絕"
                }
            }
        }
    }
    
    func setupUI() {
        view.backgroundColor = .white
        
        // 設置按鈕
        view.addSubview(button)
        
        // 設置TextView來顯示語音識別結果
        view.addSubview(textView)
        
        // AutoLayout
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -20)
        ])
    }

    // 點擊按鈕
    @objc func startListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            button.setTitle("點擊開始講話", for: .normal)
        } else {
            startRecording()
            button.setTitle("停止講話", for: .normal)
        }
    }
}

extension ViewController {
    
    // 點擊按鈕如果目前不是錄音狀態，開始錄音執行這段程式碼
    func startRecording() {
        // 如果已有語音識別任務，先取消
        recognitionTask?.cancel()
        recognitionTask = nil

        // 設置音頻會話
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try! audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else { fatalError("不能創建請求") }
        recognitionRequest.shouldReportPartialResults = true

        // 開始識別語音
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { result, error in
            if let result = result {
                // 顯示語音識別的結果
                self.textView.text = result.bestTranscription.formattedString
            }

            if error != nil || result?.isFinal == true {
                // 停止錄音
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.button.setTitle("點擊開始講話", for: .normal)
            }
        })

        // 設置音頻輸入
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }

        // 啟動音頻引擎
        audioEngine.prepare()
        try! audioEngine.start()

        textView.text = "請開始講話..."
    }
    
}

