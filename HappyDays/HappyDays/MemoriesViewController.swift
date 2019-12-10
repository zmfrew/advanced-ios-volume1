import AVFoundation
import Photos
import Speech
import CoreSpotlight
import MobileCoreServices
import UIKit

class MemoriesViewController: UICollectionViewController {
    private var activeMemory: URL!
    private var audioPlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    private var filteredMemories: [URL] = []
    private var memories: [URL] = []
    private var recordingURL: URL!
    private var searchQuery: CSSearchQuery?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadMemories()
        checkPermissions()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        recordingURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
    }
    
    @objc func addTapped() {
        let picker = UIImagePickerController()
        picker.modalPresentationStyle = .formSheet
        picker.delegate = self
        navigationController?.present(picker, animated: true)
    }
    
    @objc func memoryLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let cell = sender.view as! MemoryCell
            
            if let index = collectionView?.indexPath(for: cell) {
                activeMemory = filteredMemories[index.row]
            } else if sender.state == .ended {
                finishRecording(success: true)
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Memory", for: indexPath) as! MemoryCell
        
        let memory = filteredMemories[indexPath.row]
        let imageName = thumbnailURL(for: memory).path
        let image = UIImage(contentsOfFile: imageName)
        cell.configure(image)
        
        if cell.gestureRecognizers == nil {
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(memoryLongPress))
            cell.addGestureRecognizer(recognizer)
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let memory = filteredMemories[indexPath.row]
        let fm = FileManager.default
        
        do {
            let audioName = audioURL(for: memory)
            let transcriptionName = transcriptionURL(for: memory)
            
            if fm.fileExists(atPath: audioName.path) {
                audioPlayer = try AVAudioPlayer(contentsOf: audioName)
                audioPlayer?.play()
            }
            
            if fm.fileExists(atPath: transcriptionName.path) {
                let contents = try String(contentsOf: transcriptionName)
                print(contents)
            }
        } catch {
            print("Error loading audio: \(error.localizedDescription)")
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        } else {
            return filteredMemories.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
}

extension MemoriesViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterMemories(text: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func activateFilter(matches: [CSSearchableItem]) {
        filteredMemories = matches.map { URL(fileURLWithPath: $0.uniqueIdentifier) }
        
        UIView.performWithoutAnimation {
            collectionView?.reloadSections(IndexSet(integer: 1))
        }
    }
    
    func filterMemories(text: String) {
        guard text.count > 0 else {
            filteredMemories = memories
            
            UIView.performWithoutAnimation {
                collectionView?.reloadSections(IndexSet(integer: 1))
            }
            
            return
        }
        
        var allItems: [CSSearchableItem] = []
        
        searchQuery?.cancel()
        let queryString = "contentDescription == \"*\(text)*\"c"
        searchQuery = CSSearchQuery(queryString: queryString, attributes: nil)
        
        searchQuery?.foundItemsHandler = { items in
            allItems.append(contentsOf: items)
        }
        
        searchQuery?.completionHandler = { error in
            DispatchQueue.main.async { [unowned self] in
                self.activateFilter(matches: allItems)
            }
        }
        
        searchQuery?.start()
    }
}

extension MemoriesViewController {
    private func audioURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("m4a")
    }
    
    private func checkPermissions() {
        let photosAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted
        let transcribeAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        let authorized = photosAuthorized && recordingAuthorized && transcribeAuthorized
        
        if authorized == false {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "FirstRun") {
                navigationController?.present(vc, animated: true)
            }
        }
    }
    
    func finishRecording(success: Bool) {
        collectionView.backgroundColor = .darkGray
        audioRecorder?.stop()
        
        if success {
            do {
                let memoryAudioURL = activeMemory.appendingPathExtension("m4a")
                let fm = FileManager.default
                if fm.fileExists(atPath: memoryAudioURL.path) {
                    try fm.removeItem(at: memoryAudioURL)
                }
                
                try fm.moveItem(at: recordingURL, to: memoryAudioURL)
                transcribeAudio(memory: activeMemory)
            } catch {
                print("Failure finishing recording: \(error)")
            }
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func imageURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("jpg")
    }
    
    private func indexMemory(memory: URL, text: String) {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = "Happy Days Memory"
        attributeSet.contentDescription = text
        attributeSet.thumbnailURL = thumbnailURL(for: memory)
        
        let item = CSSearchableItem(uniqueIdentifier: memory.path, domainIdentifier: "com.zachfrew", attributeSet: attributeSet)
        
        item.expirationDate = Date.distantFuture
        
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                print("Indexing error: \(error.localizedDescription)")
            } else {
                print("Search item successfully indexed: \(text)")
            }
        }
    }
    
    private func loadMemories() {
        memories.removeAll()
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else { return }
        
        for file in files {
            let filename = file.lastPathComponent
            if filename.hasSuffix(".thumb") {
                let noExtension = filename.replacingOccurrences(of: ".thumb", with: "")
                let memoryPath = getDocumentsDirectory().appendingPathComponent(noExtension)
                memories.append(memoryPath)
            }
        }
        
        collectionView?.reloadSections(IndexSet(integer: 1))
    }
    
    private func recordMemory() {
        audioPlayer?.stop()
        collectionView.backgroundColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1)
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try recordingSession.setActive(true)
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch {
            print("Failed to record: \(error)")
            finishRecording(success: false)
        }
    }
    
    private func resize(image: UIImage, to width: CGFloat) -> UIImage? {
        let scale = width / image.size.width
        let height = image.size.height * scale
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    private func saveNewMemory(image: UIImage) {
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        let imageName = memoryName + ".jpg"
        let thumbnailName = memoryName + ".thumb"
        
        do {
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
            if let jpegData = image.jpegData(compressionQuality: 0.8) {
                try jpegData.write(to: imagePath, options: [.atomicWrite])
                
                if let thumbnail = resize(image: image, to: 200) {
                    let imagePath = getDocumentsDirectory().appendingPathComponent(thumbnailName)
                    if let jpegData = thumbnail.jpegData(compressionQuality: 0.8) {
                        try jpegData.write(to: imagePath, options: [.atomicWrite])
                    }
                }
            }
        } catch {
                print("Failed to save image to disk: \(error.localizedDescription)")
        }
    }
    
    private func thumbnailURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("thumb")
    }
    
    func transcribeAudio(memory: URL) {
        let audio = audioURL(for: memory)
        let transcription = transcriptionURL(for: memory)
        
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audio)
        
        recognizer?.recognitionTask(with: request) { [unowned self] (result, error) in
            guard let result = result else {
                print("There was an error: \(error!)")
                return
            }
            
            if result.isFinal {
                let text = result.bestTranscription.formattedString
                
                do {
                    try text.write(to: transcription, atomically: true, encoding: .utf8)
                    self.indexMemory(memory: memory, text: text)
                } catch {
                    print("Failed to save transcription.")
                }
            }
        }
    }
    
    private func transcriptionURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("txt")
    }
}

extension MemoriesViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}

extension MemoriesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 1 {
            return CGSize.zero
        } else {
            return CGSize(width: 0, height: 50)
        }
    }
}

extension MemoriesViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            saveNewMemory(image: image)
            loadMemories()
        }
    }
}

extension MemoriesViewController: UINavigationControllerDelegate {
    
}
