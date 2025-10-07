import Foundation

// MARK: - International Invoice Parser
// Swift port of the Android InternationalInvoiceParser.kt

class InternationalInvoiceParser {
    
    // MARK: - Currency and Language Detection
    
    private static let currencyPatterns: [String: [String]] = [
        "ISK": ["kr", "krónur", "króna", "ISK"],
        "EUR": ["€", "EUR", "euro", "euros"],
        "USD": ["$", "USD", "dollar", "dollars"],
        "GBP": ["£", "GBP", "pound", "pounds"],
        "DKK": ["kr", "DKK", "danske kroner"],
        "NOK": ["kr", "NOK", "norske kroner"],
        "SEK": ["kr", "SEK", "svenska kronor"],
        "CHF": ["CHF", "franc", "francs"]
    ]
    
    private static let vatTerms: [String: [String]] = [
        "is": ["VSK", "virðisaukaskattur"],
        "en": ["VAT", "tax", "sales tax", "value added tax"],
        "da": ["MOMS", "merværdiafgift"],
        "no": ["MVA", "merverdiavgift"],
        "sv": ["MOMS", "mervärdesskatt"],
        "de": ["MwSt", "Mehrwertsteuer", "Umsatzsteuer"],
        "fr": ["TVA", "taxe sur la valeur ajoutée"],
        "es": ["IVA", "impuesto sobre el valor añadido"],
        "it": ["IVA", "imposta sul valore aggiunto"]
    ]
    
    private static let totalTerms: [String: [String]] = [
        "is": ["samtals", "til greiðslu", "heild", "alls"],
        "en": ["total", "amount due", "grand total", "sum"],
        "da": ["total", "i alt", "til betaling"],
        "no": ["totalt", "til betaling", "sum"],
        "sv": ["totalt", "att betala", "summa"],
        "de": ["gesamt", "summe", "zu zahlen", "total"],
        "fr": ["total", "montant total", "à payer"],
        "es": ["total", "importe total", "a pagar"],
        "it": ["totale", "importo totale", "da pagare"]
    ]
    
    private static let subtotalTerms: [String: [String]] = [
        "is": ["án vsk", "nettó", "undirheild"],
        "en": ["subtotal", "net", "before tax", "excl. tax"],
        "da": ["subtotal", "ekskl. moms", "netto"],
        "no": ["subtotal", "ekskl. mva", "netto"],
        "sv": ["subtotal", "exkl. moms", "netto"],
        "de": ["zwischensumme", "netto", "ohne mwst"],
        "fr": ["sous-total", "hors taxes", "net"],
        "es": ["subtotal", "sin iva", "neto"],
        "it": ["subtotale", "senza iva", "netto"]
    ]
    
    // MARK: - Main Parsing Function
    
    static func extractInternationalVAT(from text: String) -> InternationalVATResult {
        print("=== INTERNATIONAL VAT EXTRACTION START ===")
        
        let detectedCurrency = detectCurrency(from: text)
        let detectedLanguage = detectLanguage(from: text)
        let detectedCountry = getCountryFromLanguage(detectedLanguage)
        
        print("Detected currency: \(detectedCurrency)")
        print("Detected language: \(detectedLanguage ?? "unknown")")
        print("Detected country: \(detectedCountry ?? "unknown")")
        
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var subtotal: CurrencyAmount?
        var tax: CurrencyAmount?
        var total: CurrencyAmount?
        var rateMap: [Double: CurrencyAmount] = [:]
        
        // Get language-specific terms
        let currentVatTerms = vatTerms[detectedLanguage ?? "en"] ?? vatTerms["en"]!
        let currentTotalTerms = totalTerms[detectedLanguage ?? "en"] ?? totalTerms["en"]!
        let currentSubtotalTerms = subtotalTerms[detectedLanguage ?? "en"] ?? subtotalTerms["en"]!
        
        // Get common VAT rates for detected country
        let commonVatRates = getCommonVatRates(for: detectedCountry)
        
        // Process each line
        for line in lines {
            let lowerLine = line.lowercased()
            
            // Check for VAT amounts
            for vatTerm in currentVatTerms {
                if lowerLine.contains(vatTerm.lowercased()) {
                    for rate in commonVatRates {
                        let ratePattern = "\\b\(Int(rate))[.,]?0?%?.*?([0-9.,\\s]+)"
                        if let regex = try? NSRegularExpression(pattern: ratePattern, options: .caseInsensitive) {
                            let range = NSRange(location: 0, length: line.count)
                            if let match = regex.firstMatch(in: line, options: [], range: range) {
                                let amountRange = match.range(at: 1)
                                if let swiftRange = Range(amountRange, in: line) {
                                    let amountStr = String(line[swiftRange])
                                    if let amount = parseInternationalNumber(amountStr, currency: detectedCurrency) {
                                        rateMap[rate] = amount
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Check for totals
            if total == nil {
                for totalTerm in currentTotalTerms {
                    if lowerLine.contains(totalTerm.lowercased()) {
                        if let amount = extractLastNumberFromLine(line, currency: detectedCurrency) {
                            total = amount
                            break
                        }
                    }
                }
            }
            
            // Check for subtotals
            if subtotal == nil {
                for subtotalTerm in currentSubtotalTerms {
                    if lowerLine.contains(subtotalTerm.lowercased()) {
                        if let amount = extractLastNumberFromLine(line, currency: detectedCurrency) {
                            subtotal = amount
                            break
                        }
                    }
                }
            }
        }
        
        // Calculate total tax if we have rate map
        if tax == nil && !rateMap.isEmpty {
            let totalTaxAmount = rateMap.values.reduce(0.0) { $0 + $1.amount }
            tax = CurrencyAmount(amount: totalTaxAmount, currency: detectedCurrency, confidence: 0.9)
        }
        
        // Calculate missing values
        if let sub = subtotal, let tot = total, tax == nil {
            let taxAmount = tot.amount - sub.amount
            if taxAmount >= -0.01 {
                tax = CurrencyAmount(amount: taxAmount, currency: detectedCurrency, confidence: 0.8)
            }
        } else if subtotal == nil, let tot = total, let taxAmt = tax {
            let subtotalAmount = tot.amount - taxAmt.amount
            subtotal = CurrencyAmount(amount: subtotalAmount, currency: detectedCurrency, confidence: 0.8)
        } else if total == nil, let sub = subtotal, let taxAmt = tax {
            let totalAmount = sub.amount + taxAmt.amount
            total = CurrencyAmount(amount: totalAmount, currency: detectedCurrency, confidence: 0.9)
        }
        
        print("=== INTERNATIONAL VAT RESULT ===")
        print("Subtotal: \(subtotal?.formattedAmount ?? "nil")")
        print("Tax: \(tax?.formattedAmount ?? "nil")")
        print("Total: \(total?.formattedAmount ?? "nil")")
        print("Rate map: \(rateMap)")
        
        return InternationalVATResult(
            subtotal: subtotal,
            tax: tax,
            total: total,
            rateMap: rateMap,
            detectedCountry: detectedCountry,
            detectedLanguage: detectedLanguage
        )
    }
    
    // MARK: - Helper Functions
    
    static func detectCurrency(from text: String) -> String {
        let lowerText = text.lowercased()
        
        var currencyScores: [String: Int] = [:]
        
        for (currency, patterns) in currencyPatterns {
            let score = patterns.reduce(0) { total, pattern in
                total + lowerText.components(separatedBy: .whitespaces).filter { 
                    $0.contains(pattern.lowercased()) 
                }.count
            }
            currencyScores[currency] = score
        }
        
        let mostLikelyCurrency = currencyScores.max { $0.value < $1.value }?.key
        
        print("Currency detection scores: \(currencyScores)")
        print("Detected currency: \(mostLikelyCurrency ?? "EUR")")
        
        return mostLikelyCurrency ?? "EUR"
    }
    
    static func detectLanguage(from text: String) -> String? {
        let lowerText = text.lowercased()
        
        var languageScores: [String: Int] = [:]
        
        for (lang, terms) in vatTerms {
            let score = terms.reduce(0) { total, term in
                total + lowerText.components(separatedBy: .whitespaces).filter {
                    $0.contains(term.lowercased())
                }.count
            }
            languageScores[lang] = score
        }
        
        let detectedLang = languageScores.filter { $0.value > 0 }.max { $0.value < $1.value }?.key
        
        print("Language detection scores: \(languageScores)")
        print("Detected language: \(detectedLang ?? "unknown")")
        
        return detectedLang
    }
    
    static func parseInternationalNumber(_ text: String, currency: String) -> CurrencyAmount? {
        let cleaned = text
            .replacingOccurrences(of: "\u{00A0}", with: " ") // NBSP
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        // Remove currency symbols and words
        let currencyPatterns = InternationalInvoiceParser.currencyPatterns[currency] ?? []
        var numberText = cleaned
        for pattern in currencyPatterns {
            numberText = numberText.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
        }
        numberText = numberText.trimmingCharacters(in: .whitespaces)
        
        var amount: Double?
        
        // European format: 1.234,56 or 1 234,56
        if numberText.range(of: #"\d{1,3}(?:[. ]\d{3})*,\d{1,2}"#, options: .regularExpression) != nil {
            let cleaned = numberText.replacingOccurrences(of: "[. ]", with: "", options: .regularExpression)
                                   .replacingOccurrences(of: ",", with: ".")
            amount = Double(cleaned)
        }
        // US format: 1,234.56
        else if numberText.range(of: #"\d{1,3}(?:,\d{3})*\.\d{1,2}"#, options: .regularExpression) != nil {
            let cleaned = numberText.replacingOccurrences(of: ",", with: "")
            amount = Double(cleaned)
        }
        // Simple decimal with comma: 1234,56
        else if numberText.range(of: #"\d+,\d{1,2}"#, options: .regularExpression) != nil {
            let cleaned = numberText.replacingOccurrences(of: ",", with: ".")
            amount = Double(cleaned)
        }
        // Simple decimal with dot: 1234.56
        else if numberText.range(of: #"\d+\.\d{1,2}"#, options: .regularExpression) != nil {
            amount = Double(numberText)
        }
        // Integer: 1234
        else if numberText.range(of: #"\d+"#, options: .regularExpression) != nil {
            amount = Double(numberText)
        }
        
        if let validAmount = amount {
            return CurrencyAmount(amount: validAmount, currency: currency, confidence: 0.8)
        }
        
        return nil
    }
    
    private static func extractLastNumberFromLine(_ line: String, currency: String) -> CurrencyAmount? {
        let numberPattern = #"([0-9.,\s]+)"#
        let regex = try? NSRegularExpression(pattern: numberPattern)
        let range = NSRange(location: 0, length: line.count)
        
        let matches = regex?.matches(in: line, options: [], range: range) ?? []
        
        if let lastMatch = matches.last {
            let matchRange = lastMatch.range(at: 1)
            if let swiftRange = Range(matchRange, in: line) {
                let numberStr = String(line[swiftRange])
                return parseInternationalNumber(numberStr, currency: currency)
            }
        }
        
        return nil
    }
    
    private static func getCountryFromLanguage(_ language: String?) -> String? {
        switch language {
        case "is": return "IS" // Iceland
        case "en": return "US" // Default to US for English
        case "da": return "DK" // Denmark
        case "no": return "NO" // Norway
        case "sv": return "SE" // Sweden
        case "de": return "DE" // Germany
        case "fr": return "FR" // France
        case "es": return "ES" // Spain
        case "it": return "IT" // Italy
        default: return nil
        }
    }
    
    private static func getCommonVatRates(for country: String?) -> [Double] {
        switch country {
        case "IS": return [24.0, 11.0, 0.0] // Iceland
        case "DK": return [25.0, 0.0] // Denmark
        case "NO": return [25.0, 15.0, 0.0] // Norway
        case "SE": return [25.0, 12.0, 6.0, 0.0] // Sweden
        case "DE": return [19.0, 7.0, 0.0] // Germany
        case "FR": return [20.0, 10.0, 5.5, 2.1, 0.0] // France
        case "ES": return [21.0, 10.0, 4.0, 0.0] // Spain
        case "IT": return [22.0, 10.0, 5.0, 4.0, 0.0] // Italy
        case "US": return [8.5, 7.0, 6.0, 0.0] // US sales tax
        case "GB": return [20.0, 5.0, 0.0] // UK
        default: return [24.0, 20.0, 19.0, 25.0, 21.0, 0.0] // Common EU rates
        }
    }
}

// MARK: - Invoice Parser (Main parsing logic)

class InvoiceParser {
    
    static func parseInvoice(from text: String) -> InvoiceRecord? {
        let internationalResult = InternationalInvoiceParser.extractInternationalVAT(from: text)
        
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // Extract company name (usually first non-empty line)
        let companyName = lines.first { !$0.isEmpty && !$0.allSatisfy { $0.isNumber || $0.isPunctuation } } ?? "Óþekkt fyrirtæki"
        
        // Extract invoice number
        let invoiceNumber = extractInvoiceNumber(from: text)
        
        // Extract date
        let date = extractDate(from: text) ?? Date()
        
        // Convert international result to invoice record
        let currency = internationalResult.detectedCountry == "IS" ? "ISK" : "EUR"
        
        let vatRates = internationalResult.rateMap.map { (rate, amount) in
            VATRate(rate: rate, amount: amount.amount, currency: amount.currency)
        }
        
        let totalAmount = internationalResult.total?.amount ?? 0.0
        
        // Auto-categorize based on company name
        let category = categorizeInvoice(companyName: companyName, text: text)
        
        return InvoiceRecord(
            companyName: companyName,
            invoiceNumber: invoiceNumber,
            date: date,
            subtotal: internationalResult.subtotal?.amount,
            vatAmount: internationalResult.tax?.amount,
            totalAmount: totalAmount,
            currency: currency,
            vatRates: vatRates,
            category: category
        )
    }
    
    private static func extractInvoiceNumber(from text: String) -> String? {
        let patterns = [
            #"(?:reikningur|invoice|receipt)\s*[#:]\s*(\d+)"#,
            #"#(\d+)"#,
            #"nr\.?\s*(\d+)"#,
            #"number\s*[:#]\s*(\d+)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: text.count)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    let numberRange = match.range(at: 1)
                    if let swiftRange = Range(numberRange, in: text) {
                        return String(text[swiftRange])
                    }
                }
            }
        }
        
        return nil
    }
    
    private static func extractDate(from text: String) -> Date? {
        let datePattern = #"\d{1,2}[./-]\d{1,2}[./-]\d{2,4}"#
        
        if let regex = try? NSRegularExpression(pattern: datePattern) {
            let range = NSRange(location: 0, length: text.count)
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let swiftRange = Range(match.range, in: text) {
                    let dateStr = String(text[swiftRange])
                    
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "is_IS")
                    
                    // Try different date formats
                    let formats = ["dd.MM.yyyy", "dd/MM/yyyy", "dd-MM-yyyy", "dd.MM.yy", "dd/MM/yy"]
                    
                    for format in formats {
                        formatter.dateFormat = format
                        if let date = formatter.date(from: dateStr) {
                            return date
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    private static func categorizeInvoice(companyName: String, text: String) -> InvoiceCategory {
        let lowerName = companyName.lowercased()
        let lowerText = text.lowercased()
        
        // Grocery stores
        if lowerName.contains("bónus") || lowerName.contains("nettó") || lowerName.contains("krónan") ||
           lowerText.contains("matvörur") || lowerText.contains("grocery") {
            return .groceries
        }
        
        // Utilities
        if lowerName.contains("orkuveita") || lowerName.contains("veitur") ||
           lowerText.contains("rafmagn") || lowerText.contains("hitaveita") {
            return .utilities
        }
        
        // Transportation
        if lowerName.contains("olís") || lowerName.contains("n1") || lowerName.contains("orkan") ||
           lowerText.contains("bensín") || lowerText.contains("dísel") {
            return .transportation
        }
        
        // Healthcare
        if lowerName.contains("apótek") || lowerName.contains("heilsu") ||
           lowerText.contains("lyf") || lowerText.contains("health") {
            return .healthcare
        }
        
        return .other
    }
}