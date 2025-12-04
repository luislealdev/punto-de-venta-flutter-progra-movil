import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/sale_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../providers/employee_provider.dart';
import '../../../providers/supplier_provider.dart';
import '../../../providers/store_provider.dart';

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

  User? user;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    // Usamos addPostFrameCallback para cargar datos después del primer build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    // No establecemos _isLoading a true aquí porque queremos que los providers manejen su estado
    // y la UI reaccione a ellos. Pero para la carga inicial completa, podemos usar un estado local si queremos bloquear.
    // Sin embargo, la idea es que sea fluido.
    
    try {
      final companyId = _authService.currentCompanyId;
      if (companyId == null) return;

      // Cargar todos los datos necesarios
      final saleProvider = Provider.of<SaleProvider>(context, listen: false);
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);

      // Ejecutar cargas en paralelo
      await Future.wait([
        if (saleProvider.sales.isEmpty) saleProvider.loadSales(companyId),
        if (customerProvider.customers.isEmpty) customerProvider.loadCustomers(companyId),
        if (productProvider.products.isEmpty) productProvider.loadProducts(companyId),
        subscriptionProvider.checkSubscription(companyId), // Siempre verificar suscripción
        if (employeeProvider.employees.isEmpty) employeeProvider.loadEmployees(companyId),
        if (supplierProvider.providers.isEmpty) supplierProvider.loadProviders(companyId),
        if (storeProvider.stores.isEmpty) storeProvider.loadStores(companyId),
      ]);

    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshDashboard() async {
    final companyId = _authService.currentCompanyId;
    if (companyId == null) return;

    final saleProvider = Provider.of<SaleProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    
    await Future.wait([
      saleProvider.refreshSales(companyId),
      customerProvider.loadCustomers(companyId),
      productProvider.loadProducts(companyId),
      subscriptionProvider.checkSubscription(companyId),
    ]);
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
    // Consumir providers
    final saleProvider = Provider.of<SaleProvider>(context);
    final customerProvider = Provider.of<CustomerProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    
    // Calcular métricas derivadas
    final subscription = subscriptionProvider.subscription;
    
    // Clientes nuevos hoy
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final newCustomersToday = customerProvider.customers.where((c) {
      return c.createdAt != null && c.createdAt!.isAfter(startOfDay);
    }).length;

    // Productos inactivos
    final inactiveProducts = productProvider.products.where((p) => p.isActive == false).length;

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
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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

              // Subscription Status Card
              if (subscription != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: subscription.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: subscription.isActive ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        subscription.isActive ? Icons.check_circle : Icons.warning,
                        color: subscription.isActive ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subscription.isActive ? 'Suscripción Activa' : 'Suscripción Inactiva',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: subscription.isActive ? Colors.green[800] : Colors.red[800],
                              ),
                            ),
                            if (subscription.endDate != null)
                              Text(
                                'Vence el: ${subscription.endDate!.toString().split(' ')[0]}',
                                style: TextStyle(
                                  color: subscription.isActive ? Colors.green[800] : Colors.red[800],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!subscription.isActive)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/stripe-payment');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Renovar'),
                        ),
                    ],
                  ),
                ),

              // Stats Cards
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                        double childAspectRatio =
                            constraints.maxWidth > 600 ? 1.5 : 1.2;

                        // Calcular porcentaje de cambio vs ayer
                        final yesterdaySales = saleProvider.yesterdaySales;
                        final totalSales = saleProvider.totalSales;
                        
                        final percentChange = yesterdaySales > 0
                            ? ((totalSales - yesterdaySales) / yesterdaySales * 100)
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
                              '\$${totalSales.toStringAsFixed(2)}',
                              Icons.attach_money,
                              Colors.green,
                              changeText,
                            ),
                            _buildStatCard(
                              'Pedidos',
                              '${saleProvider.totalOrders}',
                              Icons.shopping_bag_outlined,
                              Colors.orange,
                              '${saleProvider.pendingOrders} pendientes',
                            ),
                            _buildStatCard(
                              'Clientes',
                              '${customerProvider.customers.length}',
                              Icons.people_outline,
                              Colors.blue,
                              '+$newCustomersToday nuevos hoy',
                            ),
                            _buildStatCard(
                              'Alerta',
                              '$inactiveProducts',
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
                    : saleProvider.recentSales.isEmpty
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
                            itemCount: saleProvider.recentSales.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final sale = saleProvider.recentSales[index];
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
