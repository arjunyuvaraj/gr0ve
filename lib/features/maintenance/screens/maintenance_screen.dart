import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  late Timer _timer;
  int _dotCount = 0;

  final List<String> _funnyMessages = [
    "CRITICAL: Reality buffer overflow.",
    "ERROR: Coffee machine disconnected.",
    "STATUS: Refactoring the universe...",
    "WARNING: User sanity levels low.",
    "INFO: Searching for missing semicolons...",
    "ALERT: The trees are whispering secrets.",
    "SYSTEM: Re-aligning planetary gears.",
    "FATAL: Logic.dll has stopped making sense.",
    "TRACE: Following the white rabbit...",
    "SUCCESS: Successfully failed to load.",
  ];

  @override
  void initState() {
    super.initState();
    _addLog("SYSTEM_BOOT_SEQUENCE_START");
    _addLog("INITIALIZING_MAINTENANCE_MODE");
    _addLog("LOCKDOWN_PROTOCOL_ACTIVE");
    
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
          if (timer.tick % 3 == 0) {
            _addLog(_funnyMessages[timer.tick % _funnyMessages.length]);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _addLog(String msg) {
    setState(() {
      _logs.add("[${DateTime.now().toString().split(' ').last.substring(0, 8)}] $msg");
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dots = "." * _dotCount;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "LOCKDOWN",
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "GR0VE_MAINTENANCE_OS v2.1.0",
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.greenAccent.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Big Title
              Text(
                "UNDER_MAINTENANCE",
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              Text(
                "PLEASE_STAND_BY$dots",
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.greenAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Terminal Output
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _logs[index],
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.greenAccent.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      "ACCESS_DENIED",
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.red.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "The grove is currently resting. We'll be back shortly.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
