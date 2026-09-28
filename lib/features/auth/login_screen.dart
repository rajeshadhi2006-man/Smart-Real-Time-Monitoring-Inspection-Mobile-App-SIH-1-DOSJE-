import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../core/config/app_config.dart';
import '../../core/widgets/govt_emblem_header.dart';
import '../../core/widgets/sovereign_colorful_background.dart';
import '../../providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _hostController = TextEditingController(text: ApiConfig.customHost);

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(authProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text,
          );

      if (!success && mounted) {
        final authState = ref.read(authProvider);
        if (authState.hasError) {
          final errStr = authState.error.toString().replaceAll("Exception: ", "");
          setState(() {
            _errorMessage = "Gateway Error: $errStr\nCheck Gateway IP (${ApiConfig.baseUrl}).";
          });
        } else {
          setState(() {
            _errorMessage = "Authentication failed. Invalid username or password.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showConfigDialog() {
    _hostController.text = ApiConfig.customHost;
    bool isTesting = false;
    String? testResult;
    bool? testSuccess;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> runPingTest(String rawHost) async {
            setDialogState(() {
              isTesting = true;
              testResult = "Pinging server health endpoint...";
              testSuccess = null;
            });
            String target = rawHost.trim();
            if (!target.startsWith('http://') && !target.startsWith('https://')) {
              target = 'http://$target';
            }
            if (!target.contains(':', target.indexOf('://') + 3)) {
              target = '$target:8000';
            }
            if (target.endsWith('/')) target = target.substring(0, target.length - 1);
            final testUrl = target.endsWith('/api') ? '$target/health' : '$target/api/health';

            try {
              final dio = Dio(BaseOptions(
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
              ));
              final stopwatch = Stopwatch()..start();
              final resp = await dio.get(testUrl);
              stopwatch.stop();
              if (resp.statusCode == 200) {
                setDialogState(() {
                  isTesting = false;
                  testSuccess = true;
                  testResult = "Server Online (HTTP 200) • ${stopwatch.elapsedMilliseconds}ms";
                });
              } else {
                setDialogState(() {
                  isTesting = false;
                  testSuccess = false;
                  testResult = "HTTP ${resp.statusCode}: Server responded with code ${resp.statusCode}";
                });
              }
            } catch (e) {
              setDialogState(() {
                isTesting = false;
                testSuccess = false;
                testResult = "Connection failed. Check IP & ensure phone is on same Wi-Fi.";
              });
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF0A192F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFF1E3A5F), width: 1.2),
            ),
            title: const Row(
              children: [
                Icon(Icons.router_rounded, color: AppColors.tricolorSaffron, size: 22),
                SizedBox(width: 10),
                Text("Backend Gateway Config", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Configure backend IP for phone LAN Wi-Fi or USB tethering:",
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
                  ),
                  const SizedBox(height: 12),

                  // Quick presets
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        backgroundColor: const Color(0xFF132F4C),
                        side: const BorderSide(color: Color(0xFF818CF8)),
                        label: const Text("🌐 Cloud 5G", style: TextStyle(fontSize: 11, color: Color(0xFFA5B4FC), fontWeight: FontWeight.bold)),
                        avatar: const Icon(Icons.cloud_done_rounded, size: 14, color: Color(0xFFA5B4FC)),
                        onPressed: () {
                          _hostController.text = "https://reg-lucky-hire-retrieve.trycloudflare.com";
                          runPingTest(_hostController.text);
                        },
                      ),
                      ActionChip(
                        backgroundColor: const Color(0xFF132F4C),
                        side: const BorderSide(color: Color(0xFF0284C7)),
                        label: const Text("📱 Wi-Fi LAN", style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                        avatar: const Icon(Icons.wifi_rounded, size: 14, color: Color(0xFF38BDF8)),
                        onPressed: () {
                          _hostController.text = "http://${AppConfig.localLanIp}:8000";
                          runPingTest(_hostController.text);
                        },
                      ),
                      ActionChip(
                        backgroundColor: const Color(0xFF132F4C),
                        side: const BorderSide(color: Color(0xFF64748B)),
                        label: const Text("📶 Hotspot", style: TextStyle(fontSize: 11, color: Color(0xFFE2E8F0))),
                        avatar: const Icon(Icons.wifi_tethering_rounded, size: 14, color: Color(0xFFCBD5E1)),
                        onPressed: () {
                          _hostController.text = "http://${AppConfig.hotspotLanIp}:8000";
                          runPingTest(_hostController.text);
                        },
                      ),
                      ActionChip(
                        backgroundColor: const Color(0xFF132F4C),
                        side: const BorderSide(color: Color(0xFF64748B)),
                        label: const Text("🔌 USB Cable", style: TextStyle(fontSize: 11, color: Color(0xFFE2E8F0))),
                        avatar: const Icon(Icons.usb_rounded, size: 14, color: Color(0xFFCBD5E1)),
                        onPressed: () {
                          _hostController.text = "http://127.0.0.1:8000";
                          runPingTest(_hostController.text);
                        },
                      ),
                      ActionChip(
                        backgroundColor: const Color(0xFF1E3A5F),
                        side: const BorderSide(color: Color(0xFF10B981)),
                        label: const Text("⚡ Auto-Detect", style: TextStyle(fontSize: 11, color: Color(0xFF34D399), fontWeight: FontWeight.bold)),
                        avatar: const Icon(Icons.autorenew_rounded, size: 14, color: Color(0xFF34D399)),
                        onPressed: () async {
                          setDialogState(() {
                            isTesting = true;
                            testResult = "Scanning candidate endpoints...";
                          });
                          final working = await AppConfig.autoDiscoverWorkingEndpoint();
                          if (working != null) {
                            _hostController.text = working.endsWith('/api') ? working.substring(0, working.length - 4) : working;
                            runPingTest(_hostController.text);
                          } else {
                            setDialogState(() {
                              isTesting = false;
                              testSuccess = false;
                              testResult = "No active server found. Check if backend is running.";
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _hostController,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      labelText: "Server URL / Host:Port",
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      hintText: "http://10.77.108.231:8000",
                      hintStyle: const TextStyle(color: Color(0xFF475569)),
                      filled: true,
                      fillColor: const Color(0xFF071324),
                      prefixIcon: const Icon(Icons.dns_rounded, color: Color(0xFF38BDF8), size: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.network_check_rounded, color: AppColors.tricolorSaffron),
                        tooltip: "Ping Server",
                        onPressed: isTesting ? null : () => runPingTest(_hostController.text),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.tricolorSaffron),
                      ),
                    ),
                  ),

                  if (testResult != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: testSuccess == true
                            ? const Color(0x2210B981)
                            : (testSuccess == false ? const Color(0x22EF4444) : const Color(0x2238BDF8)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: testSuccess == true
                              ? const Color(0xFF10B981)
                              : (testSuccess == false ? const Color(0xFFEF4444) : const Color(0xFF38BDF8)),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isTesting)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                            )
                          else
                            Icon(
                              testSuccess == true
                                  ? Icons.check_circle_rounded
                                  : (testSuccess == false ? Icons.error_rounded : Icons.info_outline_rounded),
                              size: 16,
                              color: testSuccess == true
                                  ? const Color(0xFF10B981)
                                  : (testSuccess == false ? const Color(0xFFEF4444) : const Color(0xFF38BDF8)),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              testResult!,
                              style: TextStyle(
                                fontSize: 11,
                                color: testSuccess == true
                                    ? const Color(0xFF6EE7B7)
                                    : (testSuccess == false ? const Color(0xFFFCA5A5) : const Color(0xFFBAE6FD)),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Color(0xFF94A3B8))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  side: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final newHost = _hostController.text.trim();
                  if (newHost.isNotEmpty) {
                    await ApiConfig.setCustomHost(newHost);
                    setState(() {});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("✅ Gateway saved: ${ApiConfig.baseUrl}"),
                          backgroundColor: const Color(0xFF0F172A),
                        ),
                      );
                    }
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text("Save & Connect", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SovereignColorfulBackground(
        child: Column(
          children: [
            // Official Sovereign Government Header Banner
            const SafeArea(
              bottom: false,
              child: GovtEmblemHeader(
                compact: false,
                subtitle: "National Autonomous Field Inspection Portal",
              ),
            ),

            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Security Restricted Clearance Badge
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A192F),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.statusGreen,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.statusGreen.withValues(alpha: 0.6),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "RESTRICTED GOVT OF INDIA PORTAL • LEVEL-3",
                                  style: TextStyle(
                                    color: Color(0xFFBAE6FD),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Interactive Gateway Chip
                      Center(
                        child: InkWell(
                          onTap: _showConfigDialog,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF071324),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                width: 0.9,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.wifi_tethering_rounded, size: 13, color: AppColors.tricolorSaffron),
                                const SizedBox(width: 6),
                                Text(
                                  "Gateway: ${ApiConfig.baseUrl.replaceAll('http://', '').replaceAll('/api', '')}",
                                  style: const TextStyle(
                                    color: Color(0xFFBAE6FD),
                                    fontSize: 10.5,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A5F),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    "Change",
                                    style: TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Main Authentication Card (Sleek Sovereign Glassmorphism)
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xF50A192F),
                              Color(0xF50E2447),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 28,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Card Title & Subtitle
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.solarSaffronGradient,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF9933).withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.fingerprint_rounded, color: Colors.white, size: 24),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Officer Single Sign-On",
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      Text(
                                        "Authorized Field Personnel Authentication",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),


                            // Error Banner
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.statusError.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.statusError.withValues(alpha: 0.6)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: AppColors.statusError, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12.5, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Username / Officer ID
                            TextFormField(
                              controller: _usernameController,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: "Officer ID / Official Email",
                                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                hintText: "e.g. officer@field.gov.in",
                                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                                fillColor: const Color(0xFF071324),
                                filled: true,
                                prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF38BDF8)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 1.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.tricolorSaffron, width: 1.8),
                                ),
                              ),
                              validator: (val) => val == null || val.isEmpty ? "Please enter Officer ID" : null,
                            ),
                            const SizedBox(height: 14),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: "Security Password",
                                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                hintText: "••••••••",
                                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                                fillColor: const Color(0xFF071324),
                                filled: true,
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF38BDF8)),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8)),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 1.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.tricolorSaffron, width: 1.8),
                                ),
                              ),
                              validator: (val) => val == null || val.isEmpty ? "Please enter password" : null,
                            ),
                            const SizedBox(height: 8),

                            // Links Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: TextButton.icon(
                                    onPressed: _showConfigDialog,
                                    icon: const Icon(Icons.settings_ethernet_rounded, size: 15, color: Color(0xFF38BDF8)),
                                    label: const Text("Gateway IP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF38BDF8))),
                                  ),
                                ),
                                Flexible(
                                  child: TextButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Contact MoSJE National Command Admin for credential recovery.")),
                                      );
                                    },
                                    child: const Text("Forgot Credentials?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Secure Login Button with Vibrant Saffron / Solar Gradient
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFF9933), // National Saffron
                                    Color(0xFFEA580C), // Solar Amber
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9933).withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  minimumSize: const Size.fromHeight(52),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.shield_rounded, size: 18, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text(
                                            "SECURE GOVT LOGIN",
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.8,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sovereign Digital India & National Emblem Footer
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 2.5,
                                    decoration: const BoxDecoration(color: AppColors.tricolorSaffron),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "DIGITAL INDIA • MoSJE NIRIKSHAN 2.0",
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFBAE6FD),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 24,
                                    height: 2.5,
                                    decoration: const BoxDecoration(color: AppColors.tricolorGreen),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Smart India Hackathon 2026 • Problem Statement ID: 26095\nDepartment of Social Justice and Empowerment, Government of India",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
