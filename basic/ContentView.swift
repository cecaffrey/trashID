import SwiftUI
import UIKit
import CoreML
import Vision
import CoreImage
import Foundation
import Combine
import LLM


// MARK: - Color Theme
extension Color {
    static let appBackground = Color(red: 0.07, green: 0.09, blue: 0.10)
    static let cardBackground = Color(red: 0.12, green: 0.14, blue: 0.16)
    static let accentGreen = Color(red: 0.22, green: 0.85, blue: 0.52)
    static let softWhite = Color(red: 0.92, green: 0.93, blue: 0.94)
    static let mutedGray = Color(red: 0.45, green: 0.50, blue: 0.55)
}

// MARK: - Content View
struct ContentView: View {
    @State private var image: UIImage?
    @State private var showCamera = false
    @State private var savedImages: [UIImage] = []
    @State private var predictionText = ""
    @State private var Response = ""
    @State private var isAnalyzing = false
    @State private var showSheet = false

    let classLabels = ["glass", "paper", "cardboard", "plastic", "metal", "trash"]

    func iconFor(_ label: String) -> String {
        switch label {
        case "glass":     return "🫙"
        case "paper":     return "📄"
        case "cardboard": return "📦"
        case "plastic":   return "🧴"
        case "metal":     return "🥫"
        default:          return "🗑️"
        }
    }

    func binColorFor(_ label: String) -> Color {
        switch label {
        case "glass":     return Color(red: 0.2, green: 0.7, blue: 0.3)
        case "paper":     return Color(red: 0.2, green: 0.4, blue: 0.9)
        case "cardboard": return Color(red: 0.2, green: 0.4, blue: 0.9)
        case "plastic":   return Color(red: 1.0, green: 0.8, blue: 0.1)
        case "metal":     return Color(red: 1.0, green: 0.8, blue: 0.1)
        default:          return Color(red: 0.5, green: 0.5, blue: 0.5)
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Header
                VStack(spacing: 4) {
                    Text("TRASHID")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .tracking(6)
                        .foregroundColor(.accentGreen)

                    Text("Trash Classifier")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.softWhite)
                }
                .padding(.top, 56)
                .padding(.bottom, 32)

                // MARK: Image Preview Area
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(
                                    image != nil ? Color.accentGreen.opacity(0.5) : Color.mutedGray.opacity(0.2),
                                    lineWidth: 1.5
                                )
                        )

                    if let img = image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 48))
                                .foregroundColor(.mutedGray)
                            Text("Tap below to scan an item")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.mutedGray)
                        }
                    }

                    if isAnalyzing {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.black.opacity(0.6))
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.accentGreen)
                                .scaleEffect(1.4)
                            Text("Analyzing...")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.accentGreen)
                        }
                    }
                }
                .frame(height: 320)
                .padding(.horizontal, 20)
                // MARK: Result Card
                if !predictionText.isEmpty && !isAnalyzing {
                    let parts = predictionText.components(separatedBy: " ")
                    let label = parts.first ?? ""

                    HStack(spacing: 10) {
                        Text(iconFor(label))
                            .font(.system(size: 28))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("DETECTED")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .tracking(3)
                                .foregroundColor(.mutedGray)
                            Text(predictionText)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.softWhite)
                            Button("Show AI Response") {showSheet = true}
                        }
                        Spacer()

                        Circle()
                            .fill(binColorFor(label))
                            .frame(width: 14, height: 14)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.accentGreen.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                } else if predictionText.isEmpty && image != nil && !isAnalyzing {
                    Text("Nothing detected — try again")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.mutedGray)
                        .padding(.top, 20)
                }

                Spacer()

                // MARK: Bottom Buttons
                VStack(spacing: 12) {
                    Button(action: { showCamera = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Scan Item")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.appBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.accentGreen)
                        )
                    }

                    if image != nil {
                        Button(action: {
                            withAnimation(.spring()) {
                                image = nil
                                predictionText = ""
                            }
                        }) {
                            Text("Clear")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.mutedGray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.cardBackground)
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $image)
        }
        .sheet(isPresented: $showSheet) {
            Text(Response)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.black)
            .padding(.horizontal, 24)
        }
        .onChange(of: image) { newImage in
            if let img = newImage {
                Response = ""
                showSheet = false
                saveImageToDocuments(image: img)
                isAnalyzing = true
                predictionText = ""
                DispatchQueue.global(qos: .userInitiated).async {
                    runObjectDetection(on: img)
                    showSheet = true
                }
            }
        }
    }

    // MARK: - Object Detection
    func runObjectDetection(on image: UIImage) {
        guard let resized = resizeImage(image, to: CGSize(width: 320, height: 320)),
              let pixelBuffer = resized.toCVPixelBuffer() else {
            DispatchQueue.main.async { isAnalyzing = false; predictionText = "" }
            return
        }
        do {
            let model = try best(configuration: MLModelConfiguration())
            let output = try model.prediction(input: bestInput(image: pixelBuffer))
            parsePredictions(output.var_910)
        } catch {
            DispatchQueue.main.async {
                isAnalyzing = false
                predictionText = ""
            }
        }
    }

    func parsePredictions(_ output: MLMultiArray) {
        let numAnchors = output.shape[2].intValue
        var bestConfidence: Float = 0.5
        var bestLabel = ""

        for a in 0..<numAnchors {
            for c in 0..<classLabels.count {
                let idx = (4 + c) * numAnchors + a
                let score = output[idx].floatValue
                if score > bestConfidence {
                    bestConfidence = score
                    bestLabel = classLabels[c]
                }
            }
        }

        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isAnalyzing = false
                predictionText = bestLabel.isEmpty ? "" : "\(bestLabel) (\(Int(bestConfidence * 100))%)"
            }
        }
        let llama = LlamaService()
        Task {
            let r = await llama.generate(prompt: "Explain how \(bestLabel) items should be disposed of. Do not give an introduction. Be vague and general in your response. Keep your response below 200 words.")
            Response = r
        }
    }
}

// MARK: - Image Resize Helper
func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
    image.draw(in: CGRect(origin: .zero, size: size))
    let resized = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return resized
}

// MARK: - UIImage → CVPixelBuffer
extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width), Int(size.height),
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        let ctx = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width), height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        )
        ctx?.draw(cgImage!, in: CGRect(origin: .zero, size: size))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { parent.image = img }
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Save / Load Images
func saveImageToDocuments(image: UIImage) {
    guard let data = image.jpegData(compressionQuality: 0.9) else { return }
    let filename = UUID().uuidString + ".jpg"
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(filename)
    try? data.write(to: url)
}

func loadImages() -> [UIImage] {
    let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    guard let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else { return [] }
    return files.compactMap { UIImage(contentsOfFile: $0.path) }
}

// MARK: - LlamaService
class LlamaService: ObservableObject {
    @Published var response: String = ""
    @Published var isGenerating: Bool = false
    @Published var modelLoaded: Bool = false

    private var llm: LLM?

    init() {
        loadModel()
    }

    private func loadModel() {
        // Make sure your .gguf file is added to your Xcode target
        // Change "your-model" to your actual filename without the extension
        guard let modelURL = Bundle.main.url(forResource: "tinyllama-1.1b-chat-v1.0.Q8_0", withExtension: "gguf") else {
            print("❌ Model file not found — make sure your .gguf is added to the Xcode target")
            return
        }

        llm = LLM(from: modelURL, maxTokenCount: 600)
        
        DispatchQueue.main.async { self.modelLoaded = true }
        print("✅ Model loaded successfully")
    }

    func generate(prompt: String) async -> String {
        guard let llm else { return "error loading llm" }
        let formatted = "<|im_start>system\nWhen given a material, respond in the following manner: [BIN]: provide a brief explanation on which bin it should go in, [HOW]: provide brief instruction on how to prepare the material for disposal, [TIP]: provide one useful tip. Keep your response as short as possible. Do not mention any other material. Do not go off topic. Keep your response below 200 words. <|im_start|>user\n\(prompt)<|im_end|>\n<|im_start|>assistant\n"
        await llm.respond(to: formatted)
        return llm.output  // full string is here after await completes
    }
}
