import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// For Chrome on the same computer as Laravel, keep this address.
// For an Android emulator, use http://10.0.2.2:8000/api instead.
const String apiBaseUrl = 'http://127.0.0.1:8000/api';

const Color purple = Color(0xFF6D28D9);
const Color deepPurple = Color(0xFF4C1D95);
const Color lavender = Color(0xFFA78BFA);
const Color pageBackground = Color(0xFFF7F5FC);
const Color mutedText = Color(0xFF77718A);

void main() => runApp(const AppointmentReminderApp());

// ============================================================
// APPOINTMENT MODEL
// ============================================================

class AppointmentRecord {
  const AppointmentRecord({
    required this.id,
    required this.name,
    required this.service,
    required this.destination,
    required this.status,
    required this.attempts,
    required this.maxAttempts,
    required this.simulationMode,
    required this.appointmentAt,
    required this.reminderAt,
    required this.nextAttemptAt,
    required this.lastError,
    required this.logs,
  });

  final int id;
  final String name;
  final String service;
  final String destination;
  final String status;
  final int attempts;
  final int maxAttempts;
  final String simulationMode;
  final DateTime? appointmentAt;
  final DateTime? reminderAt;
  final DateTime? nextAttemptAt;
  final String? lastError;
  final List<Map<String, dynamic>> logs;

  factory AppointmentRecord.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString())?.toLocal();
    }

    final rawLogs = json['logs'] as List? ?? [];

    return AppointmentRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      status: json['status']?.toString() ?? 'scheduled',
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      maxAttempts: (json['max_attempts'] as num?)?.toInt() ?? 3,
      simulationMode: json['simulation_mode']?.toString() ?? 'success',
      appointmentAt: parseDate(json['appointment_at']),
      reminderAt: parseDate(json['reminder_at']),
      nextAttemptAt: parseDate(json['next_attempt_at']),
      lastError: json['last_error']?.toString(),
      logs: rawLogs
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(),
    );
  }
}

// ============================================================
// LARAVEL API SERVICE
// ============================================================
class AppointmentApi {
  String? token;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<dynamic> _handle(http.Response response) async {
    dynamic result;

    try {
      result = jsonDecode(response.body);
    } catch (_) {
      result = response.body;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Request failed (${response.statusCode}).';

      if (result is Map) {
        message = result['message']?.toString() ?? message;

        final errors = result['errors'];

        if (errors is Map) {
          final details = errors.values
              .expand((value) => value is List ? value : [value])
              .join('\n');

          if (details.isNotEmpty) {
            message = '$message\n$details';
          }
        }
      }

      throw Exception(message);
    }

    return result;
  }

  // LOGIN
  Future<Map<String, dynamic>> login(
      String email,
      String password,
      ) async {
    final response = await http
        .post(
      Uri.parse('$apiBaseUrl/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    )
        .timeout(const Duration(seconds: 12));

    final result = await _handle(response);

    if (result is! Map ||
        result['token'] == null ||
        result['user'] is! Map) {
      throw Exception('Invalid login response from the server.');
    }

    token = result['token'].toString();

    return Map<String, dynamic>.from(result['user']);
  }

  // LOGOUT
  Future<void> logout() async {
    if (token == null) return;

    try {
      final response = await http
          .post(
        Uri.parse('$apiBaseUrl/logout'),
        headers: _headers,
      )
          .timeout(const Duration(seconds: 12));

      await _handle(response);
    } finally {
      token = null;
    }
  }

  // GET APPOINTMENTS
  Future<List<AppointmentRecord>> getAppointments() async {
    final response = await http
        .get(
      Uri.parse('$apiBaseUrl/appointments'),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 12));

    final result = await _handle(response);

    if (result is! List) {
      throw Exception('The appointments API did not return a JSON list.');
    }

    return result
        .whereType<Map>()
        .map(
          (entry) => AppointmentRecord.fromJson(
        Map<String, dynamic>.from(entry),
      ),
    )
        .toList();
  }

  // POST REQUESTS
  Future<dynamic> post(
      String path, {
        Map<String, dynamic>? body,
      }) async {
    final response = await http
        .post(
      Uri.parse('$apiBaseUrl$path'),
      headers: _headers,
      body: jsonEncode(body ?? <String, dynamic>{}),
    )
        .timeout(const Duration(seconds: 12));

    return _handle(response);
  }
}

// ============================================================
// APPLICATION THEME
// ============================================================

class AppointmentReminderApp extends StatelessWidget {
  const AppointmentReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: purple,
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Appointment Reminder System',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: pageBackground,
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: deepPurple,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFECE7F5)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFAF9FD),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: purple,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ============================================================
// ============================================================
// WEEK 14 - LOGIN SCREEN
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AppointmentApi api = AppointmentApi();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      setState(() => errorMessage = 'Enter your email and password.');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final user = await api.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AppointmentDashboard(
            api: api,
            user: user,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Color(0xFFF0E9FF),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        color: purple,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Welcome to Remindly',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: deepPurple,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Sign in to manage your appointments and reminders.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mutedText, fontSize: 13),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      onSubmitted: (_) {
                        if (!loading) login();
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEEEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFAA3030),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: loading ? null : login,
                      child: loading
                          ? const SizedBox(
                              width: 21,
                              height: 21,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Secure login powered by Laravel Sanctum',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mutedText, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// MAIN DASHBOARD AND NAVIGATION
// ============================================================

class AppointmentDashboard extends StatefulWidget {
  const AppointmentDashboard({
    super.key,
    required this.api,
    required this.user,
  });

  final AppointmentApi api;
  final Map<String, dynamic> user;

  @override
  State<AppointmentDashboard> createState() => _AppointmentDashboardState();
}

class _AppointmentDashboardState extends State<AppointmentDashboard> {

  final TextEditingController logSearchController = TextEditingController();

  List<AppointmentRecord> appointments = [];
  bool loading = true;
  bool busy = false;
  String? errorMessage;

  int selectedPage = 0;
  DateTime calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime selectedCalendarDate = DateTime.now();
  String logFilter = 'all';
  String logSearch = '';

  // These settings are local demo preferences only. They are not saved by Laravel.
  bool emailRemindersEnabled = true;
  bool smsRemindersEnabled = true;
  bool pushRemindersEnabled = false;
  bool showDemoLabels = true;
  double maxRetryAttempts = 3;

  static const List<String> pageTitles = [
    'Dashboard',
    'Appointments Calendar',
    '4.6 Reminder Status & Delivery Logs',
    'System Settings',
  ];

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  @override
  void dispose() {
    logSearchController.dispose();
    super.dispose();
  }

  Future<void> loadAppointments({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

    try {
      final data = await widget.api.getAppointments();
      if (!mounted) return;
      setState(() {
        appointments = data;
        loading = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage =
        'Could not load appointments.\n$error\n\n'
            'Make sure Laravel is running at 127.0.0.1:8000.';
      });
    }
  }

  void selectPage(int index) {
    setState(() => selectedPage = index);
    if (index == 0 || index == 1 || index == 2) {
      loadAppointments(showLoading: false);
    }
  }

  int count(String status) =>
      appointments.where((item) => item.status == status).length;

  Future<void> runAction(
      String successMessage,
      Future<void> Function() action,
      ) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
      await loadAppointments(showLoading: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> createAppointment() async {
    final input = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const AppointmentFormDialog(),
    );
    if (input == null) return;

    final appointmentAt = input['appointmentAt'] as DateTime;
    final reminderAt = appointmentAt.subtract(const Duration(hours: 1));

    await runAction('Appointment created successfully.', () async {
      await widget.api.post(
        '/appointments',
        body: {
          'name': input['name'],
          'service': input['service'],
          'destination': input['destination'],
          'appointment_at': appointmentAt.toUtc().toIso8601String(),
          'reminder_at': reminderAt.toUtc().toIso8601String(),
          'simulation_mode': input['simulationMode'],
        },
      );
    });
  }

  Future<void> cancelAppointment(AppointmentRecord item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: Text('Cancel "${item.name}"? This action will be sent to Laravel.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep appointment'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm cancel'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await runAction('Appointment cancelled.', () async {
      await widget.api.post('/appointments/${item.id}/cancel');
    });
  }

  Future<void> rescheduleAppointment(AppointmentRecord item) async {
    final input = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => RescheduleDialog(appointment: item),
    );
    if (input == null) return;

    final newDate = input['appointmentAt'] as DateTime;
    final newReminder = newDate.subtract(const Duration(hours: 1));

    await runAction('Appointment schedule updated in Laravel.', () async {
      // This uses the existing /schedule endpoint and sends the new date/time.
      // The backend must accept and persist appointment_at and reminder_at.
      await widget.api.post(
        '/appointments/${item.id}/schedule',
        body: {
          'appointment_at': newDate.toUtc().toIso8601String(),
          'reminder_at': newReminder.toUtc().toIso8601String(),
          'reason': input['reason'],
        },
      );

      // Verify that Laravel actually saved the new date before showing success.
      final refreshed = await widget.api.getAppointments();
      final updated = refreshed.firstWhere(
            (record) => record.id == item.id,
        orElse: () => throw Exception('Appointment was not returned by Laravel.'),
      );
      if (updated.appointmentAt == null ||
          !updated.appointmentAt!.isAtSameMomentAs(newDate)) {
        throw Exception(
          'Laravel did not update the appointment date. The /schedule endpoint '
              'may need backend changes to accept appointment_at and reminder_at.',
        );
      }
    });
  }

  Future<void> resolveReview(AppointmentRecord item) async {
    final controller = TextEditingController(
      text: 'Reviewed the simulated delivery failure and confirmed the destination.',
    );

    final resolution = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resolve manual review'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Review action taken',
              hintText: 'Describe the action taken',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Back'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (controller.text.trim().length < 5) return;
              Navigator.pop(dialogContext, controller.text.trim());
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirm review'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (resolution == null) return;

    await runAction('Review submitted to Laravel.', () async {
      await widget.api.post(
        '/appointments/${item.id}/resolve-review',
        body: {
          'resolution': resolution,
          'simulation_mode': 'success',
        },
      );
    });
  }

  Future<void> logout() async {
    try {
      await widget.api.logout();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout request failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  String formatMonth(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String statusLabel(String status) => status
      .replaceAll('_', ' ')
      .split(' ')
      .map((part) => part.isEmpty
      ? part
      : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  Color statusColor(String status) {
    switch (status) {
      case 'delivered':
        return const Color(0xFF16845B);
      case 'manual_review':
        return const Color(0xFFDC4545);
      case 'retrying':
        return const Color(0xFFCB7A12);
      case 'expired':
        return const Color(0xFF64748B);
      case 'cancelled':
        return const Color(0xFF7B8496);
      default:
        return purple;
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'manual_review':
        return Icons.support_agent_rounded;
      case 'retrying':
        return Icons.refresh_rounded;
      case 'expired':
        return Icons.event_busy_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule_rounded;
    }
  }

  List<Map<String, dynamic>> get allLogs {
    final entries = <Map<String, dynamic>>[];
    for (final item in appointments) {
      for (final log in item.logs) {
        entries.add({
          ...log,
          'appointment_id': item.id,
          'appointment_name': item.name,
          'destination': item.destination,
        });
      }
    }
    DateTime logDate(Map<String, dynamic> log) =>
        DateTime.tryParse(log['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
    entries.sort((a, b) => logDate(b).compareTo(logDate(a)));
    return entries;
  }

  List<Map<String, dynamic>> get filteredLogs {
    return allLogs.where((log) {
      final level = log['level']?.toString().toLowerCase() ?? '';
      final event = log['event']?.toString().toLowerCase() ?? '';
      final message = log['message']?.toString().toLowerCase() ?? '';
      final matchesFilter = logFilter == 'all' ||
          (logFilter == 'warning' && level == 'warning') ||
          (logFilter == 'success' && level != 'warning');
      final query = logSearch.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          event.contains(query) ||
          message.contains(query) ||
          (log['appointment_name']?.toString().toLowerCase().contains(query) ?? false) ||
          (log['destination']?.toString().toLowerCase().contains(query) ?? false);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1000;

    return Scaffold(
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
        selectedIndex: selectedPage,
        onDestinationSelected: selectPage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_active_rounded),
            label: '4.6 Logs',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (wide) _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => loadAppointments(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(wide ? 28 : 16),
                        children: [
                          if (errorMessage != null) ...[
                            _buildErrorPanel(),
                            const SizedBox(height: 16),
                          ],
                          _buildCurrentPage(),
                          const SizedBox(height: 22),
                          _buildFooter(),
                        ],
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
  }

  Widget _buildCurrentPage() {
    switch (selectedPage) {
      case 1:
        return _buildCalendarPage();
      case 2:
        return _buildLogsPage();
      case 3:
        return _buildSettingsPage();
      default:
        return _buildDashboardPage();
    }
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: const Color(0xFF32105F),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active_rounded,
                  color: Colors.white, size: 32),
              SizedBox(width: 10),
              Expanded(
                child: Text('Remindly',
                    style: TextStyle(color: Colors.white,
                        fontSize: 22, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('APPOINTMENT SYSTEM',
              style: TextStyle(color: Color(0xFFD5C5F5), fontSize: 10)),
          const SizedBox(height: 34),
          const Text('WORKSPACE',
              style: TextStyle(color: Color(0xFFB9A3DE),
                  fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _navigationTile(0, 'Dashboard', Icons.dashboard_rounded),
          _navigationTile(1, 'Appointments Calendar', Icons.calendar_month_rounded),
          _navigationTile(2, '4.6 Reminder Status & Delivery Logs', Icons.notifications_active_rounded),
          _navigationTile(3, 'System Settings', Icons.settings_rounded),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFFD7C4FF), size: 25),
                SizedBox(height: 10),
                Text('Automation active',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text('Processing is managed by the Laravel backend.',
                    style: TextStyle(color: Color(0xFFD5C5F5),
                        fontSize: 12, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('WEEK 13  •  SA7',
              style: TextStyle(color: Color(0xFFB9A3DE), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _navigationTile(int index, String title, IconData icon) {
    final selected = selectedPage == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: ListTile(
        selected: selected,
        selectedTileColor: purple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: Colors.white, size: 21),
        title: Text(title,
            style: const TextStyle(color: Colors.white,
                fontSize: 12, fontWeight: FontWeight.w600)),
        onTap: () => selectPage(index),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFECE7F5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pageTitles[selectedPage],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: deepPurple,
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 3),
                const Text('Week 13 · Automation Foundation',
                    style: TextStyle(color: mutedText, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh appointments',
            onPressed: busy ? null : () => loadAppointments(),
            icon: const Icon(Icons.refresh_rounded, color: purple),
          ),
          const SizedBox(width: 5),
          if (MediaQuery.sizeOf(context).width > 520) ...[
            const Chip(
              avatar: Icon(Icons.cloud_done_rounded, color: purple, size: 17),
              label: Text('Laravel API'),
              backgroundColor: Color(0xFFF0E9FF),
            ),
            const SizedBox(width: 8),
            Chip(
              avatar: const Icon(Icons.account_circle, color: purple, size: 18),
              label: Text(
                '${widget.user['name']} · ${widget.user['role']}',
              ),
              backgroundColor: const Color(0xFFF0E9FF),
            ),
          ],
          IconButton(
            tooltip: 'Logout',
            onPressed: busy ? null : logout,
            icon: const Icon(Icons.logout_rounded, color: purple),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DASHBOARD PAGE
  // ============================================================

  Widget _buildDashboardPage() {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1200 ? 4 : width >= 700 ? 3 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeBanner(),
        const SizedBox(height: 18),
        _buildDemoNotice(),
        const SizedBox(height: 25),
        _sectionHeading('Dashboard overview',
            'A quick look at your appointment activity.', Icons.grid_view_rounded),
        const SizedBox(height: 14),
        if (loading && appointments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(35),
            child: Center(child: CircularProgressIndicator(color: purple)),
          )
        else
          GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: width < 400 ? 1.05 : 1.45,
            children: [
              MetricCard(title: 'Total appointments', value: appointments.length,
                  icon: Icons.calendar_month_rounded, accent: purple),
              MetricCard(title: 'Scheduled', value: count('scheduled'),
                  icon: Icons.schedule_rounded, accent: const Color(0xFF7C3AED)),
              MetricCard(title: 'Delivered (simulated)', value: count('delivered'),
                  icon: Icons.mark_email_read_rounded, accent: const Color(0xFF16845B)),
              MetricCard(title: 'Retrying', value: count('retrying'),
                  icon: Icons.sync_rounded, accent: const Color(0xFFCB7A12)),
              MetricCard(title: 'Manual review', value: count('manual_review'),
                  icon: Icons.support_agent_rounded, accent: const Color(0xFFDC4545)),
              MetricCard(title: 'Expired', value: count('expired'),
                  icon: Icons.event_busy_rounded, accent: const Color(0xFF64748B)),
              MetricCard(title: 'Cancelled', value: count('cancelled'),
                  icon: Icons.event_busy_outlined, accent: const Color(0xFF8B849B)),
            ],
          ),
        const SizedBox(height: 28),
        _sectionHeading(
          'Appointment records',
          '${appointments.length} records from your Laravel API',
          Icons.event_note_rounded,
          trailing: FilledButton.icon(
            onPressed: busy ? null : createAppointment,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New appointment'),
          ),
        ),
        const SizedBox(height: 14),
        if (!loading && appointments.isEmpty)
          _emptyState()
        else
          ...appointments.map(_buildAppointmentCard),
        const SizedBox(height: 24),
        _sectionHeading('Recent automation activity',
            'Latest events returned by the Laravel API.', Icons.bolt_rounded),
        const SizedBox(height: 14),
        _buildRecentActivity(),
      ],
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: purple.withValues(alpha: 0.18),
              blurRadius: 22, offset: const Offset(0, 8)),
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 500;
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SMART REMINDER MANAGEMENT',
                      style: TextStyle(color: Color(0xFFE8DFFF),
                          fontSize: 10, letterSpacing: 1,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 17),
                  Text('Stay on top of\nevery appointment.',
                      style: TextStyle(color: Colors.white,
                          fontSize: compact ? 26 : 34,
                          height: 1.15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  const Text(
                    'Manage schedules, track reminder delivery, and review automation activity.',
                    style: TextStyle(color: Color(0xFFE9DFFF),
                        height: 1.5, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: busy ? null : createAppointment,
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.white, foregroundColor: deepPurple),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create appointment'),
                  ),
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 16),
              const Icon(Icons.calendar_month_rounded,
                  color: Color(0xFFE9DFFF), size: 75),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildDemoNotice() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E9FF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDFD0FF)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: purple, size: 22),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Demonstration mode',
                    style: TextStyle(color: deepPurple,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                  'Reminder delivery is simulated for testing. No real email, SMS, or push notification is sent.',
                  style: TextStyle(color: Color(0xFF655581),
                      fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, String subtitle, IconData icon,
      {Widget? trailing}) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE5FF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: purple, size: 22),
            ),
            const SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: deepPurple,
                    fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: mutedText, fontSize: 12)),
              ],
            ),
          ],
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildAppointmentCard(AppointmentRecord item) {
    final canCancel = !['delivered', 'expired', 'cancelled'].contains(item.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 13),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 9,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E9FF),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.event_available_rounded,
                          color: purple, size: 22),
                    ),
                    const SizedBox(width: 11),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#${item.id} · ${item.name}',
                            style: const TextStyle(color: deepPurple,
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(item.service,
                            style: const TextStyle(color: mutedText, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                _statusChip(item.status),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF0ECF7), height: 1),
            const SizedBox(height: 15),
            Wrap(
              spacing: 22,
              runSpacing: 14,
              children: [
                _detail(Icons.person_outline_rounded, 'Client', item.name),
                _detail(Icons.alternate_email_rounded, 'Destination', item.destination),
                _detail(Icons.calendar_today_rounded, 'Appointment', formatDate(item.appointmentAt)),
                _detail(Icons.notifications_none_rounded, 'Reminder', formatDate(item.reminderAt)),
                _detail(Icons.sync_rounded, 'Delivery attempts', '${item.attempts} / ${item.maxAttempts}'),
                _detail(Icons.science_outlined, 'Test scenario', item.simulationMode),
              ],
            ),
            if (item.lastError != null && item.lastError!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFC53D3D), size: 19),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.lastError!,
                        style: const TextStyle(color: Color(0xFFAA3030), fontSize: 12))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : () => loadAppointments(),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(105, 46), foregroundColor: purple),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                ),
                if (canCancel)
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => rescheduleAppointment(item),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(150, 46), foregroundColor: purple),
                    icon: const Icon(Icons.event_repeat_rounded, size: 18),
                    label: const Text('Reschedule'),
                  ),
                if (widget.user['role'] == 'admin' &&
                    item.status == 'manual_review')
                  FilledButton.icon(
                    onPressed: busy ? null : () => resolveReview(item),
                    style: FilledButton.styleFrom(
                        backgroundColor: deepPurple,
                        minimumSize: const Size(150, 46)),
                    icon: const Icon(Icons.fact_check_rounded, size: 20),
                    label: const Text('Resolve review'),
                  ),
                if (canCancel)
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => cancelAppointment(item),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB83D4A),
                        minimumSize: const Size(150, 46)),
                    icon: const Icon(Icons.cancel_outlined, size: 20),
                    label: const Text('Cancel appointment'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(status), color: color, size: 15),
          const SizedBox(width: 6),
          Text(statusLabel(status), style: TextStyle(color: color,
              fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String label, String value) {
    return SizedBox(
      width: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: lavender, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: mutedText, fontSize: 11)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Color(0xFF39304C),
                    fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(Icons.event_note_rounded, color: purple, size: 42),
            const SizedBox(height: 12),
            const Text('No appointments yet',
                style: TextStyle(color: deepPurple,
                    fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 7),
            const Text('Create an appointment to start using the reminder system.',
                textAlign: TextAlign.center,
                style: TextStyle(color: mutedText)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: busy ? null : createAppointment,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create first appointment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final logs = allLogs.take(6).toList();
    if (logs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(22),
          child: Row(
            children: [
              Icon(Icons.history_rounded, color: lavender, size: 27),
              SizedBox(width: 12),
              Expanded(child: Text('No activity logs recorded yet.',
                  style: TextStyle(color: mutedText))),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Column(
        children: logs.map((log) => _logTile(log)).toList(),
      ),
    );
  }

  // ============================================================
  // CALENDAR PAGE
  // ============================================================

  Widget _buildCalendarPage() {
    final firstDay = DateTime(calendarMonth.year, calendarMonth.month, 1);
    final daysInMonth = DateTime(calendarMonth.year, calendarMonth.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday % 7; // Sunday-first calendar.
    final cellCount = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;
    final selectedDayAppointments = appointments.where((item) {
      final date = item.appointmentAt;
      return date != null && DateUtils.isSameDay(date, selectedCalendarDate);
    }).toList()
      ..sort((a, b) => (a.appointmentAt ?? DateTime(1900))
          .compareTo(b.appointmentAt ?? DateTime(1900)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('Appointments Calendar',
            'Appointments from your Laravel records.', Icons.calendar_month_rounded,
            trailing: FilledButton.icon(
              onPressed: busy ? null : createAppointment,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New appointment'),
            )),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous month',
                      onPressed: () => setState(() {
                        calendarMonth = DateTime(calendarMonth.year, calendarMonth.month - 1);
                        selectedCalendarDate = DateTime(calendarMonth.year, calendarMonth.month, 1);
                      }),
                      icon: const Icon(Icons.chevron_left_rounded, color: purple),
                    ),
                    Expanded(
                      child: Text(formatMonth(calendarMonth),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: deepPurple,
                              fontSize: 19, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      tooltip: 'Next month',
                      onPressed: () => setState(() {
                        calendarMonth = DateTime(calendarMonth.year, calendarMonth.month + 1);
                        selectedCalendarDate = DateTime(calendarMonth.year, calendarMonth.month, 1);
                      }),
                      icon: const Icon(Icons.chevron_right_rounded, color: purple),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                      .map((day) => Expanded(
                    child: Center(
                      child: Text(day,
                          style: TextStyle(color: mutedText,
                              fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cellCount,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final day = index - leadingBlanks + 1;
                    if (day < 1 || day > daysInMonth) {
                      return const SizedBox.shrink();
                    }
                    final date = DateTime(calendarMonth.year, calendarMonth.month, day);
                    final dayItems = appointments.where((item) {
                      final value = item.appointmentAt;
                      return value != null && value.year == date.year &&
                          value.month == date.month && value.day == date.day;
                    }).toList();
                    final isToday = DateUtils.isSameDay(date, DateTime.now());
                    final isSelected = DateUtils.isSameDay(date, selectedCalendarDate);
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => selectedCalendarDate = date),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE5D8FF)
                              : isToday
                              ? const Color(0xFFF1EBFF)
                              : const Color(0xFFFAF9FD),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? purple : isToday ? lavender : const Color(0xFFECE7F5),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$day', style: TextStyle(
                                color: isSelected || isToday ? deepPurple : const Color(0xFF3F3650),
                                fontWeight: FontWeight.bold, fontSize: 11)),
                            if (dayItems.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                                decoration: BoxDecoration(
                                  color: purple.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text('${dayItems.length} appt.',
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: deepPurple,
                                        fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        _sectionHeading('Appointments on ${formatDate(selectedCalendarDate)}',
            'Showing appointments for the selected day only.', Icons.event_note_rounded),
        const SizedBox(height: 12),
        if (selectedDayAppointments.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No appointments for this day. Select another date on the calendar.',
                  style: TextStyle(color: mutedText)),
            ),
          )
        else
          ...selectedDayAppointments.map(_buildAppointmentCard),
      ],
    );
  }

  // ============================================================
  // REMINDER LOGS PAGE
  // ============================================================

  Widget _buildLogsPage() {
    final logs = filteredLogs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('4.6 Reviewing Reminder Status and Logs',
            'Chronological activity returned by your Laravel API.',
            Icons.notifications_active_rounded),
        const SizedBox(height: 12),
        _buildDemoNotice(),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                TextField(
                  controller: logSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search event, appointment, or destination',
                    prefixIcon: const Icon(Icons.search_rounded, color: purple),
                    suffixIcon: IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        logSearchController.clear();
                        setState(() => logSearch = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  onChanged: (value) => setState(() => logSearch = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: logFilter,
                  decoration: const InputDecoration(labelText: 'Filter activity'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All activity')),
                    DropdownMenuItem(value: 'success', child: Text('Informational / success')),
                    DropdownMenuItem(value: 'warning', child: Text('Warnings / failures')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => logFilter = value);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Text('Activity history',
                style: TextStyle(color: deepPurple,
                    fontSize: 17, fontWeight: FontWeight.bold))),
            Text('${logs.length} entries',
                style: const TextStyle(color: mutedText, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        if (logs.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No matching activity logs were returned by the API.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedText))),
            ),
          )
        else
          Card(child: Column(children: logs.map(_logTile).toList())),
        const SizedBox(height: 12),
        const Text(
          'Note: These are backend event logs. They do not necessarily confirm an actual SMS or email receipt. The current project uses simulated reminder delivery.',
          style: TextStyle(color: mutedText, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }

  Widget _logTile(Map<String, dynamic> log) {
    final event = log['event']?.toString() ?? 'Event';
    final message = log['message']?.toString() ?? '';
    final created = log['created_at']?.toString() ?? 'Timestamp unavailable';
    final warning = log['level']?.toString().toLowerCase() == 'warning';
    final color = warning ? const Color(0xFFCB7A12) : purple;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.10),
        child: Icon(warning ? Icons.warning_amber_rounded : Icons.bolt_rounded,
            color: color, size: 21),
      ),
      title: Text('$event · Appointment #${log['appointment_id'] ?? ''}',
          style: const TextStyle(color: deepPurple,
              fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${log['appointment_name'] ?? ''}\n$message\n$created',
          style: const TextStyle(color: mutedText, fontSize: 12, height: 1.5),
        ),
      ),
      isThreeLine: true,
    );
  }

  // ============================================================
  // SETTINGS PAGE
  // ============================================================

  Widget _buildSettingsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('System Settings',
            'Demo preferences for the reminder interface.', Icons.settings_rounded),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E8),
            border: Border.all(color: const Color(0xFFF2D9A8)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF9A6415)),
              SizedBox(width: 10),
              Expanded(child: Text(
                'These controls currently change only this screen during the session. They are not saved to Laravel and do not enable real message delivery.',
                style: TextStyle(color: Color(0xFF79551D), fontSize: 12, height: 1.5),
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reminder channels', style: TextStyle(
                    color: deepPurple, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: emailRemindersEnabled,
                  activeThumbColor: purple,
                  title: const Text('Email reminders'),
                  subtitle: const Text('Demo preference only'),
                  onChanged: (value) => setState(() => emailRemindersEnabled = value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: smsRemindersEnabled,
                  activeThumbColor: purple,
                  title: const Text('SMS reminders'),
                  subtitle: const Text('Demo preference only'),
                  onChanged: (value) => setState(() => smsRemindersEnabled = value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: pushRemindersEnabled,
                  activeThumbColor: purple,
                  title: const Text('Push notifications'),
                  subtitle: const Text('Not connected to a push provider'),
                  onChanged: (value) => setState(() => pushRemindersEnabled = value),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Automation display preferences', style: TextStyle(
                    color: deepPurple, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Retry attempt display: ${maxRetryAttempts.round()}',
                    style: const TextStyle(color: mutedText, fontSize: 13)),
                Slider(
                  value: maxRetryAttempts,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: purple,
                  label: maxRetryAttempts.round().toString(),
                  onChanged: (value) => setState(() => maxRetryAttempts = value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: showDemoLabels,
                  activeThumbColor: purple,
                  title: const Text('Show demonstration labels'),
                  subtitle: const Text('Keep simulated actions clearly identified'),
                  onChanged: (value) => setState(() => showDemoLabels = value),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Backend connection', style: TextStyle(
                    color: deepPurple, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                _SettingInfoRow(label: 'API base URL', value: apiBaseUrl),
                _SettingInfoRow(label: 'Backend', value: 'Laravel API'),
                _SettingInfoRow(label: 'Delivery mode', value: 'Simulated / test only'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorPanel() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: SelectableText(errorMessage!,
              style: const TextStyle(color: Color(0xFF9F2424)))),
          IconButton(
            onPressed: () => loadAppointments(),
            icon: const Icon(Icons.refresh_rounded, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E9FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.code_rounded, color: purple, size: 22),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'System design: Laravel manages appointment records, reminder processing, retry scheduling, expiration, and persistent logs. Flutter provides the dashboard and sends requests to the API. Reminder delivery is simulated in this version.',
              style: TextStyle(color: Color(0xFF655581),
                  fontSize: 12, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SMALL REUSABLE WIDGETS
// ============================================================

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 21),
                ),
                Text('$value', style: TextStyle(color: accent,
                    fontSize: 26, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF655B76),
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SettingInfoRow extends StatelessWidget {
  const _SettingInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 115,
              child: Text(label, style: const TextStyle(color: mutedText, fontSize: 12))),
          Expanded(child: SelectableText(value,
              style: const TextStyle(color: deepPurple,
                  fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

// ============================================================
// CREATE APPOINTMENT DIALOG
// ============================================================

class AppointmentFormDialog extends StatefulWidget {
  const AppointmentFormDialog({super.key});

  @override
  State<AppointmentFormDialog> createState() => _AppointmentFormDialogState();
}

class _AppointmentFormDialogState extends State<AppointmentFormDialog> {
  final nameController = TextEditingController();
  final serviceController = TextEditingController();
  final destinationController = TextEditingController();

  late DateTime appointmentAt;
  String simulationMode = 'success';
  String? formError;

  @override
  void initState() {
    super.initState();
    appointmentAt = DateTime.now().add(const Duration(days: 1));
    appointmentAt = DateTime(
      appointmentAt.year,
      appointmentAt.month,
      appointmentAt.day,
      appointmentAt.hour,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    serviceController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  Future<void> chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: appointmentAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: purple),
        ),
        child: child!,
      ),
    );
    if (selected == null) return;
    setState(() {
      appointmentAt = DateTime(
        selected.year, selected.month, selected.day,
        appointmentAt.hour, appointmentAt.minute,
      );
    });
  }

  Future<void> chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appointmentAt),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: purple),
        ),
        child: child!,
      ),
    );
    if (selected == null) return;
    setState(() {
      appointmentAt = DateTime(
        appointmentAt.year, appointmentAt.month, appointmentAt.day,
        selected.hour, selected.minute,
      );
    });
  }

  void submit() {
    if (nameController.text.trim().isEmpty ||
        serviceController.text.trim().isEmpty ||
        destinationController.text.trim().isEmpty) {
      setState(() => formError = 'Complete the name, service, and destination fields.');
      return;
    }
    if (!appointmentAt.isAfter(DateTime.now())) {
      setState(() => formError = 'Choose an appointment time in the future.');
      return;
    }

    Navigator.pop(context, {
      'name': nameController.text.trim(),
      'service': serviceController.text.trim(),
      'destination': destinationController.text.trim(),
      'appointmentAt': appointmentAt,
      'simulationMode': simulationMode,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Row(
        children: [
          Icon(Icons.event_available_rounded, color: purple, size: 27),
          SizedBox(width: 10),
          Expanded(child: Text('Create appointment',
              style: TextStyle(color: deepPurple, fontWeight: FontWeight.bold))),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'Student / client name',
                      prefixIcon: Icon(Icons.person_outline_rounded))),
              const SizedBox(height: 12),
              TextField(controller: serviceController,
                  decoration: const InputDecoration(
                      labelText: 'Appointment service',
                      prefixIcon: Icon(Icons.medical_services_outlined))),
              const SizedBox(height: 12),
              TextField(controller: destinationController,
                  decoration: const InputDecoration(
                      labelText: 'Email / phone destination (test data)',
                      prefixIcon: Icon(Icons.alternate_email_rounded))),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('DATE AND TIME',
                    style: TextStyle(color: purple, fontSize: 11,
                        fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: chooseDate,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: const Text('Select date'),
                  ),
                  OutlinedButton.icon(
                    onPressed: chooseTime,
                    icon: const Icon(Icons.access_time_rounded),
                    label: const Text('Select time'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E9FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(formatDate(appointmentAt),
                    style: const TextStyle(color: deepPurple,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              const Text('The reminder is scheduled one hour before the appointment.',
                  style: TextStyle(fontSize: 12, color: mutedText)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: simulationMode,
                decoration: const InputDecoration(
                  labelText: 'Delivery test scenario',
                  prefixIcon: Icon(Icons.science_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'success', child: Text('Success (simulated)')),
                  DropdownMenuItem(value: 'transient', child: Text('Temporary failure, then recovery')),
                  DropdownMenuItem(value: 'permanent', child: Text('Permanent failure / manual review')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => simulationMode = value);
                },
              ),
              if (formError != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(formError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: submit,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Create appointment'),
        ),
      ],
    );
  }
}

// ============================================================
// RESCHEDULE APPOINTMENT DIALOG
// ============================================================

class RescheduleDialog extends StatefulWidget {
  const RescheduleDialog({super.key, required this.appointment});
  final AppointmentRecord appointment;

  @override
  State<RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<RescheduleDialog> {
  late DateTime appointmentAt;
  final reasonController = TextEditingController();
  String? formError;

  @override
  void initState() {
    super.initState();
    appointmentAt = widget.appointment.appointmentAt ??
        DateTime.now().add(const Duration(days: 1));
    if (!appointmentAt.isAfter(DateTime.now())) {
      appointmentAt = DateTime.now().add(const Duration(days: 1));
    }
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  Future<void> chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: appointmentAt.isBefore(DateTime.now()) ? DateTime.now() : appointmentAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected == null) return;
    setState(() {
      appointmentAt = DateTime(selected.year, selected.month, selected.day,
          appointmentAt.hour, appointmentAt.minute);
    });
  }

  Future<void> chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appointmentAt),
    );
    if (selected == null) return;
    setState(() {
      appointmentAt = DateTime(appointmentAt.year, appointmentAt.month,
          appointmentAt.day, selected.hour, selected.minute);
    });
  }

  void submit() {
    if (!appointmentAt.isAfter(DateTime.now())) {
      setState(() => formError = 'Choose a future appointment date and time.');
      return;
    }
    if (widget.appointment.appointmentAt != null &&
        appointmentAt.isAtSameMomentAs(widget.appointment.appointmentAt!)) {
      setState(() => formError = 'Choose a different appointment date or time.');
      return;
    }
    Navigator.pop(context, {
      'appointmentAt': appointmentAt,
      'reason': reasonController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final reminderAt = appointmentAt.subtract(const Duration(hours: 1));
    return AlertDialog(
      title: const Text('Reschedule appointment',
          style: TextStyle(color: deepPurple, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Appointment #${widget.appointment.id} · ${widget.appointment.name}',
                  style: const TextStyle(color: mutedText, fontSize: 12)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: chooseDate,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: const Text('Choose date'),
                  ),
                  OutlinedButton.icon(
                    onPressed: chooseTime,
                    icon: const Icon(Icons.access_time_rounded),
                    label: const Text('Choose time'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DatePreview(label: 'New appointment', value: formatDate(appointmentAt)),
              const SizedBox(height: 8),
              _DatePreview(label: 'New reminder dispatch', value: formatDate(reminderAt)),
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'Enter the reason for rescheduling',
                ),
              ),
              if (formError != null) ...[
                const SizedBox(height: 10),
                Text(formError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const SizedBox(height: 10),
              const Text(
                'The app will submit these new dates to the existing Laravel scheduling endpoint. If that endpoint does not save them, the app will show an error instead of claiming success.',
                style: TextStyle(color: mutedText, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: submit,
          icon: const Icon(Icons.event_repeat_rounded),
          label: const Text('Submit new schedule'),
        ),
      ],
    );
  }
}

class _DatePreview extends StatelessWidget {
  const _DatePreview({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E9FF),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: mutedText, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: deepPurple,
              fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
