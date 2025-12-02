import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/sale_service.dart';
import '../../../services/customer_service.dart';
import '../../../services/product_service.dart';
import '../../../models/sale_dto.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color _primaryColor = const Color(0xFF1A237E);
  final Color _accentColor = const Color(0xFF00BFA5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  final AuthService _authService = AuthService();
  final SaleService _saleService = SaleService();
  final CustomerService _customerService = CustomerService();
  final ProductService _productService = ProductService();

  User? user;
  bool _isLoading = true;
  
  // Dashboard stats
  double _totalSales = 0.0;
  double _yesterdaySales = 0.0;
  int _totalOrders = 0;
  int _pendingOrders = 0;
  int _totalCustomers = 0;
  int _newCustomersToday = 0;
  int _lowStockProducts = 0;
  List<SaleDTO> _recentSales = [];

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final companyId = _authService.currentCompanyId;
      if (companyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Cargar datos en paralelo
      await Future.wait([
        _loadSalesData(companyId),
        _loadCustomersData(companyId),
        _loadProductsData(companyId),
      ]);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSalesData(String companyId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final yesterday = startOfDay.subtract(const Duration(days: 1));
      
      // Obtener todas las ventas
      final allSales = await _saleService.getAll(companyId);
      
      // Filtrar ventas de hoy
      final todaySales = allSales.where((sale) {
        return sale.saleDate != null && sale.saleDate!.isAfter(startOfDay);
      }).toList();
      
      // Filtrar ventas de ayer
      final yesterdaySalesList = allSales.where((sale) {
        return sale.saleDate != null && 
               sale.saleDate!.isAfter(yesterday) && 
               sale.saleDate!.isBefore(startOfDay);
      }).toList();
      
      // Calcular totales
      _totalSales = todaySales.fold(0.0, (sum, sale) => sum + (sale.total ?? 0.0));
      _yesterdaySales = yesterdaySalesList.fold(0.0, (sum, sale) => sum + (sale.total ?? 0.0));
      _totalOrders = todaySales.length;
      
      // Contar pedidos pendientes
      _pendingOrders = todaySales.where((sale) {
        return sale.status != 'completed';
      }).length;
      
      // Obtener ventas recientes (últimas 5)
      _recentSales = allSales.take(5).toList();
      
    } catch (e) {
      debugPrint('Error loading sales data: $e');
    }
  }

  Future<void> _loadCustomersData(String companyId) async {
    try {
      final customers = await _customerService.getAll(companyId);
      _totalCustomers = customers.length;
      
      // Contar clientes nuevos de hoy
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      _newCustomersToday = customers.where((customer) {
        return customer.createdAt != null && 
               customer.createdAt!.isAfter(startOfDay);
      }).length;
    } catch (e) {
      debugPrint('Error loading customers data: $e');
    }
  }

  Future<void> _loadProductsData(String companyId) async {
    try {
      final products = await _productService.getAll(companyId);
      
      // Contar productos inactivos o que necesitan atención
      // Como ProductDTO no tiene campo stock, contamos productos inactivos
      _lowStockProducts = products.where((product) {
        return product.isActive == false;
      }).length;
    } catch (e) {
      debugPrint('Error loading products data: $e');
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return 'Hace unos momentos';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text(
          'Panel de Administración',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: _accentColor,
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? 'A',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, ${user?.displayName ?? "Administrador"}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Resumen del día - ${DateTime.now().toString().split(' ')[0]}',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Stats Cards
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                      double childAspectRatio =
                          constraints.maxWidth > 600 ? 1.5 : 1.2;

                      // Calcular porcentaje de cambio vs ayer
                      final percentChange = _yesterdaySales > 0
                          ? ((_totalSales - _yesterdaySales) / _yesterdaySales * 100)
                          : 0.0;
                      final changeText = percentChange >= 0
                          ? '+${percentChange.toStringAsFixed(1)}% vs ayer'
                          : '${percentChange.toStringAsFixed(1)}% vs ayer';

                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: childAspectRatio,
                        children: [
                          _buildStatCard(
                            'Ventas Totales',
                            '\$${_totalSales.toStringAsFixed(2)}',
                            Icons.attach_money,
                            Colors.green,
                            changeText,
                          ),
                          _buildStatCard(
                            'Pedidos',
                            '$_totalOrders',
                            Icons.shopping_bag_outlined,
                            Colors.orange,
                            '$_pendingOrders pendientes',
                          ),
                          _buildStatCard(
                            'Clientes',
                            '$_totalCustomers',
                            Icons.people_outline,
                            Colors.blue,
                            '+$_newCustomersToday nuevos hoy',
                          ),
                          _buildStatCard(
                            'Alerta',
                            '$_lowStockProducts',
                            Icons.warning_amber_rounded,
                            Colors.red,
                            'Productos inactivos',
                          ),
                        ],
                      );
                    },
                  ),

            const SizedBox(height: 32),

            // Recent Activity Section
            Text(
              'Actividad Reciente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _recentSales.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'No hay ventas recientes',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentSales.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final sale = _recentSales[index];
                            final timeAgo = sale.saleDate != null
                                ? _getTimeAgo(sale.saleDate!)
                                : 'Fecha desconocida';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[50],
                                child: Icon(
                                  Icons.receipt_long,
                                  color: _primaryColor,
                                  size: 20,
                                ),
                              ),
                              title: Text('Venta #${sale.number ?? 'S/N'}'),
                              subtitle: Text(timeAgo),
                              trailing: Text(
                                '\$${(sale.total ?? 0.0).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: _primaryColor,
              // Evitar que intente cargar imagen de fondo
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? 'A',
                style: TextStyle(fontSize: 24, color: _primaryColor),
              ),
            ),
            accountName: Text(
              user?.displayName ?? "Administrador",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user?.email ?? "admin@empresa.com"),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            selected: true,
            selectedColor: _primaryColor,
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.point_of_sale),
            title: const Text('Nueva Venta'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/new-sale');
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Gestión de Ventas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/sales-management');
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Productos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/products');
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outlined),
            title: const Text('Clientes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/customers');
            },
          ),
          ListTile(
            leading: const Icon(Icons.store_outlined),
            title: const Text('Proveedores'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/providers');
            },
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Tiendas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/stores');
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('Empleados'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/employees');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reportes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reports');
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Pagos Stripe'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/stripe-payment');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configuración'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: _logout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 30),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
