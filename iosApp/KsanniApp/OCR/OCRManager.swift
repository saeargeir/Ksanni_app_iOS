import Foundation
import Vision
import VisionKit
import UIKit

// MARK: - OCR Manager

class OCRManager: ObservableObject {
    static let shared = OCRManager()
    
    private init() {}
    
    // MARK: - Main OCR Functions
    
    func recognizeText(from image: UIImage, completion: @escaping (OCRResult) -> Void) {
        let startTime = Date()
        
        guard let cgImage = image.cgImage else {
            completion(OCRResult(
                recognizedText: "",
                confidence: 0.0,
                engine: .vision,
                success: false,
                error: "Failed to process image"
            ))
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)
            
            if let error = error {
                completion(OCRResult(
                    recognizedText: "",
                    confidence: 0.0,
                    engine: .vision,
                    processingTimeMs: processingTime,
                    success: false,
                    error: error.localizedDescription
                ))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(OCRResult(
                    recognizedText: "",
                    confidence: 0.0,
                    engine: .vision,
                    processingTimeMs: processingTime,
                    success: false,
                    error: "No text recognized"
                ))
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            let fullText = recognizedStrings.joined(separator: "\n")
            let avgConfidence = observations.compactMap { observation in
                observation.topCandidates(1).first?.confidence
            }.reduce(0, +) / Float(max(observations.count, 1))
            
            completion(OCRResult(
                recognizedText: fullText,
                confidence: avgConfidence,
                engine: .vision,
                processingTimeMs: processingTime,
                success: true,
                error: nil
            ))
        }
        
        // Configure for best accuracy
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US", "is-IS"] // English and Icelandic
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)
                completion(OCRResult(
                    recognizedText: "",
                    confidence: 0.0,
                    engine: .vision,
                    processingTimeMs: processingTime,
                    success: false,
                    error: error.localizedDescription
                ))
            }
        }
    }
    
    // MARK: - Document Scanner Support (iOS 13+)
    
    @available(iOS 13.0, *)
    func createDocumentScannerViewController(completion: @escaping (OCRResult) -> Void) -> VNDocumentCameraViewController? {
        guard VNDocumentCameraViewController.isSupported else {
            completion(OCRResult(
                recognizedText: "",
                confidence: 0.0,
                engine: .documentScanner,
                success: false,
                error: "Document scanner not supported on this device"
            ))
            return nil
        }
        
        let scannerViewController = VNDocumentCameraViewController()
        // We'll handle the delegate in the coordinator
        return scannerViewController
    }
    
    // MARK: - Hybrid OCR Processing
    
    func processImageWithHybridOCR(image: UIImage, completion: @escaping (OCRResult) -> Void) {
        // Primary: Use Vision framework
        recognizeText(from: image) { visionResult in
            if visionResult.success && visionResult.confidence > 0.7 {
                // If Vision works well, use it
                completion(OCRResult(
                    recognizedText: visionResult.recognizedText,
                    confidence: visionResult.confidence,
                    engine: .hybrid,
                    processingTimeMs: visionResult.processingTimeMs,
                    success: true,
                    error: nil
                ))
            } else {
                // Fallback to enhanced processing
                self.processWithEnhancedVision(image: image, completion: completion)
            }
        }
    }
    
    private func processWithEnhancedVision(image: UIImage, completion: @escaping (OCRResult) -> Void) {
        // Preprocess image for better OCR
        let enhancedImage = preprocessImageForOCR(image)
        
        recognizeText(from: enhancedImage) { result in
            completion(OCRResult(
                recognizedText: result.recognizedText,
                confidence: result.confidence,
                engine: .hybrid,
                processingTimeMs: result.processingTimeMs,
                success: result.success,
                error: result.error
            ))
        }
    }
    
    // MARK: - Image Preprocessing
    
    private func preprocessImageForOCR(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let context = CIContext()
        
        // Apply filters to enhance text recognition
        var processedImage = ciImage
        
        // 1. Convert to grayscale
        if let grayscaleFilter = CIFilter(name: "CIColorControls") {
            grayscaleFilter.setValue(processedImage, forKey: kCIInputImageKey)
            grayscaleFilter.setValue(0.0, forKey: kCIInputSaturationKey) // Remove color
            if let output = grayscaleFilter.outputImage {
                processedImage = output
            }
        }
        
        // 2. Enhance contrast
        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(processedImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(1.5, forKey: kCIInputContrastKey) // Increase contrast
            if let output = contrastFilter.outputImage {
                processedImage = output
            }
        }
        
        // 3. Sharpen
        if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(processedImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.7, forKey: kCIInputSharpnessKey)
            if let output = sharpenFilter.outputImage {
                processedImage = output
            }
        }
        
        // Convert back to UIImage
        if let cgImage = context.createCGImage(processedImage, from: processedImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return image
    }
}

// MARK: - Document Scanner Coordinator (iOS 13+)

@available(iOS 13.0, *)
class DocumentScannerCoordinator: NSObject, VNDocumentCameraViewControllerDelegate {
    private let completion: (OCRResult) -> Void
    
    init(completion: @escaping (OCRResult) -> Void) {
        self.completion = completion
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        controller.dismiss(animated: true)
        
        // Process all scanned pages
        var allText = ""
        let group = DispatchGroup()
        
        for pageIndex in 0..<scan.pageCount {
            group.enter()
            let image = scan.imageOfPage(at: pageIndex)
            
            OCRManager.shared.recognizeText(from: image) { result in
                if result.success {
                    allText += result.recognizedText + "\n\n"
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.completion(OCRResult(
                recognizedText: allText.trimmingCharacters(in: .whitespacesAndNewlines),
                confidence: 0.9,
                engine: .documentScanner,
                success: true,
                error: nil
            ))
        }
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        controller.dismiss(animated: true)
        
        completion(OCRResult(
            recognizedText: "",
            confidence: 0.0,
            engine: .documentScanner,
            success: false,
            error: error.localizedDescription
        ))
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
        
        completion(OCRResult(
            recognizedText: "",
            confidence: 0.0,
            engine: .documentScanner,
            success: false,
            error: "User cancelled scanning"
        ))
    }
}