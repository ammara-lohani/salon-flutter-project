import 'package:file_name/deals_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CategoryBookingScreen extends StatefulWidget {
  final Category category;

  const CategoryBookingScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<CategoryBookingScreen> createState() => _CategoryBookingScreenState();
}

class _CategoryBookingScreenState extends State<CategoryBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime? selectedDate;
  String? selectedTimeSlot;
  bool isLoading = false;
  bool isSubmitting = false;
  
  // Available time slots
  final List<String> weekdaySlots = [
    '11:00 AM - 1:00 PM',
    '1:00 PM - 3:00 PM',
    '3:00 PM - 5:00 PM',
    '5:00 PM - 7:00 PM',
    '7:00 PM - 8:00 PM', // Only 1 hour slot for the last one
  ];
  
  final List<String> weekendSlots = [
    '11:00 AM - 1:00 PM',
    '1:00 PM - 3:00 PM',
    '3:00 PM - 5:00 PM',
    '5:00 PM - 7:00 PM',
    '7:00 PM - 9:00 PM',
    '9:00 PM - 11:00 PM',
    '11:00 PM - 12:00 AM', // Only 1 hour slot for the last one
  ];
  
  Map<String, int> slotBookings = {};
  
  // Supabase configuration
  static const String supabaseUrl = 'https://krasyurpxjwqolqqwsxz.supabase.co';
  static const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtyYXN5dXJweGp3cW9scXF3c3h6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAxNzk4MTEsImV4cCI6MjA2NTc1NTgxMX0.PUd0iJnl9wxgOkslZPxBwAvohVcN2wGefOPaEk-Fklw';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkSlotAvailability() async {
    if (selectedDate == null) return;
    
    setState(() {
      isLoading = true;
      slotBookings.clear();
    });
    
    try {
      final formattedDate = "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
      
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/bookingcategorie?select=time&date=eq.$formattedDate'),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
        },
      );
      
      print('Slot check response: ${response.statusCode}');
      print('Slot check body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> bookings = json.decode(response.body);
        
        // Count bookings for each time slot
        for (var booking in bookings) {
          String timeSlot = booking['time'];
          slotBookings[timeSlot] = (slotBookings[timeSlot] ?? 0) + 1;
        }
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error checking slot availability: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  List<String> _getAvailableSlots() {
    if (selectedDate == null) return [];
    return _isWeekend(selectedDate!) ? weekendSlots : weekdaySlots;
  }

  bool _isSlotFull(String timeSlot) {
    return (slotBookings[timeSlot] ?? 0) >= 5;
  }

  String _convertTimeSlotToDbFormat(String timeSlot) {
    // Convert "11:00 AM - 1:00 PM" to "11:00:00" (start time)
    String startTime = timeSlot.split(' - ')[0];
    
    if (startTime.contains('AM')) {
      String time = startTime.replaceAll(' AM', '');
      if (time.startsWith('12:')) {
        time = time.replaceAll('12:', '00:');
      }
      return '$time:00';
    } else {
      String time = startTime.replaceAll(' PM', '');
      if (!time.startsWith('12:')) {
        int hour = int.parse(time.split(':')[0]) + 12;
        String minutes = time.split(':')[1];
        time = '$hour:$minutes';
      }
      return '$time:00';
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate() || selectedDate == null || selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields and select date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      isSubmitting = true;
    });
    
    try {
      final formattedDate = "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
      final formattedTime = _convertTimeSlotToDbFormat(selectedTimeSlot!);
      
      final bookingData = {
        'bookname': _nameController.text.trim(),
        'bookemail': _emailController.text.trim(), 
        'bookphoneno': int.parse(_phoneController.text.trim()),
        'bookdes': _descriptionController.text.trim().isEmpty 
            ? 'No additional description provided' 
            : _descriptionController.text.trim(),
        'date': formattedDate,
        'time': formattedTime,
      };
      
      print('Category booking data: $bookingData');
      
      final response = await http.post(
        Uri.parse('$supabaseUrl/rest/v1/bookingcategorie'),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: json.encode(bookingData),
      );
      
      print('Submit response: ${response.statusCode}');
      print('Submit body: ${response.body}');
      
      if (response.statusCode == 201) {
        // Success
        _showSuccessDialog();
      } else {
        // Show detailed error
        String errorMessage = 'Failed to submit booking (${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final errorData = json.decode(response.body);
            errorMessage += ': ${errorData['message'] ?? errorData.toString()}';
          } catch (e) {
            errorMessage += ': ${response.body}';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Full error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Booking Confirmed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your appointment has been successfully booked for:'),
              const SizedBox(height: 16),
              Text('Category: ${widget.category.catname}', 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Date: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
              Text('Time: $selectedTimeSlot'),
              Text('Name: ${_nameController.text}'),
              const SizedBox(height: 16),
              const Text('Thank you for booking, See you there!', 
                   style: TextStyle(color: Color.fromARGB(255, 192, 31, 160))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to deals screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedTimeSlot = null; // Reset time slot when date changes
      });
      _checkSlotAvailability();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Book Category Service',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Category Information Card (without image)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.category.catname,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.category.catdes,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            // Booking Form
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.pink.shade300, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address *',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.pink.shade300, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number *',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.pink.shade300, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.trim().length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Additional Requirements (Optional)',
                        hintText: 'Please describe any specific requirements or preferences...',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Icon(Icons.description),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.pink.shade300, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Date Selection
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Date *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Text(
                                    selectedDate == null
                                        ? 'Choose a date'
                                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: selectedDate == null ? Colors.grey : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Time Slot Selection
                    if (selectedDate != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Time Slot * (${_isWeekend(selectedDate!) ? 'Weekend' : 'Weekday'} Schedule)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (isLoading)
                              const Center(child: CircularProgressIndicator())
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _getAvailableSlots().map((slot) {
                                  bool isSelected = selectedTimeSlot == slot;
                                  bool isFull = _isSlotFull(slot);
                                  
                                  return GestureDetector(
                                    onTap: isFull ? null : () {
                                      setState(() {
                                        selectedTimeSlot = slot;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isFull 
                                            ? Colors.red.shade100 
                                            : isSelected 
                                                ? Colors.pink.shade300 
                                                : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isFull 
                                              ? Colors.red.shade300 
                                              : isSelected 
                                                  ? Colors.pink.shade300 
                                                  : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            slot,
                                            style: TextStyle(
                                              color: isFull 
                                                  ? Colors.red.shade700 
                                                  : isSelected 
                                                      ? Colors.white 
                                                      : Colors.black87,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                          ),
                                          if (isFull) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              '(Full)',
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ] else if (slotBookings[slot] != null) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              '(${slotBookings[slot]}/5)',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Submit Booking Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submitBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade300,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                        child: isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Book My Appointment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Info Text
                   
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}