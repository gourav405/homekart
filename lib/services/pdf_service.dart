import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'dart:typed_data';
import '../models/sale.dart';
import 'settings_service.dart';

class PdfService {
  Future<Uint8List> generateCustomerLedgerStatement({
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required double totalBalance,
    required List<Sale> unpaidInvoices,
    required List<Map<String, dynamic>> recentPayments,
  }) async {
    final settings = await _settings.getAll();
    final pdf = pw.Document();

    final businessName = settings['business_name'] ?? 'Kewal Hardware Store';
    final businessAddr = settings['business_address'] ?? '';
    final businessPhone = settings['business_phone'] ?? '';
    pw.ImageProvider? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/images/logo.jpg');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null) pw.Container(width: 80, child: pw.Image(logoImage)),
                    pw.SizedBox(height: 8),
                    pw.Text(businessName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text(businessAddr, style: const pw.TextStyle(fontSize: 12)),
                    pw.Text('Phone: $businessPhone', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('STATEMENT OF ACCOUNT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.SizedBox(height: 8),
                    pw.Text('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Prepared For:', style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text(customerName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    if (customerPhone.isNotEmpty) pw.Text('Phone: $customerPhone', style: const pw.TextStyle(fontSize: 12)),
                    if (customerAddress.isNotEmpty) pw.Text(customerAddress, style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('TOTAL AMOUNT DUE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('Rs. ${totalBalance.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Text('Unpaid Invoices', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            if (unpaidInvoices.isEmpty)
              pw.Text('No pending invoices.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic))
            else
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                cellAlignment: pw.Alignment.centerRight,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                },
                headers: ['Date', 'Invoice No.', 'Total', 'Paid/Returned', 'Balance Due'],
                data: unpaidInvoices.map((inv) {
                  final due = inv.totalAmount - inv.returnedAmount - inv.amountPaid;
                  return [
                    DateFormat('dd MMM yyyy').format(inv.saleDate),
                    inv.invoiceNumber,
                    'Rs. ${inv.totalAmount.toStringAsFixed(2)}',
                    'Rs. ${(inv.returnedAmount + inv.amountPaid).toStringAsFixed(2)}',
                    'Rs. ${due.toStringAsFixed(2)}',
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 24),
            if (recentPayments.isNotEmpty) ...[
              pw.Text('Recent Payments Received', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
                cellAlignment: pw.Alignment.centerRight,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                },
                headers: ['Date', 'Method', 'Amount', 'Notes'],
                data: recentPayments.take(5).map((p) {
                  return [
                    DateFormat('dd MMM yyyy').format(DateTime.parse(p['payment_date'])),
                    p['payment_method'],
                    'Rs. ${double.parse(p['amount'].toString()).toStringAsFixed(2)}',
                    p['notes'] ?? '-',
                  ];
                }).toList(),
              ),
            ],
            pw.SizedBox(height: 48),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text('Thank you for your business!', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
            ),
          ];
        }
      )
    );
    return pdf.save();
  }
  final SettingsService _settings = SettingsService();

  Future<void> printInvoice(Sale sale, {bool showGst = true}) async {
    final settings = await _settings.getAll();
    final pdf = pw.Document();

    final businessName = settings['business_name'] ?? 'Kewal Hardware Store';
    final businessAddr = settings['business_address'] ?? '';
    final businessPhone = settings['business_phone'] ?? '';
    final businessEmail = settings['business_email'] ?? '';
    final gstin = settings['business_gstin'] ?? '';
    pw.ImageProvider? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/images/logo.jpg');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      // Ignore logo load error
    }

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        // Header
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            if (logoImage != null) ...[
              pw.Image(logoImage, width: 60, height: 60, fit: pw.BoxFit.contain),
              pw.SizedBox(width: 16),
            ],
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(businessName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E88E5'))),
              pw.SizedBox(height: 4),
              if (businessAddr.isNotEmpty) pw.Text(businessAddr, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              if (businessPhone.isNotEmpty) pw.Text('Phone: $businessPhone', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              if (businessEmail.isNotEmpty) pw.Text('Email: $businessEmail', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              if (gstin.isNotEmpty) pw.Text('GSTIN: $gstin', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ])),
          ])),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text(showGst ? 'TAX INVOICE' : 'INVOICE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
            pw.SizedBox(height: 8),
            pw.Text('Invoice #: ${sale.invoiceNumber}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text('Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(sale.saleDate)}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: pw.BoxDecoration(
                color: sale.paymentStatus == 'paid' ? PdfColor.fromHex('#E8F5E9') : PdfColor.fromHex('#FFEBEE'),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(sale.paymentStatus.toUpperCase(), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: sale.paymentStatus == 'paid' ? PdfColor.fromHex('#2E7D32') : PdfColor.fromHex('#C62828'))),
            ),
          ]),
        ]),
        pw.SizedBox(height: 20),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 12),

        // Customer info
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F7FA'), borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Bill To:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
              pw.SizedBox(height: 4),
              pw.Text(sale.customerName ?? 'Walk-in Customer', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ])),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('Payment: ${sale.paymentMethod}', style: const pw.TextStyle(fontSize: 10)),
            ]),
          ]),
        ),
        pw.SizedBox(height: 20),

        // Items table
        pw.TableHelper.fromTextArray(
          context: context,
          border: pw.TableBorder.all(color: PdfColors.grey300),
          headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E88E5')),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellHeight: 28,
          headerHeight: 32,
          cellAlignments: (() {
            if (!showGst || sale.tax == 0) return {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight};
            if (sale.isIgst) return {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight, 5: pw.Alignment.centerRight, 6: pw.Alignment.centerRight};
            return {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight, 5: pw.Alignment.centerRight, 6: pw.Alignment.centerRight, 7: pw.Alignment.centerRight};
          })(),
          headers: (() {
            if (!showGst || sale.tax == 0) return ['#', 'Product', 'Qty', 'Unit Price (Rs.)', 'Amount (Rs.)'];
            if (sale.isIgst) return ['#', 'Product', 'Qty', 'Unit Base', 'Base Tot', 'IGST', 'Final (Rs.)'];
            return ['#', 'Product', 'Qty', 'Unit Base', 'Base Tot', 'CGST', 'SGST', 'Final (Rs.)'];
          })(),
          data: (sale.items ?? []).asMap().entries.map((e) {
            final i = e.value;
            final tintingPerUnit = i.tintingCharge / (i.quantity > 0 ? i.quantity : 1);
            
            final basePrice = i.price + tintingPerUnit;
            final baseAmount = (i.price * i.quantity) + i.tintingCharge - i.discount;
            final finalAmount = baseAmount + i.tax;
            
            double taxPct = baseAmount > 0 ? (i.tax / baseAmount * 100) : 0;
            
            String productName = i.productName ?? i.variantSku ?? '-';
            if (i.variantName != null && i.variantName!.isNotEmpty) {
              productName += ' - ${i.variantName}';
            }
            if (i.packSize != null && i.unitSymbol != null) {
              productName += ' (${i.packSize!.toStringAsFixed(i.packSize! == i.packSize!.toInt() ? 0 : 2)} ${i.unitSymbol})';
            }
            if (i.isTinted) {
              productName += '\n(Shade: ${i.shadeCode ?? "Custom"})';
            }
            if (i.discount > 0) {
              productName += '\n(Disc: -Rs. ${i.discount.toStringAsFixed(2)})';
            }
            
            String qtyStr = i.quantity == i.quantity.toInt() ? i.quantity.toInt().toString() : i.quantity.toString();
            if (i.returnedQuantity > 0) {
              qtyStr += '\n[Rtn: -${i.returnedQuantity == i.returnedQuantity.toInt() ? i.returnedQuantity.toInt().toString() : i.returnedQuantity.toString()}]';
            }
            
            List<String> row = ['${e.key + 1}', productName, qtyStr, basePrice.toStringAsFixed(2), baseAmount.toStringAsFixed(2)];
            
            if (!showGst || sale.tax == 0) {
              row.add(finalAmount.toStringAsFixed(2));
            } else if (sale.isIgst) {
              row.addAll(['${taxPct.toStringAsFixed(2)}%\nRs. ${i.tax.toStringAsFixed(2)}', finalAmount.toStringAsFixed(2)]);
            } else {
              row.addAll(['${(taxPct/2).toStringAsFixed(1)}%\nRs. ${(i.tax/2).toStringAsFixed(2)}', '${(taxPct/2).toStringAsFixed(1)}%\nRs. ${(i.tax/2).toStringAsFixed(2)}', finalAmount.toStringAsFixed(2)]);
            }
            return row;
          }).toList(),
        ),
        pw.SizedBox(height: 16),

        // Summary
        pw.Align(alignment: pw.Alignment.centerRight, child: pw.Container(
          width: 220,
          child: pw.Column(children: [
            if (showGst) ...[
              _pdfSummaryRow('Subtotal', 'Rs. ${(sale.subtotal + _totalTinting(sale)).toStringAsFixed(2)}'),
              sale.isIgst
                ? _pdfSummaryRow('IGST', 'Rs. ${sale.igstAmount.toStringAsFixed(2)}')
                : pw.Column(children: [
                    _pdfSummaryRow('CGST', 'Rs. ${sale.cgst.toStringAsFixed(2)}'),
                    pw.Divider(color: PdfColors.grey200),
                    _pdfSummaryRow('SGST', 'Rs. ${sale.sgst.toStringAsFixed(2)}'),
                  ]),
            ],
            if (!showGst) ...[
              _pdfSummaryRow('Total', 'Rs. ${(sale.subtotal + sale.tax + _totalTinting(sale)).toStringAsFixed(2)}'),
            ],
            if (sale.discount > 0) ...[
              pw.Divider(color: PdfColors.grey200),
              _pdfSummaryRow('Discount', '- Rs. ${sale.discount.toStringAsFixed(2)}'),
            ],
            pw.Divider(color: PdfColors.grey400, thickness: 1.5),
            pw.SizedBox(height: 4),
            _pdfSummaryRow('Total Amount', 'Rs. ${sale.totalAmount.toStringAsFixed(2)}', bold: true, fontSize: 13),
            pw.SizedBox(height: 4),
            if (sale.paymentStatus == 'paid') ...[
              _pdfSummaryRow('Status', 'Fully Paid', bold: true, color: PdfColors.green700),
              _pdfSummaryRow('Amount Paid', 'Rs. ${sale.amountPaid.toStringAsFixed(2)}'),
            ] else if (sale.paymentStatus == 'partial') ...[
              _pdfSummaryRow('Status', 'Partially Paid', bold: true, color: PdfColors.orange700),
              _pdfSummaryRow('Amount Paid', 'Rs. ${sale.amountPaid.toStringAsFixed(2)}'),
              pw.Divider(color: PdfColors.grey400, thickness: 1.5),
              _pdfSummaryRow('Remaining', 'Rs. ${(sale.totalAmount - sale.amountPaid).toStringAsFixed(2)}', bold: true, fontSize: 14, color: PdfColors.red700),
            ] else if (sale.paymentStatus == 'unpaid') ...[
              _pdfSummaryRow('Status', 'Udhar (Pay Later)', bold: true, color: PdfColors.red700),
              pw.Divider(color: PdfColors.grey400, thickness: 1.5),
              _pdfSummaryRow('Amount Due', 'Rs. ${sale.totalAmount.toStringAsFixed(2)}', bold: true, fontSize: 14, color: PdfColors.red700),
            ],
            if (sale.returnedAmount > 0) ...[
              pw.SizedBox(height: 4),
              _pdfSummaryRow('Refunded', '- Rs. ${sale.returnedAmount.toStringAsFixed(2)}', bold: true, fontSize: 13, color: PdfColors.red700),
              pw.Divider(color: PdfColors.grey400, thickness: 1.5),
              _pdfSummaryRow('Net Revenue', 'Rs. ${(sale.totalAmount - sale.returnedAmount).toStringAsFixed(2)}', bold: true, fontSize: 14),
            ]
          ]),
        )),
        pw.SizedBox(height: 30),

        // Footer
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Text('Thank you for your business!', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 4),
        pw.Text('This is a computer-generated invoice.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500), textAlign: pw.TextAlign.center),
      ],
    ));

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Invoice_${sale.invoiceNumber}');
  }

  pw.Widget _pdfSummaryRow(String label, String value, {bool bold = false, double fontSize = 10, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color ?? PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
      ]),
    );
  }

  double _totalTinting(Sale sale) => (sale.items ?? []).fold(0.0, (s, i) => s + i.tintingCharge);
  Future<Uint8List> generateThermalReceipt(Sale sale, {bool showGst = true}) async {
    final settings = await _settings.getAll();
    final businessName = settings['business_name'] ?? 'Kewal Hardware Store';
    final businessAddr = settings['business_address'] ?? '';
    final businessPhone = settings['business_phone'] ?? '';
    final gstin = settings['business_gstin'] ?? '';

    final pdf = pw.Document();
    
    // Thermal paper 80mm width (approx 3.14 inches). 72 pt = 1 inch. 
    // 3.14 * 72 = 226 pt width. Length is dynamic.
    final format = PdfPageFormat(226, double.infinity, marginAll: 10);

    pdf.addPage(pw.Page(
      pageFormat: format,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(child: pw.Text(businessName.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
            if (businessAddr.isNotEmpty) pw.Center(child: pw.Text(businessAddr, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
            if (businessPhone.isNotEmpty) pw.Center(child: pw.Text('Ph: $businessPhone', style: const pw.TextStyle(fontSize: 8))),
            if (gstin.isNotEmpty) pw.Center(child: pw.Text('GSTIN: $gstin', style: const pw.TextStyle(fontSize: 8))),
            pw.SizedBox(height: 8),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            pw.SizedBox(height: 8),
            
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Inv: ${sale.invoiceNumber}', style: const pw.TextStyle(fontSize: 9)),
              pw.Text(DateFormat('dd-MMM-yy').format(sale.saleDate), style: const pw.TextStyle(fontSize: 9)),
            ]),
            pw.SizedBox(height: 4),
            pw.Text('To: ${sale.customerName ?? 'Walk-in'}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            pw.SizedBox(height: 8),
            
            // Items
            ...sale.items?.map((i) {
              final tintingPerUnit = i.tintingCharge / (i.quantity > 0 ? i.quantity : 1);
              final discountPerUnit = i.discount / (i.quantity > 0 ? i.quantity : 1);
              final displayPrice = i.price + tintingPerUnit - discountPerUnit;
              
              final baseAmount = (i.price * i.quantity) + i.tintingCharge - i.discount;
              final finalAmount = baseAmount + i.tax;
              
              String name = i.productName ?? '-';
              if (i.variantName != null && i.variantName!.isNotEmpty) {
                name += ' - ${i.variantName}';
              }
              if (i.packSize != null && i.unitSymbol != null) {
                name += ' (${i.packSize!.toStringAsFixed(i.packSize! == i.packSize!.toInt() ? 0 : 2)} ${i.unitSymbol})';
              }
              if (i.isTinted) name += ' (Shade: ${i.shadeCode ?? "Custom"})';
              if (i.discount > 0) name += ' (Disc: -Rs. ${i.discount.toStringAsFixed(2)})';

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(name, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text('${i.quantity == i.quantity.toInt() ? i.quantity.toInt().toString() : i.quantity.toString()} x Rs. ${displayPrice.toStringAsFixed(2)}${showGst ? '' : ' (Incl. Tax)'}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Rs. ${finalAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                  ]),
                  if (showGst && i.tax > 0)
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                      pw.Text(sale.isIgst ? '  IGST' : '  CGST/SGST', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.Text('Rs. ${i.tax.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ]),
                  pw.SizedBox(height: 4),
                ]
              );
            }).toList() ?? [],
            
            pw.SizedBox(height: 4),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            pw.SizedBox(height: 4),
            
            // Totals
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text(showGst ? 'Subtotal:' : 'Gross Total:', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Rs. ${(sale.subtotal + (showGst ? 0 : sale.tax)).toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
            ]),
            if (sale.tax > 0 && showGst) ...[
              if (sale.isIgst)
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('IGST:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Rs. ${sale.igstAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                ])
              else ...[
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('CGST:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Rs. ${sale.cgst.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                ]),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('SGST:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Rs. ${sale.sgst.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                ])
              ]
            ],
            if (sale.discount > 0)
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Discount:', style: const pw.TextStyle(fontSize: 10)),
                pw.Text('- Rs. ${sale.discount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
              ]),
            pw.SizedBox(height: 4),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('TOTAL DUE:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('Rs. ${sale.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ]),
            pw.SizedBox(height: 8),
            pw.Divider(borderStyle: pw.BorderStyle.dashed),
            pw.SizedBox(height: 4),
            
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Status:', style: const pw.TextStyle(fontSize: 10)),
              pw.Text(sale.paymentStatus.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ]),
            pw.SizedBox(height: 24),
            pw.Center(child: pw.Text('Thank you for shopping!', style: const pw.TextStyle(fontSize: 9))),
            pw.SizedBox(height: 10),
          ],
        );
      }
    ));

    return pdf.save();
  }
}
