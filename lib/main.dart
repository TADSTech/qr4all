import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr4all/qr_data_handler.dart';
import 'package:qr4all/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'generate_qr_code.dart';
import 'scan_qr_code.dart';
import 'theme/theme_settings_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider()..loadThemePrefs(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    QRDataHandler.navigatorKey = GlobalKey<NavigatorState>();

    return MaterialApp(
      title: 'QR4All',
      debugShowCheckedModeBanner: false,
      theme: FlexColorScheme.light(
        scheme: FlexScheme
            .values[themeProvider.themeIndex % FlexScheme.values.length],
        useMaterial3: true,
      ).toTheme,
      darkTheme: FlexColorScheme.dark(
        scheme: FlexScheme
            .values[themeProvider.themeIndex % FlexScheme.values.length],
        useMaterial3: true,
      ).toTheme,
      themeMode: themeProvider.themeMode,
      home: const HomePage(),
      navigatorKey: QRDataHandler.navigatorKey,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> recentScans = [];

  @override
  void initState() {
    super.initState();
    _loadRecentScans();
  }

  Future<void> _loadRecentScans() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentScans = prefs.getStringList('recentScans') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR4All',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            )),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 10,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const ThemeSettingsDialog(),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isLargeScreen ? _buildDesktopLayout() : _buildMobileLayout(),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          _buildFeatureCards(context),
          _buildRecentScans(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 40),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildFeatureCards(context),
                ),
                const SizedBox(width: 40),
                Expanded(
                  flex: 3,
                  child: _buildRecentScans(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner, size: 80, color: Colors.deepPurple),
          const SizedBox(height: 20),
          Text(
            'Your QR Code Solution',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Scan and generate QR codes seamlessly across all your devices',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Padding(
      padding: EdgeInsets.all(isLargeScreen ? 0 : 20),
      child: Column(
        children: [
          _buildFeatureCard(
            context,
            icon: Icons.camera_alt,
            title: 'Scan QR Code',
            subtitle: 'Scan any QR code instantly with your camera',
            color: Colors.purple,
            onTap: () => _navigateTo(context, const ScanQrCode()),
          ),
          const SizedBox(height: 20),
          _buildFeatureCard(
            context,
            icon: Icons.create,
            title: 'Generate QR Code',
            subtitle: 'Create custom QR codes for URLs, text, and more',
            color: Colors.deepPurple,
            onTap: () => _navigateTo(context, const GenerateQrCode()),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScans() {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Padding(
      padding: EdgeInsets.all(isLargeScreen ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recent Scans',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const Spacer(),
              if (recentScans.isNotEmpty)
                TextButton(
                  onPressed: () => _clearRecentScans(),
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: isLargeScreen ? 300 : 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: recentScans.isEmpty
                ? Center(
                    child: Text(
                      'No recent scans',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  )
                : ListView.builder(
                    itemCount: recentScans.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          recentScans[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () {
                                _copyToClipboard(recentScans[index]);
                              },
                              tooltip: 'Copy to clipboard',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () {
                                _removeScan(index);
                              },
                              tooltip: 'Delete scan',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(isLargeScreen ? 25 : 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: color.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            )),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            )),
                  ],
                ),
              ),
              if (isLargeScreen)
                const Icon(Icons.chevron_right, size: 30, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
    _loadRecentScans();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _removeScan(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentScans.removeAt(index);
    });
    await prefs.setStringList('recentScans', recentScans);
  }

  Future<void> _clearRecentScans() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentScans.clear();
    });
    await prefs.setStringList('recentScans', recentScans);
  }
}
