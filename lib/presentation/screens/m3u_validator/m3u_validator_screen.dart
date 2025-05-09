import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:tiwee/business_logic/model/m3u_channel.dart';
import 'package:tiwee/core/consts.dart';
import 'package:tiwee/presentation/screens/home/player.dart';

class M3UValidatorScreen extends StatefulWidget {
  const M3UValidatorScreen({super.key});

  @override
  State<M3UValidatorScreen> createState() => _M3UValidatorScreenState();
}

class _M3UValidatorScreenState extends State<M3UValidatorScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _loading = false;
  String _status = '';
  List<M3UChannel> _channels = [];
  Map<String, int> _categoryCount = {};
  Map<String, bool> _categoryExpanded = {};
  double _responseTime = 0;
  int _totalChannels = 0;
  bool _isValidating = false;
  Timer? _validationTimer;
  int _validationProgress = 0;
  String _currentValidationStep = '';

  @override
  void initState() {
    super.initState();
    _urlController.text = AppConstants.defaultM3uUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _validationTimer?.cancel();
    super.dispose();
  }

  Future<void> _validateM3U() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showError('Please enter a URL');
      return;
    }

    setState(() {
      _loading = true;
      _status = '';
      _channels = [];
      _categoryCount = {};
      _isValidating = true;
      _validationProgress = 0;
      _currentValidationStep = 'Connecting to server...';
    });

    try {
      final stopwatch = Stopwatch()..start();
      
      // Start progress timer
      _validationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (mounted && _isValidating) {
          setState(() {
            _validationProgress = (_validationProgress + 1) % 100;
          });
        }
      });

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': '*/*',
        },
      ).timeout(const Duration(seconds: 15));

      setState(() => _currentValidationStep = 'Analyzing response...');

      if (response.statusCode == 200) {
        if (!response.body.contains("#EXTM3U")) {
          throw FormatException('Invalid M3U format: Missing #EXTM3U header');
        }

        setState(() => _currentValidationStep = 'Parsing channels...');
        
        final lines = const LineSplitter().convert(response.body);
        List<M3UChannel> channels = [];
        String? currentExtInf;

        for (var line in lines) {
          if (line.startsWith("#EXTINF:")) {
            currentExtInf = line;
          } else if (line.startsWith("http")) {
            if (currentExtInf != null) {
              try {
                final channel = M3UChannel.fromM3ULine(currentExtInf, line);
                channels.add(channel);
              } catch (e) {
                print('Error parsing channel: $e');
              }
            }
            currentExtInf = null;
          }
        }

        // Calculate category statistics
        final categoryCount = <String, int>{};
        for (var channel in channels) {
          categoryCount[channel.category] = (categoryCount[channel.category] ?? 0) + 1;
        }

        stopwatch.stop();
        _responseTime = stopwatch.elapsedMilliseconds / 1000;
        
        setState(() {
          _channels = channels;
          _categoryCount = categoryCount;
          _totalChannels = channels.length;
          _categoryExpanded = Map.fromIterable(
            categoryCount.keys,
            value: (_) => false,
          );
          _status = 'Valid M3U list\n'
                    'Response time: ${_responseTime.toStringAsFixed(2)}s\n'
                    'Total channels: $_totalChannels\n'
                    'Categories: ${categoryCount.length}';
        });
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      _validationTimer?.cancel();
      setState(() {
        _loading = false;
        _isValidating = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _status = 'Error: $message';
      _loading = false;
      _isValidating = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _testChannel(M3UChannel channel) async {
    try {
      final response = await http.head(Uri.parse(channel.url))
          .timeout(const Duration(seconds: 5));
      
      String message = 'Status: ${response.statusCode}';
      if (response.statusCode == 200) {
        message += '\nContent-Type: ${response.headers['content-type']}';
        message += '\nContent-Length: ${response.headers['content-length']}';
      }
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(channel.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Player(
                          url: channel.url,
                          fallbackUrl: channel.fallbackUrl,
                          name: channel.name,
                        ),
                      ),
                    );
                  },
                  child: const Text('Test Playback'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(channel.name),
            content: Text('Error: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M3U Validator'),
        actions: [
          if (_channels.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                AppConstants.updateM3uUrl(_urlController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL saved as default')),
                );
              },
              tooltip: 'Set as default URL',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'M3U URL',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _urlController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _validateM3U,
              child: _loading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        value: _isValidating ? _validationProgress / 100 : null,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Validate'),
            ),
            if (_loading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_currentValidationStep),
              ),
            if (_status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _status
                          .split('\n')
                          .map((line) => Text(
                                line,
                                style: const TextStyle(fontSize: 14),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            if (_channels.isNotEmpty) ...[
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _categoryCount.length,
                  itemBuilder: (context, index) {
                    final category = _categoryCount.keys.elementAt(index);
                    final channelsInCategory = _channels
                        .where((c) => c.category == category)
                        .toList();
                    
                    return Card(
                      child: ExpansionTile(
                        title: Text(category),
                        subtitle: Text('${channelsInCategory.length} channels'),
                        initiallyExpanded: _categoryExpanded[category] ?? false,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _categoryExpanded[category] = expanded;
                          });
                        },
                        children: channelsInCategory.map((channel) {
                          return ListTile(
                            title: Text(channel.name),
                            subtitle: Text(channel.url),
                            trailing: IconButton(
                              icon: const Icon(Icons.play_circle_outline),
                              onPressed: () => _testChannel(channel),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 