package io.github.saeargeir.skanniapp.model

/**
 * Data class representing a scanned invoice record in the SkanniApp system.
 * 
 * This model contains all essential information extracted from a receipt/invoice,
 * including OCR text, calculated VAT amounts, and categorization data for
 * expense tracking and reporting.
 * 
 * @property id Unique identifier for the invoice record in the local database
 * @property date Invoice date in ISO format (yyyy-MM-dd) for consistent sorting and filtering
 * @property monthKey Month grouping key in format (yyyy-MM) for monthly reporting and aggregation
 * @property vendor Store/vendor name as recognized by OCR or manually corrected by user
 * @property amount Total invoice amount including VAT, in Icelandic krónur (ISK)
 * @property vat VAT amount (not percentage) calculated based on Icelandic tax rates (typically 24% or 11%)
 * @property imagePath Absolute path to the stored receipt image in internal app storage
 * @property invoiceNumber Optional invoice/receipt number if detected by OCR or entered manually
 * @property categoryId Optional expense category identifier for smart categorization system
 * @property ocrText Optional full OCR-extracted text for ML analysis and future improvements
 * @property isManuallyClassified Flag indicating if the user manually overrode automatic categorization
 * @property classificationConfidence ML confidence score (0.0-1.0) for automatic categorization accuracy
 * 
 * @since 1.0.0
 * @author SkanniApp Team
 */
data class InvoiceRecord(
    val id: Long,
    val date: String,        // ISO yyyy-MM-dd
    val monthKey: String,    // yyyy-MM
    val vendor: String,
    val amount: Double,
    val vat: Double,         // VAT amount (not percent)
    val imagePath: String,   // absolute path in internal storage
    val invoiceNumber: String? = null,
    val categoryId: String? = null,  // Smart categorization
    val ocrText: String? = null,     // Full OCR text for ML analysis
    val isManuallyClassified: Boolean = false,  // User manually changed category
    val classificationConfidence: Double = 0.0  // ML confidence score
)
