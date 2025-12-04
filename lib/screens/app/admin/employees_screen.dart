import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/employee_dto.dart';
import '../../../services/employee_service.dart';
import '../../../services/auth_service.dart';
import '../../../providers/employee_provider.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen>
    with SingleTickerProviderStateMixin {
  final EmployeeService _employeeService = EmployeeService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  List<EmployeeDTO> _allEmployees = [];
  List<EmployeeDTO> _filteredEmployees = [];
  bool _isLoading = true;
  String _filterPosition = 'Todos';
  String _filterStatus = 'Activos';
  late AnimationController _animationController;

  final Color _primaryColor = const Color(0xFF1A237E);
  final Color _accentColor = const Color(0xFF00BFA5);

  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      _isFirstLoad = false;
      // Usar addPostFrameCallback para evitar errores de construcción
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEmployees();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    final companyId = _authService.currentCompanyId;
    if (companyId == null) return;

    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    
    // Si ya hay datos, mostrarlos inmediatamente sin loading
    if (employeeProvider.employees.isNotEmpty) {
      setState(() {
        _allEmployees = employeeProvider.employees;
        _applyFilters();
        _isLoading = false;
      });
      _animationController.forward();
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('🔍 EmployeesScreen - Loading employees for companyId: $companyId');
      
      await employeeProvider.loadEmployees(companyId);
      print('✅ EmployeesScreen - Loaded ${employeeProvider.employees.length} employees');
      
      if (mounted) {
        setState(() {
          _allEmployees = employeeProvider.employees;
          _applyFilters();
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      print('❌ EmployeesScreen - Error loading employees: $e');
      if (mounted) {
        setState(() {
          _allEmployees = [];
          _filteredEmployees = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar empleados: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    var filtered = _allEmployees;

    // Filtrar por estado
    if (_filterStatus == 'Activos') {
      filtered = filtered.where((e) => e.isActive).toList();
    } else if (_filterStatus == 'Inactivos') {
      filtered = filtered.where((e) => !e.isActive).toList();
    }

    // Filtrar por posición
    if (_filterPosition != 'Todos') {
      filtered = filtered.where((e) => e.position == _filterPosition).toList();
    }

    // Filtrar por búsqueda
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((e) {
        return e.displayName.toLowerCase().contains(searchTerm) ||
            e.email.toLowerCase().contains(searchTerm) ||
            (e.phone?.contains(searchTerm) ?? false);
      }).toList();
    }

    setState(() => _filteredEmployees = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              'Gestión de Empleados',
              textStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              speed: const Duration(milliseconds: 100),
            ),
          ],
          totalRepeatCount: 1,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmployees,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatsCards(),
          Expanded(
            child: _isLoading ? _buildShimmerList() : _buildEmployeeList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEmployee(),
        backgroundColor: _accentColor,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Nuevo Empleado',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _applyFilters(),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, email o teléfono...',
          prefixIcon: Icon(Icons.search, color: _primaryColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryColor.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final activeCount = _allEmployees.where((e) => e.isActive).length;
    final totalPayroll = _allEmployees
        .where((e) => e.isActive)
        .fold<double>(0, (sum, e) => sum + e.salary);

    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              _allEmployees.length.toString(),
              Icons.people,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Activos',
              activeCount.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Nómina',
              '\$${NumberFormat('#,##0').format(totalPayroll)}',
              Icons.payments,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 1),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.grey[300]),
              title: Container(
                height: 16,
                width: double.infinity,
                color: Colors.grey[300],
              ),
              subtitle: Container(
                height: 12,
                width: 150,
                color: Colors.grey[300],
                margin: const EdgeInsets.only(top: 8),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmployeeList() {
    if (_filteredEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron empleados',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                _filterPosition = 'Todos';
                _filterStatus = 'Activos';
                _applyFilters();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar filtros'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = _filteredEmployees[index];
        return _buildEmployeeCard(employee, index);
      },
    );
  }

  Widget _buildEmployeeCard(EmployeeDTO employee, int index) {
    final yearsWorking = DateTime.now().difference(employee.hireDate).inDays ~/ 365;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                (index / _filteredEmployees.length).clamp(0.0, 1.0),
                1.0,
                curve: Curves.easeOut,
              ),
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.3, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  (index / _filteredEmployees.length).clamp(0.0, 1.0),
                  1.0,
                  curve: Curves.easeOut,
                ),
              ),
            ),
            child: child,
          ),
        );
      },
      child: Slidable(
        key: ValueKey(employee.employeeId),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _editEmployee(employee),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Editar',
            ),
            SlidableAction(
              onPressed: (_) => _toggleEmployeeStatus(employee),
              backgroundColor: employee.isActive ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
              icon: employee.isActive ? Icons.block : Icons.check_circle,
              label: employee.isActive ? 'Desactivar' : 'Activar',
            ),
            SlidableAction(
              onPressed: (_) => _deleteEmployee(employee),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Eliminar',
            ),
          ],
        ),
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Hero(
              tag: 'employee-${employee.employeeId}',
              child: CircleAvatar(
                radius: 30,
                backgroundColor: _primaryColor,
                backgroundImage:
                    employee.photoURL != null ? NetworkImage(employee.photoURL!) : null,
                child: employee.photoURL == null
                    ? Text(
                        employee.displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 24),
                      )
                    : null,
              ),
            ),
            title: Text(
              employee.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.work_outline, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(employee.position),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        employee.email,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('$yearsWorking ${yearsWorking == 1 ? 'año' : 'años'}'),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: employee.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    employee.isActive ? 'Activo' : 'Inactivo',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${NumberFormat('#,##0').format(employee.salary)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _accentColor,
                  ),
                ),
              ],
            ),
            onTap: () => _showEmployeeDetails(employee),
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempPosition = _filterPosition;
        String tempStatus = _filterStatus;

        final positions = ['Todos', ...
          _allEmployees.map((e) => e.position).toSet().toList()..sort()
        ];

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filtros'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: tempStatus,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: ['Todos', 'Activos', 'Inactivos']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => tempStatus = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: tempPosition,
                    decoration: const InputDecoration(labelText: 'Posición'),
                    items: positions
                        .map((position) => DropdownMenuItem(
                              value: position,
                              child: Text(position),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => tempPosition = value!);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    this.setState(() {
                      _filterStatus = tempStatus;
                      _filterPosition = tempPosition;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEmployeeDetails(EmployeeDTO employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: _primaryColor,
                    backgroundImage: employee.photoURL != null
                        ? NetworkImage(employee.photoURL!)
                        : null,
                    child: employee.photoURL == null
                        ? Text(
                            employee.displayName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 40),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    employee.displayName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    employee.position,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(Icons.email, 'Email', employee.email),
                  if (employee.phone != null)
                    _buildDetailRow(Icons.phone, 'Teléfono', employee.phone!),
                  if (employee.department != null)
                    _buildDetailRow(Icons.business, 'Departamento', employee.department!),
                  _buildDetailRow(
                    Icons.attach_money,
                    'Salario',
                    '\$${NumberFormat('#,##0.00').format(employee.salary)}',
                  ),
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Fecha de Contratación',
                    DateFormat('dd/MM/yyyy').format(employee.hireDate),
                  ),
                  if (employee.address != null)
                    _buildDetailRow(Icons.location_on, 'Dirección', employee.address!),
                  if (employee.emergencyContact != null)
                    _buildDetailRow(
                      Icons.contact_emergency,
                      'Contacto de Emergencia',
                      '${employee.emergencyContact} - ${employee.emergencyPhone ?? 'N/A'}',
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _editEmployee(employee);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _toggleEmployeeStatus(employee);
                          },
                          icon: Icon(employee.isActive ? Icons.block : Icons.check_circle),
                          label: Text(employee.isActive ? 'Desactivar' : 'Activar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                employee.isActive ? Colors.orange : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddEmployee() async {
    final result = await Navigator.pushNamed(context, '/add-employee');
    if (result == true) {
      _loadEmployees();
    }
  }

  Future<void> _editEmployee(EmployeeDTO employee) async {
    final result = await Navigator.pushNamed(
      context,
      '/edit-employee',
      arguments: employee,
    );
    if (result == true) {
      _loadEmployees();
    }
  }

  Future<void> _toggleEmployeeStatus(EmployeeDTO employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(employee.isActive ? 'Desactivar Empleado' : 'Activar Empleado'),
        content: Text(
          employee.isActive
              ? '¿Estás seguro de desactivar a ${employee.displayName}?'
              : '¿Estás seguro de reactivar a ${employee.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: employee.isActive ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(employee.isActive ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final companyId = _authService.currentCompanyId;
        if (companyId != null && employee.employeeId != null) {
          if (employee.isActive) {
            await _employeeService.deactivateEmployee(companyId, employee.employeeId!);
          } else {
            await _employeeService.reactivateEmployee(companyId, employee.employeeId!);
          }
          _loadEmployees();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  employee.isActive
                      ? 'Empleado desactivado'
                      : 'Empleado reactivado',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteEmployee(EmployeeDTO employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Empleado'),
        content: Text(
          '¿Estás seguro de eliminar permanentemente a ${employee.displayName}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final companyId = _authService.currentCompanyId;
        if (companyId != null && employee.employeeId != null) {
          await _employeeService.delete(companyId, employee.employeeId!);
          _loadEmployees();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Empleado eliminado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }
}
