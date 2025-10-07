import SwiftUI
import Combine
import CoreData

// MARK: - Invoice Manager

class InvoiceManager: ObservableObject {
    @Published var invoices: [InvoiceRecord] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedCategory: InvoiceCategory? = nil
    @Published var selectedDateRange: DateRange = .all
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadInvoices()
    }
    
    var filteredInvoices: [InvoiceRecord] {
        invoices.filter { invoice in
            let matchesSearch = searchText.isEmpty || 
                               invoice.companyName.localizedCaseInsensitiveContains(searchText) ||
                               (invoice.invoiceNumber?.contains(searchText) ?? false)
            
            let matchesCategory = selectedCategory == nil || invoice.category == selectedCategory
            
            let matchesDate: Bool
            switch selectedDateRange {
            case .all:
                matchesDate = true
            case .thisMonth:
                matchesDate = Calendar.current.isDate(invoice.date, equalTo: Date(), toGranularity: .month)
            case .lastMonth:
                let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                matchesDate = Calendar.current.isDate(invoice.date, equalTo: lastMonth, toGranularity: .month)
            case .thisYear:
                matchesDate = Calendar.current.isDate(invoice.date, equalTo: Date(), toGranularity: .year)
            case .custom(let start, let end):
                matchesDate = invoice.date >= start && invoice.date <= end
            }
            
            return matchesSearch && matchesCategory && matchesDate
        }
    }
    
    func addInvoice(_ invoice: InvoiceRecord) {
        invoices.append(invoice)
        saveInvoices()
    }
    
    func deleteInvoice(_ invoice: InvoiceRecord) {
        invoices.removeAll { $0.id == invoice.id }
        saveInvoices()
    }
    
    func updateInvoice(_ invoice: InvoiceRecord) {
        if let index = invoices.firstIndex(where: { $0.id == invoice.id }) {
            invoices[index] = invoice
            saveInvoices()
        }
    }
    
    private func loadInvoices() {
        // Load from UserDefaults for now (in production, use Core Data or CloudKit)
        if let data = UserDefaults.standard.data(forKey: "invoices"),
           let decodedInvoices = try? JSONDecoder().decode([InvoiceRecord].self, from: data) {
            self.invoices = decodedInvoices
        }
    }
    
    private func saveInvoices() {
        if let data = try? JSONEncoder().encode(invoices) {
            UserDefaults.standard.set(data, forKey: "invoices")
        }
    }
    
    // MARK: - Statistics
    
    var totalSpent: Double {
        filteredInvoices.reduce(0) { $0 + $1.totalAmount }
    }
    
    var totalVAT: Double {
        filteredInvoices.compactMap { $0.vatAmount }.reduce(0, +)
    }
    
    var averageInvoiceAmount: Double {
        guard !filteredInvoices.isEmpty else { return 0 }
        return totalSpent / Double(filteredInvoices.count)
    }
    
    var categoryBreakdown: [InvoiceCategory: Double] {
        var breakdown: [InvoiceCategory: Double] = [:]
        for invoice in filteredInvoices {
            breakdown[invoice.category, default: 0] += invoice.totalAmount
        }
        return breakdown
    }
    
    var monthlySpending: [String: Double] {
        var monthly: [String: Double] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        for invoice in filteredInvoices {
            let key = formatter.string(from: invoice.date)
            monthly[key, default: 0] += invoice.totalAmount
        }
        
        return monthly
    }
}

// MARK: - Date Range Enum

enum DateRange: Hashable {
    case all
    case thisMonth
    case lastMonth
    case thisYear
    case custom(Date, Date)
    
    var displayName: String {
        switch self {
        case .all: return "Allt"
        case .thisMonth: return "Þessi mánuður"
        case .lastMonth: return "Síðasti mánuður"
        case .thisYear: return "Þetta ár"
        case .custom(let start, let end):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }
}

// MARK: - Authentication Manager

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    
    init() {
        checkAuthenticationStatus()
    }
    
    func signInWithGoogle() {
        isLoading = true
        
        // TODO: Implement Google Sign-In
        // For now, simulate authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isAuthenticated = true
            self.currentUser = UserProfile(
                id: "test-user",
                email: "test@example.com",
                displayName: "Test User"
            )
            self.isLoading = false
        }
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
    }
    
    private func checkAuthenticationStatus() {
        // Check if user is already signed in
        // For now, default to not authenticated
        isAuthenticated = false
    }
}

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .system
    
    init() {
        loadTheme()
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        saveTheme()
    }
    
    private func loadTheme() {
        if let themeString = UserDefaults.standard.string(forKey: "app_theme"),
           let theme = AppTheme(rawValue: themeString) {
            currentTheme = theme
        }
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: "app_theme")
    }
}

// MARK: - Export Manager

class ExportManager: ObservableObject {
    @Published var isExporting = false
    @Published var lastExportResult: ExportResult?
    
    func exportInvoices(_ invoices: [InvoiceRecord], format: ExportFormat) -> ExportResult {
        isExporting = true
        
        defer { isExporting = false }
        
        switch format {
        case .csv:
            return exportToCSV(invoices)
        case .excel:
            return exportToExcel(invoices)
        case .pdf:
            return exportToPDF(invoices)
        }
    }
    
    private func exportToCSV(_ invoices: [InvoiceRecord]) -> ExportResult {
        var csvContent = "Fyrirtæki,Reikningsnúmer,Dagsetning,Undirheild,VSK,Samtals,Gjaldmiðill,Flokkur\n"
        
        for invoice in invoices {
            let line = [
                invoice.companyName,
                invoice.invoiceNumber ?? "",
                DateFormatter.shortDate.string(from: invoice.date),
                String(invoice.subtotal ?? 0),
                String(invoice.vatAmount ?? 0),
                String(invoice.totalAmount),
                invoice.currency,
                invoice.category.displayName
            ].joined(separator: ",")
            
            csvContent += line + "\n"
        }
        
        // Save to documents directory
        let fileName = "reikningar_\(DateFormatter.fileNameDate.string(from: Date())).csv"
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: url, atomically: true, encoding: .utf8)
            return ExportResult.success(filePath: url.path, fileName: fileName)
        } catch {
            return ExportResult.failure(error: error.localizedDescription)
        }
    }
    
    private func exportToExcel(_ invoices: [InvoiceRecord]) -> ExportResult {
        // For now, return CSV format with .xlsx extension
        // In production, use a proper Excel library
        return exportToCSV(invoices)
    }
    
    private func exportToPDF(_ invoices: [InvoiceRecord]) -> ExportResult {
        // TODO: Implement PDF export using PDFKit
        return ExportResult.failure(error: "PDF útflutningur ekki útfærður ennþá")
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "is_IS")
        return formatter
    }()
    
    static let fileNameDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}