import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Translator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TranslatorPage(),
    );
  }
}

class TranslatorPage extends StatefulWidget {
  const TranslatorPage({super.key});

  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  bool _isRecording = false;
  bool _isProcessing = false;
  String _status = "Tap mic to start speaking";
  String? _recordedFilePath;

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<String> _getAudioPath() async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> _startRecording() async {
    try {
      // Check permissions
      if (!await _recorder.hasPermission()) {
        setState(() {
          _status = "Microphone permission denied";
        });
        return;
      }

      // Get a proper file path
      final path = await _getAudioPath();
      
      // Start recording
      await _recorder.start(
        const RecordConfig(),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _status = "Recording... Tap to stop";
      });
    } catch (e) {
      setState(() {
        _status = "Error starting recording: ${e.toString()}";
      });
      print('Recording error: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      
      if (path != null) {
        _recordedFilePath = path;
        setState(() {
          _isRecording = false;
          _isProcessing = true;
          _status = "Processing audio...";
        });

        // TODO: Send audio to Whisper API for transcription
        await _processAudio(path);
      } else {
        setState(() {
          _isRecording = false;
          _status = "Recording failed";
        });
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _status = "Error stopping recording: ${e.toString()}";
      });
      print('Stop recording error: $e');
    }
  }

  Future<void> _processAudio(String audioPath) async {
    try {
      // Simulate API processing delay
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Implement actual API calls here
      // 1. Send to Whisper API for speech-to-text
      // 2. Send transcribed text to translation service
      // 3. Send translated text to ElevenLabs for TTS
      // 4. Play the returned audio

      setState(() {
        _isProcessing = false;
        _status = "Translation complete! (Demo mode)";
      });

      // For demo purposes, show success message
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _status = "Tap mic to start speaking";
      });

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _status = "Error processing audio: ${e.toString()}";
      });
      print('Processing error: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath != null && File(_recordedFilePath!).existsSync()) {
      try {
        await _player.setFilePath(_recordedFilePath!);
        _player.play();
        
        setState(() {
          _status = "Playing recorded audio...";
        });

        // Listen for playback completion
        _player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            setState(() {
              _status = "Tap mic to start speaking";
            });
          }
        });
      } catch (e) {
        setState(() {
          _status = "Error playing audio: ${e.toString()}";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isTablet = screenWidth > 600;
    
    // Responsive sizing
    final buttonSize = isTablet ? 150.0 : screenWidth * 0.3;
    final iconSize = isTablet ? 60.0 : buttonSize * 0.4;
    final horizontalPadding = screenWidth * 0.05;
    final statusFontSize = isTablet ? 22.0 : screenWidth * 0.045;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Voice Translator',
          style: TextStyle(fontSize: isTablet ? 24 : 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top section with status
                      Column(
                        children: [
                          SizedBox(height: screenHeight * 0.05),
                          Container(
                            constraints: BoxConstraints(
                              minHeight: screenHeight * 0.1,
                              maxWidth: screenWidth * 0.9,
                            ),
                            child: Center(
                              child: Text(
                                _status,
                                style: TextStyle(
                                  fontSize: statusFontSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Middle section with recording button
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Recording button
                          GestureDetector(
                            onTap: _isProcessing ? null : (_isRecording ? _stopRecording : _startRecording),
                            child: Container(
                              width: buttonSize,
                              height: buttonSize,
                              decoration: BoxDecoration(
                                color: _isProcessing 
                                    ? Colors.grey[400]
                                    : (_isRecording ? Colors.red : Colors.blue),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isRecording ? Colors.red : Colors.blue).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: _isProcessing
                                  ? CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: isTablet ? 4 : 3,
                                    )
                                  : Icon(
                                      _isRecording ? Icons.stop : Icons.mic,
                                      color: Colors.white,
                                      size: iconSize,
                                    ),
                            ),
                          ),
                          
                          SizedBox(height: screenHeight * 0.05),
                          
                          // Play button (for testing recorded audio)
                          if (_recordedFilePath != null && !_isRecording && !_isProcessing)
                            Container(
                              margin: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                              child: ElevatedButton.icon(
                                onPressed: _playRecording,
                                icon: Icon(Icons.play_arrow, size: isTablet ? 24 : 20),
                                label: Text(
                                  'Play Recording',
                                  style: TextStyle(fontSize: isTablet ? 18 : 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.06,
                                    vertical: screenHeight * 0.015,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      // Bottom section with instructions
                      Container(
                        margin: EdgeInsets.only(bottom: screenHeight * 0.03),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'How to use:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isTablet ? 20 : 16,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                Text(
                                  '1. Tap the microphone to start recording\n'
                                  '2. Speak clearly in your source language\n'
                                  '3. Tap stop when finished\n'
                                  '4. Wait for translation and playback',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: isTablet ? 16 : 14,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}