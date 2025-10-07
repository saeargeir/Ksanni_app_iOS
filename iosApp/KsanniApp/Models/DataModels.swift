import Foundation

// MARK: - Invoice Data Models

struct InvoiceRecord: Identifiable, Codable {
    let id = UUID()
    let companyName: String
    let invoiceNumber: String?
    let date: Date
    let subtotal: Double?
    let vatAmount: Double?
    let totalAmount: Double
    let currency: String
    let vatRates: [VATRate]
    let imagePath: String?
    let category: InvoiceCategory
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    
    init(companyName: String, 
         invoiceNumber: String? = nil,
         date: Date = Date(),
         subtotal: Double? = nil,
         vatAmount: Double? = nil, 
         totalAmount: Double,
         currency: String = "ISK",
         vatRates: [VATRate] = [],
         imagePath: String? = nil,
         category: InvoiceCategory = .other,
         notes: String? = nil) {
        
        self.companyName = companyName
        self.invoiceNumber = invoiceNumber
        self.date = date
        self.subtotal = subtotal
        self.vatAmount = vatAmount
        self.totalAmount = totalAmount
        self.currency = currency
        self.vatRates = vatRates
        self.imagePath = imagePath
        self.category = category
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct VATRate: Codable, Identifiable {
    let id = UUID()
    let rate: Double
    let amount: Double
    let currency: String
    
    init(rate: Double, amount: Double, currency: String = "ISK") {
        self.rate = rate
        self.amount = amount
        self.currency = currency
    }
}

enum InvoiceCategory: String, CaseIterable, Codable {
    case groceries = "groceries"
    case utilities = "utilities"
    case transportation = "transportation"
    case healthcare = "healthcare"
    case entertainment = "entertainment"
    case shopping = "shopping"
    case business = "business"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .groceries: return "Matvörur"
        case .utilities: return "Veitur"
        case .transportation: return "Samgöngur"
        case .healthcare: return "Heilbrigðisþjónusta"
        case .entertainment: return "Afþreying"
        case .shopping: return "Verslanir"
        case .business: return "Viðskipti"
        case .other: return "Annað"
        }
    }
    
    var icon: String {
        switch self {
        case .groceries: return "cart.fill"
        case .utilities: return "bolt.fill"
        case .transportation: return "car.fill"
        case .healthcare: return "cross.fill"
        case .entertainment: return "tv.fill"
        case .shopping: return "bag.fill"
        case .business: return "briefcase.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
}

// MARK: - OCR Result Models

struct OCRResult {
    let recognizedText: String
    let confidence: Float
    let engine: OCREngine
    let processingTimeMs: Int
    let success: Bool
    let error: String?
    
    init(recognizedText: String, confidence: Float = 0.8, engine: OCREngine = .vision, processingTimeMs: Int = 0, success: Bool = true, error: String? = nil) {
        self.recognizedText = recognizedText
        self.confidence = confidence
        self.engine = engine
        self.processingTimeMs = processingTimeMs
        self.success = success
        self.error = error
    }
}

enum OCREngine: String, CaseIterable {
    case vision = "Vision"
    case documentScanner = "DocumentScanner"
    case hybrid = "Hybrid"
    
    var displayName: String {
        switch self {
        case .vision: return "Apple Vision"
        case .documentScanner: return "Document Scanner"
        case .hybrid: return "Hybrid OCR"
        }
    }
}

// MARK: - Export Models

struct ExportResult {
    let success: Bool
    let filePath: String?
    let fileName: String?
    let error: String?
    
    static func success(filePath: String, fileName: String) -> ExportResult {
        return ExportResult(success: true, filePath: filePath, fileName: fileName, error: nil)
    }
    
    static func failure(error: String) -> ExportResult {
        return ExportResult(success: false, filePath: nil, fileName: nil, error: error)
    }
}

enum ExportFormat: String, CaseIterable {
    case csv = "csv"
    case excel = "xlsx"
    case pdf = "pdf"
    
    var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .excel: return "Excel"
        case .pdf: return "PDF"
        }
    }
    
    var fileExtension: String {
        return self.rawValue
    }
}

// MARK: - Currency and International Support

struct CurrencyAmount: Codable {
    let amount: Double
    let currency: String
    let confidence: Float
    
    init(amount: Double, currency: String = "ISK", confidence: Float = 0.8) {
        self.amount = amount
        self.currency = currency
        self.confidence = confidence
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: currency == "ISK" ? "is_IS" : "en_US")
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }
}

struct InternationalVATResult {
    let subtotal: CurrencyAmount?
    let tax: CurrencyAmount?
    let total: CurrencyAmount?
    let rateMap: [Double: CurrencyAmount]
    let detectedCountry: String?
    let detectedLanguage: String?
    
    init(subtotal: CurrencyAmount? = nil,
         tax: CurrencyAmount? = nil,
         total: CurrencyAmount? = nil,
         rateMap: [Double: CurrencyAmount] = [:],
         detectedCountry: String? = nil,
         detectedLanguage: String? = nil) {
        
        self.subtotal = subtotal
        self.tax = tax
        self.total = total
        self.rateMap = rateMap
        self.detectedCountry = detectedCountry
        self.detectedLanguage = detectedLanguage
    }
}

// MARK: - Authentication Models

struct UserProfile: Codable {
    let id: String
    let email: String
    let displayName: String?
    let photoURL: String?
    let createdAt: Date
    let lastLoginAt: Date
    
    init(id: String, email: String, displayName: String? = nil, photoURL: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = Date()
        self.lastLoginAt = Date()
    }
}

// MARK: - Theme Models

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "Sjálfvirkt"
        case .light: return "Ljóst"
        case .dark: return "Dökkt"
        }
    }
}

// MARK: - Error Models

enum AppError: LocalizedError {
    case ocrFailed(String)
    case parseFailed(String)
    case exportFailed(String)
    case authenticationFailed(String)
    case networkError(String)
    case fileError(String)
    case invalidInput(String)
    
    var errorDescription: String? {
        switch self {
        case .ocrFailed(let message):
            return "OCR villa: \(message)"
        case .parseFailed(let message):
            return "Greiningarvilla: \(message)"
        case .exportFailed(let message):
            return "Útflutningsvilla: \(message)"
        case .authenticationFailed(let message):
            return "Innskráningarvilla: \(message)"
        case .networkError(let message):
            return "Netvilla: \(message)"
        case .fileError(let message):
            return "Skráarvilla: \(message)"
        case .invalidInput(let message):
            return "Rangt inntak: \(message)"
        }
    }
}