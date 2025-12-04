import 'package:flutter/material.dart';
import '../models/sale_dto.dart';
import '../models/sale_item_dto.dart';
import '../services/sale_service.dart';

class SaleProvider extends ChangeNotifier {
  final SaleService _saleService = SaleService();
  
  List<SaleDTO> _sales = [];
  bool _isLoading = false;
  String? _error;

  List<SaleDTO> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters calculados para el Dashboard
  double get totalSales {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _sales
        .where((s) => s.saleDate != null && s.saleDate!.isAfter(startOfDay))
        .fold(0.0, (sum, s) => sum + (s.total ?? 0.0));
  }

  double get yesterdaySales {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final yesterday = startOfDay.subtract(const Duration(days: 1));
    return _sales
        .where((s) => s.saleDate != null && 
               s.saleDate!.isAfter(yesterday) && 
               s.saleDate!.isBefore(startOfDay))
        .fold(0.0, (sum, s) => sum + (s.total ?? 0.0));
  }

  int get totalOrders {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _sales
        .where((s) => s.saleDate != null && s.saleDate!.isAfter(startOfDay))
        .length;
  }

  int get pendingOrders {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _sales
        .where((s) => s.saleDate != null && 
               s.saleDate!.isAfter(startOfDay) && 
               s.status != 'completed')
        .length;
  }

  List<SaleDTO> get recentSales {
    return _sales.take(5).toList();
  }

  Future<void> loadSales(String companyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Optimización: Podríamos limitar a las últimas X ventas si son muchas
      _sales = await _saleService.getAll(companyId);
      // Ordenar por fecha descendente si no viene ordenado
      _sales.sort((a, b) => (b.saleDate ?? DateTime.now()).compareTo(a.saleDate ?? DateTime.now()));
    } catch (e) {
      _error = e.toString();
      print('Error loading sales: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para actualizar manualmente (Pull-to-refresh)
  Future<void> refreshSales(String companyId) => loadSales(companyId);

  Future<String> createSale(String companyId, SaleDTO sale, List<SaleItemDTO> items) async {
    _isLoading = true;
    notifyListeners();
    try {
      final id = await _saleService.createSaleWithItems(companyId, sale, items);
      
      // Crear copia con el ID asignado
      final newSale = SaleDTO(
        id: id,
        number: sale.number,
        customerId: sale.customerId,
        createdBy: sale.createdBy,
        storeId: sale.storeId,
        companyId: sale.companyId,
        subtotal: sale.subtotal,
        tax: sale.tax,
        discount: sale.discount,
        total: sale.total,
        status: sale.status,
        paymentMethod: sale.paymentMethod,
        notes: sale.notes,
        saleDate: sale.saleDate,
        createdAt: sale.createdAt ?? DateTime.now(),
        updatedAt: sale.updatedAt ?? DateTime.now(),
      );
      
      addSale(newSale);
      return id;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSale(String companyId, String saleId, SaleDTO sale, List<SaleItemDTO> items) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _saleService.updateSaleWithItems(companyId, saleId, sale, items);
      
      final index = _sales.indexWhere((s) => s.id == saleId);
      if (index != -1) {
        _sales[index] = sale;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addSale(SaleDTO sale) {
    _sales.insert(0, sale);
    notifyListeners();
  }
}
