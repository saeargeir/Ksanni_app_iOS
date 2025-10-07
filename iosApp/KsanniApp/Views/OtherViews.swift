import SwiftUI
import Charts

// MARK: - Statistics View

struct StatisticsView: View {
    @EnvironmentObject var invoiceManager: InvoiceManager
    @State private var selectedPeriod: StatisticsPeriod = .thisMonth
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    Picker("Tímabil", selection: $selectedPeriod) {
                        ForEach(StatisticsPeriod.allCases, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Summary Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatisticCard(
                            title: "Heildarútgjöld",
                            value: invoiceManager.totalSpent,
                            currency: "ISK",
                            icon: "creditcard.fill",
                            color: .blue
                        )
                        
                        StatisticCard(
                            title: "Samtals VSK",
                            value: invoiceManager.totalVAT,
                            currency: "ISK",
                            icon: "percent",
                            color: .orange
                        )
                        
                        StatisticCard(
                            title: "Fjöldi reikninga",
                            value: Double(invoiceManager.filteredInvoices.count),
                            currency: nil,
                            icon: "doc.text.fill",
                            color: .green,
                            isCount: true
                        )
                        
                        StatisticCard(
                            title: "Meðaltal",
                            value: invoiceManager.averageInvoiceAmount,
                            currency: "ISK",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Category Breakdown
                    if !invoiceManager.categoryBreakdown.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Útgjöld eftir flokkum")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            // Category Chart would go here
                            CategoryBreakdownView(breakdown: invoiceManager.categoryBreakdown)
                        }
                        .padding(.vertical)
                    }
                    
                    // Monthly Trend
                    if !invoiceManager.monthlySpending.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mánaðarleg þróun")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            MonthlyTrendView(monthlyData: invoiceManager.monthlySpending)
                        }
                        .padding(.vertical)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Tölfræði")
        }
    }
}

// MARK: - Statistics Period

enum StatisticsPeriod: CaseIterable {
    case thisMonth
    case lastMonth
    case thisYear
    case allTime
    
    var displayName: String {
        switch self {
        case .thisMonth: return "Þessi mánuður"
        case .lastMonth: return "Síðasti mánuður"
        case .thisYear: return "Þetta ár"
        case .allTime: return "Allt"
        }
    }
}

// MARK: - Statistic Card

struct StatisticCard: View {
    let title: String
    let value: Double
    let currency: String?
    let icon: String
    let color: Color
    var isCount: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if isCount {
                    Text("\(Int(value))")
                        .font(.title2)
                        .fontWeight(.bold)
                } else if let currency = currency {
                    Text(value, format: .currency(code: currency))
                        .font(.title2)
                        .fontWeight(.bold)
                } else {
                    Text("\(value, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Category Breakdown View

struct CategoryBreakdownView: View {
    let breakdown: [InvoiceCategory: Double]
    
    var sortedBreakdown: [(InvoiceCategory, Double)] {
        breakdown.sorted { $0.value > $1.value }
    }
    
    var total: Double {
        breakdown.values.reduce(0, +)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(sortedBreakdown, id: \.0) { category, amount in
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: category.icon)
                            .foregroundColor(.accentColor)
                            .frame(width: 20)
                        
                        Text(category.displayName)
                            .font(.subheadline)
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(amount, format: .currency(code: "ISK"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(Int((amount / total) * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Progress bar
                GeometryReader { geometry in
                    HStack {
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.3))
                            .frame(width: geometry.size.width * (amount / total))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Spacer()
                    }
                }
                .frame(height: 4)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Monthly Trend View

struct MonthlyTrendView: View {
    let monthlyData: [String: Double]
    
    var sortedData: [(String, Double)] {
        monthlyData.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Simple bar chart representation
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(sortedData.prefix(6), id: \.0) { month, amount in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: 30, height: max(20, amount / 1000 * 100))
                            .cornerRadius(2)
                        
                        Text(String(month.suffix(2)))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
            // Legend
            HStack {
                Text("Síðustu 6 mánuðir")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Export View

struct ExportView: View {
    @EnvironmentObject var invoiceManager: InvoiceManager
    @StateObject private var exportManager = ExportManager()
    @State private var selectedFormat: ExportFormat = .csv
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Export Summary
                VStack(spacing: 12) {
                    Text("Útflutningsyfirlit")
                        .font(.headline)
                    
                    Text("\(invoiceManager.filteredInvoices.count) reikningar valdir")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Heildarupphæð: \(invoiceManager.totalSpent, format: .currency(code: "ISK"))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Format Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Veldu snið")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        HStack {
                            Button(action: {
                                selectedFormat = format
                            }) {
                                HStack {
                                    Image(systemName: selectedFormat == format ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedFormat == format ? .accentColor : .secondary)
                                    
                                    VStack(alignment: .leading) {
                                        Text(format.displayName)
                                            .font(.headline)
                                        Text(getFormatDescription(format))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(selectedFormat == format ? Color.accentColor.opacity(0.1) : Color.clear)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Export Button
                Button(action: {
                    exportInvoices()
                }) {
                    HStack {
                        if exportManager.isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(exportManager.isExporting ? "Flyt út..." : "Flytja út")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(exportManager.isExporting || invoiceManager.filteredInvoices.isEmpty)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Útflutningur")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Villa", isPresented: $showingAlert) {
            Button("Í lagi", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func exportInvoices() {
        let result = exportManager.exportInvoices(invoiceManager.filteredInvoices, format: selectedFormat)
        
        if result.success, let filePath = result.filePath {
            exportURL = URL(fileURLWithPath: filePath)
            showingShareSheet = true
        } else {
            alertMessage = result.error ?? "Óþekkt villa við útflutning"
            showingAlert = true
        }
    }
    
    private func getFormatDescription(_ format: ExportFormat) -> String {
        switch format {
        case .csv: return "Comma-separated values, opnast í Excel"
        case .excel: return "Microsoft Excel format"
        case .pdf: return "PDF skjal til að deila eða prenta"
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingSignOut = false
    
    var body: some View {
        NavigationView {
            Form {
                // User Section
                if authManager.isAuthenticated {
                    Section("Notandi") {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading) {
                                Text(authManager.currentUser?.displayName ?? "Notandi")
                                    .font(.headline)
                                Text(authManager.currentUser?.email ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Button("Skrá út") {
                            showingSignOut = true
                        }
                        .foregroundColor(.red)
                    }
                } else {
                    Section("Innskráning") {
                        Button("Skrá inn með Google") {
                            authManager.signInWithGoogle()
                        }
                        .foregroundColor(.accentColor)
                    }
                }
                
                // Appearance
                Section("Útlit") {
                    Picker("Þema", selection: $themeManager.currentTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                }
                
                // App Info
                Section("Um appið") {
                    HStack {
                        Text("Útgáfa")
                        Spacer()
                        Text("1.0.42")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Persónuverndarstefna", destination: URL(string: "https://github.com/saeargeir/Ksanni_app_iOS")!)
                    
                    Link("Höfundarréttur", destination: URL(string: "https://github.com/saeargeir")!)
                }
                
                // Support
                Section("Stuðningur") {
                    Link("Senda ábendingu", destination: URL(string: "mailto:iceveflausnir@gmail.com")!)
                    
                    Link("GitHub", destination: URL(string: "https://github.com/saeargeir/Ksanni_app_iOS")!)
                }
            }
            .navigationTitle("Stillingar")
        }
        .alert("Skrá út", isPresented: $showingSignOut) {
            Button("Hætta við", role: .cancel) { }
            Button("Skrá út", role: .destructive) {
                authManager.signOut()
            }
        } message: {
            Text("Ertu viss um að þú viljir skrá þig út?")
        }
    }
}

#Preview {
    StatisticsView()
        .environmentObject(InvoiceManager())
}