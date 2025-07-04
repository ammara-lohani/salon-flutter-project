import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Appointment {
  final int id;
  final String name;
  final String email;
  final int phoneNo;
  final String date;
  final String time;
  final String? description;
  final String type; 
  final String? categoryName;

  Appointment({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNo,
    required this.date,
    required this.time,
    this.description,
    required this.type,
    this.categoryName,
  });

  factory Appointment.fromJson(Map<String, dynamic> json, String appointmentType) {
    if (appointmentType == 'Deal') {
      return Appointment(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phoneNo: json['phoneno'] ?? 0,
        date: json['date'] ?? '',
        time: json['time'] ?? '',
        type: 'deal',
      );
    } else {
      // Category booking
      return Appointment(
        id: json['id'] ?? 0,
        name: json['bookname'] ?? '',
        email: json['bookemail'] ?? '',
        phoneNo: json['bookphoneno'] ?? 0,
        date: json['date'] ?? '',
        time: json['time'] ?? '',
        description: json['bookdes'],
        type: 'category',
        categoryName: json['categoryname'], // You might need to join this from categories table
      );
    }
  }
}

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<Appointment> appointments = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedFilter = 'all'; // 'all', 'regular', 'category'

  // Supabase configuration
  static const String supabaseUrl = 'https://krasyurpxjwqolqqwsxz.supabase.co';
  static const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtyYXN5dXJweGp3cW9scXF3c3h6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAxNzk4MTEsImV4cCI6MjA2NTc1NTgxMX0.PUd0iJnl9wxgOkslZPxBwAvohVcN2wGefOPaEk-Fklw';

  @override
  void initState() {
    super.initState();
    _fetchAllAppointments();
  }

  Future<void> _fetchAllAppointments() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      List<Appointment> allAppointments = [];

      // Fetch regular appointments
      await _fetchRegularAppointments(allAppointments);
      
      // Fetch category appointments
      await _fetchCategoryAppointments(allAppointments);

      // Sort appointments by date and time
      allAppointments.sort((a, b) {
        int dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        return a.time.compareTo(b.time);
      });

      setState(() {
        appointments = allAppointments;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching appointments: $e');
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchRegularAppointments(List<Appointment> allAppointments) async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/booking?select=*'),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
        },
      );

      print('Regular appointments response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var json in data) {
          allAppointments.add(Appointment.fromJson(json, 'Deal'));
        }
      }
    } catch (e) {
      print('Error fetching deal appointments: $e');
    }
  }

  Future<void> _fetchCategoryAppointments(List<Appointment> allAppointments) async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/bookingcategorie?select=*'),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
        },
      );

      print('Category appointments response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var json in data) {
          allAppointments.add(Appointment.fromJson(json, 'category'));
        }
      }
    } catch (e) {
      print('Error fetching category appointments: $e');
    }
  }

  List<Appointment> get filteredAppointments {
    switch (selectedFilter) {
      case 'deal':
        return appointments.where((apt) => apt.type == 'deal').toList();
      case 'category':
        return appointments.where((apt) => apt.type == 'category').toList();
      default:
        return appointments;
    }
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '';
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        String minute = parts[1];
        
        String period = hour >= 12 ? 'PM' : 'AM';
        if (hour > 12) {
          hour -= 12;
        } else if (hour == 0) {
          hour = 12;
        }
        
        return '$hour:$minute $period';
      }
    } catch (e) {
      print('Time formatting error: $e');
    }
    return time;
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final parts = date.split('-');
      if (parts.length >= 3) {
        final year = parts[0];
        final month = int.parse(parts[1]);
        final day = parts[2];
        
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        
        if (month >= 1 && month <= 12) {
          return '$day ${months[month - 1]} $year';
        }
      }
    } catch (e) {
      print('Date formatting error: $e');
    }
    return date;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'All Appointments',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _fetchAllAppointments,
          ),

        ], 
        
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildFilterTab('All', 'all'),
                _buildFilterTab('deal', 'deal'),
                _buildFilterTab('Category', 'category'),
          
              ],
            ),
          ),
          
          // Appointments List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.pink,
                    ),
                  )
                : errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red.shade300,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Error Loading Appointments',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                errorMessage!,
                                style: const TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchAllAppointments,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredAppointments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No appointments found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Appointments will appear here once booked',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchAllAppointments,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredAppointments.length,
                              itemBuilder: (context, index) {
                                final appointment = filteredAppointments[index];
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header with ID and Type
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${appointment.type == 'category' ? 'Category' : 'deal'} #${appointment.id}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.pink,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: appointment.type == 'category' 
                                                    ? Colors.purple.shade100 
                                                    : Colors.green.shade100,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                appointment.type == 'category' ? 'Category Service' : 'Deal Booking',
                                                style: TextStyle(
                                                  color: appointment.type == 'category' 
                                                      ? Colors.purple.shade700 
                                                      : Colors.green.shade700,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Date and Time
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Icon(Icons.calendar_today, 
                                                       color: Colors.pink.shade300, size: 20),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _formatDate(appointment.date),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Icon(Icons.access_time, 
                                                     color: Colors.pink.shade300, size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _formatTime(appointment.time),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Customer Details
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Customer Details',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              _buildDetailRow(Icons.person, appointment.name),
                                              const SizedBox(height: 8),
                                              _buildDetailRow(Icons.email, appointment.email),
                                              const SizedBox(height: 8),
                                              _buildDetailRow(Icons.phone, appointment.phoneNo.toString()),
                                              
                                              // Show description for category appointments
                                              if (appointment.type == 'category' && 
                                                  appointment.description != null && 
                                                  appointment.description!.isNotEmpty &&
                                                  appointment.description != 'No additional description provided') ...[
                                                const SizedBox(height: 8),
                                                _buildDetailRow(Icons.description, appointment.description!),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, String value) {
    bool isSelected = selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.pink.shade300 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}