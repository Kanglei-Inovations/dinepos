import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/invoice_items_model.dart';
import '../model/invoice_model.dart';

class InvoiceProvider with ChangeNotifier {
  late Box<Invoice> _invoiceBox;
  late Box<InvoiceItem> _invoiceItemBox;
  // Constructor now initializes the boxes asynchronously
  InvoiceProvider() {
    loadInvoices();
    loadInvoiceItems();
    _invoiceBox = Hive.box<Invoice>('invoices');  // Get the already opened box
    _invoiceItemBox = Hive.box<InvoiceItem>('invoice_items');
  }
  // Store invoices and invoice items as lists
  List<Invoice> _invoices = [];
  List<InvoiceItem> _invoiceItems = [];

// Getter for invoices to expose the list
  List<Invoice> get invoices => _invoices;

// Load invoices from Hive and update the invoices list
  void loadInvoices() {
    final invoiceBox = Hive.box<Invoice>('invoices'); // Corrected naming
    _invoices = invoiceBox.values.toList();
    notifyListeners();
  }

// Getter for invoice items to expose the list
  List<InvoiceItem> get invoiceItems => _invoiceItems;

// Load invoice items from Hive and update the invoiceItems list
  void loadInvoiceItems() {
    final invoiceItemBox = Hive.box<InvoiceItem>('invoice_items'); // Corrected type and naming
    _invoiceItems = invoiceItemBox.values.toList();
    notifyListeners();
  }

  // Add an invoice to Hive box
  void addInvoice(Invoice invoice) {
    if (_invoiceBox.isOpen) {
      _invoiceBox.put(invoice.id, invoice); // Store the invoice in Hive box using the id as the key
      loadInvoices(); // Reload the invoices to sync with the local list
      notifyListeners(); // Notify listeners
    }
  }

  // Add an invoice item to Hive box
  void addInvoiceItem(InvoiceItem invoiceItem) {
    if (_invoiceItemBox.isOpen) {
      _invoiceItemBox.put(invoiceItem.id, invoiceItem); // Store the invoice item in Hive box using the id as the key
      loadInvoiceItems(); // Reload the invoice items to sync with the local list
      notifyListeners(); // Notify listeners
    }
  }
// Fetch and restore invoices and invoice items
  Future<void> restoreInvoices(List<dynamic> invoices) async {
    try {
      // Check if the box is initialized
      if (_invoiceBox != null) {
        if (invoices != null) {
          // Convert the list into a Map for batch insertion
          final dataMap = {
            for (var invoice in invoices) invoice['id']: Invoice.fromJson(invoice)
          };

          // Use putAll for batch insertions into Hive
          await _invoiceBox.putAll(dataMap);
          _invoices = _invoiceBox.values.toList();
          // Refresh in-memory data
          notifyListeners();
          debugPrint('Invoices restored successfully.');
        }
      } else {
        debugPrint('Error: Invoice box is not initialized.');
      }
    } catch (e) {
      debugPrint('Error restoring invoices: $e');
    }
  }

  Future<void> restoreInvoiceItems(List<dynamic> invoiceItems) async {
    try {
      // Check if the box is initialized
      if (_invoiceItemBox != null) {
        if (invoiceItems != null) {
          // Convert the list into a Map for batch insertion
          final dataMap = {
            for (var item in invoiceItems) item['id']: InvoiceItem.fromJson(item)
          };

          // Use putAll for batch insertions into Hive
          await _invoiceItemBox.putAll(dataMap);
          _invoiceItems = _invoiceItemBox.values.toList();
          // Refresh in-memory data
          notifyListeners();
          debugPrint('Invoice items restored successfully.');
        }
      } else {
        debugPrint('Error: Invoice items box is not initialized.');
      }
    } catch (e) {
      debugPrint('Error restoring invoice items: $e');
    }
  }

  // Delete an invoice
  void deleteInvoice(int id) {
    if (_invoiceBox.isOpen) {
      _invoiceBox.delete(id); // Remove the invoice from Hive using its ID
      loadInvoices(); // Reload invoices to update the list
      notifyListeners(); // Notify listeners
    }
  }

  // Delete an invoice item
  void deleteInvoiceItem(int id) {
    if (_invoiceItemBox.isOpen) {
      _invoiceItemBox.delete(id); // Remove the invoice item from Hive using its ID
      loadInvoiceItems(); // Reload invoice items to update the list
      notifyListeners(); // Notify listeners
    }
  }

// Method to get a specific invoice by its ID
}
