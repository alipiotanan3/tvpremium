import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/business_logic/provider/channel_provider.dart';
import 'package:tiwee/core/consts.dart';
import 'package:shared_preferences.dart';
import 'package:tiwee/presentation/screens/m3u_validator/m3u_validator_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _autoRetry = true;
  int _maxRetries = 3;
  int _connectionTimeout = 15;
  int _readTimeout = 20;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController.text = prefs.getString('m3u_url') ?? AppConstants.defaultM3uUrl;
      _autoRetry = prefs.getBool('auto_retry') ?? true;
      _maxRetries = prefs.getInt('max_retries') ?? 3;
      _connectionTimeout = prefs.getInt('connection_timeout') ?? 15;
      _readTimeout = prefs.getInt('read_timeout') ?? 20;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('m3u_url', _urlController.text);
        await prefs.setBool('auto_retry', _autoRetry);
        await prefs.setInt('max_retries', _maxRetries);
        await prefs.setInt('connection_timeout', _connectionTimeout);
        await prefs.setInt('read_timeout', _readTimeout);

        AppConstants.updateM3uUrl(_urlController.text);
        AppConstants.updateNetworkSettings(
          autoRetry: _autoRetry,
          maxRetries: _maxRetries,
          connectionTimeout: _connectionTimeout,
          readTimeout: _readTimeout,
        );

        await ref.read(channelProvider.notifier).refreshChannels();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving settings: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  String? _validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a URL';
    }
    try {
      final uri = Uri.parse(value);
      if (!uri.isAbsolute) {
        return 'Please enter a valid URL';
      }
      if (!['http', 'https'].contains(uri.scheme.toLowerCase())) {
        return 'URL must start with http:// or https://';
      }
    } catch (e) {
      return 'Invalid URL format';
    }
    return null;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () {
              setState(() {
                _urlController.text = AppConstants.defaultM3uUrl;
                _autoRetry = true;
                _maxRetries = 3;
                _connectionTimeout = 15;
                _readTimeout = 20;
              });
            },
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'M3U Playlist Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'M3U URL',
                hintText: 'Enter your M3U playlist URL',
                border: OutlineInputBorder(),
              ),
              validator: _validateUrl,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            const Text(
              'Network Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-retry on failure'),
              subtitle: const Text('Automatically retry failed requests'),
              value: _autoRetry,
              onChanged: (value) => setState(() => _autoRetry = value),
            ),
            if (_autoRetry) ...[
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Maximum retries'),
                subtitle: Slider(
                  value: _maxRetries.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _maxRetries.toString(),
                  onChanged: (value) => setState(() => _maxRetries = value.round()),
                ),
                trailing: Text(_maxRetries.toString()),
              ),
            ],
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Connection timeout (seconds)'),
              subtitle: Slider(
                value: _connectionTimeout.toDouble(),
                min: 5,
                max: 30,
                divisions: 25,
                label: _connectionTimeout.toString(),
                onChanged: (value) => setState(() => _connectionTimeout = value.round()),
              ),
              trailing: Text(_connectionTimeout.toString()),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Read timeout (seconds)'),
              subtitle: Slider(
                value: _readTimeout.toDouble(),
                min: 5,
                max: 30,
                divisions: 25,
                label: _readTimeout.toString(),
                onChanged: (value) => setState(() => _readTimeout = value.round()),
              ),
              trailing: Text(_readTimeout.toString()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Save Settings'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const M3UValidatorScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.playlist_play),
              label: const Text('M3U Playlist Validator'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 