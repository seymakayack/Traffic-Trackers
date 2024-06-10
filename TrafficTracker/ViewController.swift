import UIKit
import CoreML
import Vision
import AVKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var trafficGuide: UILabel!
    @IBOutlet weak var trafficTracker: UILabel!
    @IBOutlet weak var openGalleryButton: UIButton!
    @IBOutlet weak var yourVoice: UILabel!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    let synthesizer = AVSpeechSynthesizer()
    
    let classLabels = ["Green Light", "Red Light", "Speed Limit 10", "Speed Limit 100", "Speed Limit 110", "Speed Limit 120", "Speed Limit 20", "Speed Limit 30", "Speed Limit 40", "Speed Limit 50", "Speed Limit 60","Speed Limit 60", "Speed Limit 70", "Speed Limit 80", "Speed Limit 90", "Stop"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        openGalleryButton.layer.cornerRadius = 12
        
        // Set up the background image view
        let backgroundImageView = UIImageView(frame: self.view.bounds)
        backgroundImageView.image = UIImage(named: "road") // Use the correct background image name from your assets
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.alpha = 0.5
        
        // Insert the image view at the bottom
        self.view.insertSubview(backgroundImageView, at: 0)
        
        // Add constraints to make sure the background image view covers the entire view
        NSLayoutConstraint.activate([
            backgroundImageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            backgroundImageView.topAnchor.constraint(equalTo: self.view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    @IBAction func voice(_ sender: UIButton) {
        let utterance = AVSpeechUtterance(string: "Hello")
        utterance.rate = 0.52
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
    
    @IBAction func openGalleryButton(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = selectedImage
            detectTrafficSign(in: selectedImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func detectTrafficSign(in image: UIImage) {
        guard let model = try? VNCoreMLModel(for: best2().model) else {
            print("Model yüklenemedi.")
            return
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            if let error = error {
                print("Model isteği sırasında hata: \(error.localizedDescription)")
                return
            }
            self?.processClassifications(for: request, in: image)
        }
        
        guard let ciImage = CIImage(image: image) else {
            print("Görüntü CIImage formatına dönüştürülemedi.")
            return
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Görüntü istekleri gerçekleştirilemedi: \(error.localizedDescription)")
            }
        }
    }
    
    func processClassifications(for request: VNRequest, in image: UIImage) {
        DispatchQueue.main.async {
            guard let results = request.results as? [VNCoreMLFeatureValueObservation],
                  let multiArray = results.first?.featureValue.multiArrayValue else {
                print("Hiçbir sonuç bulunamadı: \(request.results.debugDescription)")
                return
            }
            
            let pointer = UnsafeMutablePointer<Float32>(OpaquePointer(multiArray.dataPointer))
            let boundingBoxCount = multiArray.shape[1].intValue
            let elementStride = multiArray.strides[1].intValue
            
            var detectedObjects: [(CGRect, String, Float32)] = []
            
            for i in 0..<boundingBoxCount {
                let base = i * elementStride
                let confidence = pointer[base + 4]
                
                if confidence > 0.5 { // Güven eşik değeri
                    let x = pointer[base]
                    let y = pointer[base + 1]
                    let width = pointer[base + 2]
                    let height = pointer[base + 3]
                    
                    let boundingBox = CGRect(x: CGFloat(x - width / 2), y: CGFloat(y - height / 2), width: CGFloat(width), height: CGFloat(height))
                    
                    // En yüksek güvene sahip sınıfı bulma
                    var maxConfidence: Float32 = 0.0
                    var classIndex = 0
                    for j in 5..<elementStride {
                        let classConfidence = pointer[base + j]
                        if classConfidence > maxConfidence {
                            maxConfidence = classConfidence
                            classIndex = j - 5
                        }
                    }
                    
                    let className = self.classLabels[classIndex]
                    
                    detectedObjects.append((boundingBox, className, maxConfidence))
                }
            }
            
            self.showDetectedObjects(detectedObjects, in: image)
        }
    }
    
    func showDetectedObjects(_ objects: [(CGRect, String, Float32)], in image: UIImage) {
        let imageSize = image.size
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
        image.draw(at: CGPoint.zero)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            print("Çizim bağlamı oluşturulamadı.")
            return
        }
        
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(2.0)
        
        var detectedSignNames: [String] = []
        
        for (boundingBox, className, confidence) in objects {
            let rect = CGRect(x: boundingBox.minX * imageSize.width,
                              y: (1 - boundingBox.maxY) * imageSize.height,
                              width: boundingBox.width * imageSize.width,
                              height: boundingBox.height * imageSize.height)
            context.stroke(rect)
            
            if let classIndex = classLabels.firstIndex(of: className) {
                let detectedSign = "Tespit edilen trafik işareti: Class \(classIndex + 1) - \(className) - Güven: \(confidence)"
                print(detectedSign)
                detectedSignNames.append(className)
            }
        }
        
        let annotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.imageView.image = annotatedImage
        
        if !detectedSignNames.isEmpty {
            let randomIndex = Int(arc4random_uniform(UInt32(detectedSignNames.count)))
            let randomDetectedSignName = detectedSignNames[randomIndex]
            self.label.text = randomDetectedSignName
            
            // Text-to-Speech
            let utterance = AVSpeechUtterance(string: randomDetectedSignName)
            utterance.rate = 0.52
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            synthesizer.speak(utterance)
        }
    }
}
