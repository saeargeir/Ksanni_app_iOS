import SwiftUI

// MARK: - Invoice List View

struct InvoiceListView: View {
    @EnvironmentObject var invoiceManager: InvoiceManager
    @State private var showingFilterSheet = false
    @State private var showingAddInvoice = false
    @State private var selectedInvoice: InvoiceRecord?
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Leita að reikningum...", text: $invoiceManager.searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    Button(action: {
                        showingFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                
                // Filter chips
                if invoiceManager.selectedCategory != nil || invoiceManager.selectedDateRange != .all {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            if let category = invoiceManager.selectedCategory {
                                FilterChip(text: category.displayName) {
                                    invoiceManager.selectedCategory = nil
                                }
                            }
                            
                            if invoiceManager.selectedDateRange != .all {
                                FilterChip(text: invoiceManager.selectedDateRange.displayName) {
                                    invoiceManager.selectedDateRange = .all
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Invoice List
                if invoiceManager.filteredInvoices.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Engir reikningar fundust")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Skannaðu fyrsta reikninginn þinn!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(invoiceManager.filteredInvoices) { invoice in
                            InvoiceRowView(invoice: invoice)
                                .onTapGesture {
                                    selectedInvoice = invoice
                                }
                        }
                        .onDelete(perform: deleteInvoices)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Reikningar (\(invoiceManager.filteredInvoices.count))")
            .navigationBarItems(
                leading: EditButton(),
                trailing: Button(action: {
                    showingAddInvoice = true
                }) {
                    Image(systemName: "plus")
                }
            )
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheet()
        }
        .sheet(item: $selectedInvoice) { invoice in
            InvoiceDetailView(invoice: invoice)
        }
        .sheet(isPresented: $showingAddInvoice) {
            AddInvoiceView()
        }
    }
    
    private func deleteInvoices(offsets: IndexSet) {
        for index in offsets {
            let invoice = invoiceManager.filteredInvoices[index]
            invoiceManager.deleteInvoice(invoice)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.2))
        .foregroundColor(.accentColor)
        .cornerRadius(12)
    }
}

// MARK: - Invoice Row View

struct InvoiceRowView: View {
    let invoice: InvoiceRecord
    
    var body: some View {
        HStack {
            // Category Icon
            Image(systemName: invoice.category.icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(invoice.companyName)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    if let invoiceNumber = invoice.invoiceNumber {
                        Text("#\(invoiceNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(invoice.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(invoice.totalAmount, format: .currency(code: invoice.currency))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let vatAmount = invoice.vatAmount {
                    Text("VSK: \(vatAmount, format: .currency(code: invoice.currency))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @EnvironmentObject var invoiceManager: InvoiceManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section("Flokkur") {
                    Picker("Flokkur", selection: $invoiceManager.selectedCategory) {
                        Text("Allir flokkar").tag(nil as InvoiceCategory?)
                        ForEach(InvoiceCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.displayName)
                            }
                            .tag(category as InvoiceCategory?)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
                
                Section("Tímabil") {
                    Picker("Tímabil", selection: $invoiceManager.selectedDateRange) {
                        ForEach([DateRange.all, .thisMonth, .lastMonth, .thisYear], id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Sía")
            .navigationBarItems(
                leading: Button("Hreinsa") {
                    invoiceManager.selectedCategory = nil
                    invoiceManager.selectedDateRange = .all
                },
                trailing: Button("Lokið") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Invoice Detail View

struct InvoiceDetailView: View {
    let invoice: InvoiceRecord
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: invoice.category.icon)
                                .font(.title2)
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading) {
                                Text(invoice.companyName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(invoice.category.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        if let invoiceNumber = invoice.invoiceNumber {
                            Text("Reikningsnúmer: \(invoiceNumber)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Dagsetning: \(invoice.date, style: .date)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Amounts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upphæðir")
                            .font(.headline)
                        
                        if let subtotal = invoice.subtotal {
                            HStack {
                                Text("Undirheild:")
                                Spacer()
                                Text(subtotal, format: .currency(code: invoice.currency))
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if let vatAmount = invoice.vatAmount {
                            HStack {
                                Text("VSK:")
                                Spacer()
                                Text(vatAmount, format: .currency(code: invoice.currency))
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if !invoice.vatRates.isEmpty {
                            ForEach(invoice.vatRates) { vatRate in
                                HStack {
                                    Text("VSK \(vatRate.rate, specifier: "%.1f")%:")
                                    Spacer()
                                    Text(vatRate.amount, format: .currency(code: vatRate.currency))
                                        .fontWeight(.medium)
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Samtals:")
                                .font(.headline)
                            Spacer()
                            Text(invoice.totalAmount, format: .currency(code: invoice.currency))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    
                    if let notes = invoice.notes {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Athugasemdir")
                                .font(.headline)
                            Text(notes)
                                .font(.body)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Reikningsupplýsingar")
            .navigationBarItems(trailing: Button("Lokið") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Add Invoice View

struct AddInvoiceView: View {
    @EnvironmentObject var invoiceManager: InvoiceManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var companyName = ""
    @State private var invoiceNumber = ""
    @State private var date = Date()
    @State private var totalAmount = ""
    @State private var vatAmount = ""
    @State private var currency = "ISK"
    @State private var category = InvoiceCategory.other
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Grunnupplýsingar") {
                    TextField("Nafn fyrirtækis", text: $companyName)
                    TextField("Reikningsnúmer (valfrjálst)", text: $invoiceNumber)
                    DatePicker("Dagsetning", selection: $date, displayedComponents: .date)
                }
                
                Section("Upphæðir") {
                    TextField("Heildarupphæð", text: $totalAmount)
                        .keyboardType(.decimalPad)
                    TextField("VSK upphæð (valfrjálst)", text: $vatAmount)
                        .keyboardType(.decimalPad)
                    Picker("Gjaldmiðill", selection: $currency) {
                        Text("ISK").tag("ISK")
                        Text("EUR").tag("EUR")
                        Text("USD").tag("USD")
                    }
                }
                
                Section("Flokkur") {
                    Picker("Flokkur", selection: $category) {
                        ForEach(InvoiceCategory.allCases, id: \.self) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                Text(cat.displayName)
                            }
                            .tag(cat)
                        }
                    }
                }
                
                Section("Athugasemdir") {
                    TextField("Athugasemdir (valfrjálst)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Nýr reikningur")
            .navigationBarItems(
                leading: Button("Hætta við") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Vista") {
                    saveInvoice()
                }
                .disabled(companyName.isEmpty || totalAmount.isEmpty)
            )
        }
    }
    
    private func saveInvoice() {
        guard let total = Double(totalAmount) else { return }
        
        let invoice = InvoiceRecord(
            companyName: companyName,
            invoiceNumber: invoiceNumber.isEmpty ? nil : invoiceNumber,
            date: date,
            vatAmount: Double(vatAmount),
            totalAmount: total,
            currency: currency,
            category: category,
            notes: notes.isEmpty ? nil : notes
        )
        
        invoiceManager.addInvoice(invoice)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    InvoiceListView()
        .environmentObject(InvoiceManager())
}