import SwiftUI
import VisionKit
import Firebase

struct ContentView: View {
    @EnvironmentObject var invoiceManager: InvoiceManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedTab = 0
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var showingDocumentScanner = false
    @State private var inputImage: UIImage?
    @State private var isProcessing = false
    @State private var ocrResult: OCRResult?
    @State private var parsedInvoice: InvoiceRecord?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home/Scan Tab
            ScanView(
                showingCamera: $showingCamera,
                showingImagePicker: $showingImagePicker,
                showingDocumentScanner: $showingDocumentScanner,
                inputImage: $inputImage,
                isProcessing: $isProcessing,
                ocrResult: $ocrResult,
                parsedInvoice: $parsedInvoice
            )
            .tabItem {
                Image(systemName: "camera.viewfinder")
                Text("Skanna")
            }
            .tag(0)
            
            // Invoices List Tab
            InvoiceListView()
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("Reikningar")
                }
                .tag(1)
            
            // Statistics Tab
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Tölfræði")
                }
                .tag(2)
            
            // Export Tab
            ExportView()
                .tabItem {
                    Image(systemName: "square.and.arrow.up")
                    Text("Útflutningur")
                }
                .tag(3)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Stillingar")
                }
                .tag(4)
        }
        .accentColor(.primary)
        .onChange(of: inputImage) { _ in
            if let image = inputImage {
                processImage(image)
            }
        }
        .alert("Villa", isPresented: $showingAlert) {
            Button("Í lagi", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .preferredColorScheme(themeManager.currentTheme == .dark ? .dark : 
                            themeManager.currentTheme == .light ? .light : nil)
    }
    
    private func processImage(_ image: UIImage) {
        isProcessing = true
        
        OCRManager.shared.processImageWithHybridOCR(image: image) { result in
            DispatchQueue.main.async {
                self.isProcessing = false
                self.ocrResult = result
                
                if result.success {
                    // Parse the invoice
                    if let invoice = InvoiceParser.parseInvoice(from: result.recognizedText) {
                        self.parsedInvoice = invoice
                        // Save to invoice manager
                        self.invoiceManager.addInvoice(invoice)
                    } else {
                        self.showAlert("Gat ekki greint reikningsupplýsingar úr textanum.")
                    }
                } else {
                    self.showAlert(result.error ?? "Óþekkt villa við textaþekkingu.")
                }
            }
        }
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Scan View

struct ScanView: View {
    @Binding var showingCamera: Bool
    @Binding var showingImagePicker: Bool
    @Binding var showingDocumentScanner: Bool
    @Binding var inputImage: UIImage?
    @Binding var isProcessing: Bool
    @Binding var ocrResult: OCRResult?
    @Binding var parsedInvoice: InvoiceRecord?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image("logo") // App logo
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .foregroundColor(.primary)
                    
                    Text("KsanniApp")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Íslenskur Reikningaskanni")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                Spacer()
                
                // Scan Options
                VStack(spacing: 16) {
                    // Camera Button
                    Button(action: {
                        showingCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            Text("Taka mynd")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Gallery Button
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                            Text("Velja úr myndasafni")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Document Scanner (iOS 13+)
                    if #available(iOS 13.0, *), VNDocumentCameraViewController.isSupported {
                        Button(action: {
                            showingDocumentScanner = true
                        }) {
                            HStack {
                                Image(systemName: "doc.text.viewfinder")
                                    .font(.title2)
                                Text("Skjala skanni")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Processing Indicator
                if isProcessing {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Vinnur úr mynd...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                // Results Preview
                if let result = ocrResult, !isProcessing {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Niðurstöður:")
                                    .font(.headline)
                                Spacer()
                                Text("Öryggi: \(Int(result.confidence * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let invoice = parsedInvoice {
                                InvoicePreviewCard(invoice: invoice)
                            } else {
                                Text(result.recognizedText)
                                    .font(.caption)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                    .frame(maxHeight: 200)
                }
                
                Spacer()
            }
            .navigationTitle("Skanna")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(image: $inputImage)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $inputImage)
        }
        .sheet(isPresented: $showingDocumentScanner) {
            if #available(iOS 13.0, *) {
                DocumentScannerView { result in
                    if result.success {
                        ocrResult = result
                        if let invoice = InvoiceParser.parseInvoice(from: result.recognizedText) {
                            parsedInvoice = invoice
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Invoice Preview Card

struct InvoicePreviewCard: View {
    let invoice: InvoiceRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(invoice.companyName)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let invoiceNumber = invoice.invoiceNumber {
                        Text("Reikningur #\(invoiceNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(invoice.totalAmount, format: .currency(code: invoice.currency))
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(invoice.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let vatAmount = invoice.vatAmount {
                HStack {
                    Text("VSK:")
                        .font(.caption)
                    Spacer()
                    Text(vatAmount, format: .currency(code: invoice.currency))
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: invoice.category.icon)
                    .foregroundColor(.accentColor)
                Text(invoice.category.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    ContentView()
        .environmentObject(InvoiceManager())
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
}