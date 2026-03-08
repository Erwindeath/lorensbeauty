import 'package:flutter/material.dart';
import 'package:lorensbeauty/controller/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminEmployeesManagementScreen extends StatefulWidget {
  const AdminEmployeesManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminEmployeesManagementScreen> createState() =>
      _AdminEmployeesManagementScreenState();
}

class _AdminEmployeesManagementScreenState
    extends State<AdminEmployeesManagementScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String _search = '';
  String? _error;

  List<_ProfileItem> _employees = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List rows;
      try {
        rows = await _client
            .from('user_profiles')
            .select('id, full_name, email, phone, role, is_active, created_at')
            .eq('role', 'employee')
            .order('created_at', ascending: false);
      } catch (_) {
        rows = await _client
            .from('user_profiles')
            .select('id, full_name, phone, role, is_active, created_at')
            .eq('role', 'employee')
            .order('created_at', ascending: false);
      }

      final all = (rows as List)
          .map((e) => _ProfileItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (!mounted) return;
      setState(() {
        _employees = all;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar empleados. $e';
      });
    }
  }

  Future<void> _setRole(String profileId, String role) async {
    setState(() => _saving = true);
    try {
      await _client.from('user_profiles').update({'role': role}).eq('id', profileId);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(role == 'employee'
              ? 'Cliente convertido a empleado.'
              : 'Empleado convertido a cliente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar rol: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleActive(_ProfileItem item, bool value) async {
    setState(() => _saving = true);
    try {
      await _client
          .from('user_profiles')
          .update({'is_active': value}).eq('id', item.id);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cambiar estado: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendResetToEmployee(_ProfileItem item) async {
    final email = item.email?.trim();
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este empleado no tiene correo en el perfil.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final ok = await Authentication.resetPassword(email: email);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Se envio enlace de recuperacion a $email'
              : 'No se pudo enviar enlace a $email'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ok ? null : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error enviando recuperacion: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openCreateEmployeeDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        var showPassword = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            InputDecoration deco({
              required String label,
              required IconData icon,
              Widget? suffixIcon,
            }) {
              return InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon, size: 18, color: const Color(0xff721c80)),
                suffixIcon: suffixIcon,
                filled: true,
                fillColor: const Color(0xffF8F5FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xff721c80), width: 1.2),
                ),
              );
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xff721c80), Color(0xffB35DA0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(22),
                          topRight: Radius.circular(22),
                        ),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.badge_outlined, color: Colors.white, size: 18),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Nuevo empleado',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: nameCtrl,
                              decoration: deco(label: 'Nombre completo', icon: Icons.person_outline),
                              validator: (v) => (v == null || v.trim().length < 3)
                                  ? 'Ingresa un nombre valido'
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: deco(label: 'Correo', icon: Icons.alternate_email),
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty || !value.contains('@')) {
                                  return 'Correo invalido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: deco(
                                label: 'Telefono (opcional)',
                                icon: Icons.phone_outlined,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: passCtrl,
                              obscureText: !showPassword,
                              decoration: deco(
                                label: 'Contrasena temporal',
                                icon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  onPressed: () => setDialogState(() {
                                    showPassword = !showPassword;
                                  }),
                                  icon: Icon(
                                    showPassword ? Icons.visibility_off : Icons.visibility,
                                    size: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 6)
                                  ? 'Minimo 6 caracteres'
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xffF3ECF6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Este acceso es temporal. El empleado puede cambiar su clave luego.',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xff721c80),
                                side: const BorderSide(color: Color(0xff721c80)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;
                                      setState(() => _saving = true);
                                      final navigator = Navigator.of(context);
                                      try {
                                        final user = await Authentication.createEmployee(
                                          email: emailCtrl.text.trim(),
                                          password: passCtrl.text.trim(),
                                          fullName: nameCtrl.text.trim(),
                                          phone: phoneCtrl.text.trim().isEmpty
                                              ? null
                                              : phoneCtrl.text.trim(),
                                        );

                                        if (!mounted) return;
                                        navigator.pop();
                                        setState(() => _saving = false);

                                        if (user == null) {
                                          ScaffoldMessenger.of(this.context).showSnackBar(
                                            const SnackBar(
                                              content: Text('No se pudo crear el empleado.'),
                                              behavior: SnackBarBehavior.floating,
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        await _loadData();
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(this.context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Empleado creado correctamente.'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        setState(() => _saving = false);
                                        ScaffoldMessenger.of(this.context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error al crear empleado: $e'),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                              icon: _saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.person_add_alt_1, size: 18),
                              label: Text(_saving ? 'Creando...' : 'Crear'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff721c80),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final employeesFiltered = _employees.where(_matchesSearch).toList();
    final activeEmployees = _employees.where((e) => e.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de Empleados'),
        backgroundColor: const Color(0xff721c80),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _saving ? null : _openCreateEmployeeDialog,
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Nuevo empleado',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xff721c80),
        child: _loading
            ? ListView(
                children: [
                  SizedBox(height: 180),
                  Center(
                    child: CircularProgressIndicator(color: Color(0xff721c80)),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          'Total empleados',
                          '${_employees.length}',
                          const Color(0xff721c80),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _metricCard(
                          'Activos',
                          '$activeEmployees',
                          const Color(0xff10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _search = value.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o telefono',
                      prefixIcon: const Icon(Icons.search, color: Color(0xff721c80)),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _sectionTitle('Empleados'),
                  const SizedBox(height: 8),
                  if (employeesFiltered.isEmpty)
                    _emptyCard('No hay empleados para mostrar.')
                  else
                    ...employeesFiltered.map(_employeeTile),
                ],
              ),
      ),
    );
  }

  bool _matchesSearch(_ProfileItem item) {
    if (_search.isEmpty) return true;
    final name = item.fullName.toLowerCase();
    final phone = (item.phone ?? '').toLowerCase();
    return name.contains(_search) || phone.contains(_search);
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xff721c80),
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _employeeTile(_ProfileItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xff721c80).withOpacity(0.1),
            child: const Icon(Icons.person, color: Color(0xff721c80), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (item.email != null && item.email!.isNotEmpty)
                  Text(
                    item.email!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                if (item.phone != null && item.phone!.isNotEmpty)
                  Text(item.phone!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: item.isActive,
            activeColor: const Color(0xff721c80),
            onChanged: _saving ? null : (value) => _toggleActive(item, value),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') {
                _sendResetToEmployee(item);
              }
              if (value == 'to_client') {
                _setRole(item.id, 'client');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem<String>(
                value: 'reset',
                child: Text('Reenviar acceso'),
              ),
              const PopupMenuItem<String>(
                value: 'to_client',
                child: Text('Mover a clientes'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(color: Colors.grey.shade700)),
    );
  }
}

class _ProfileItem {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String role;
  final bool isActive;

  const _ProfileItem({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
  });

  factory _ProfileItem.fromJson(Map<String, dynamic> json) {
    final name = (json['full_name']?.toString() ?? '').trim();
    return _ProfileItem(
      id: json['id'].toString(),
      fullName: name.isEmpty ? 'Sin nombre' : name,
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'client',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
