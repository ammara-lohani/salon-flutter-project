import 'package:file_name/bookingscreen.dart';
import 'package:file_name/categorybookingscreen.dart'; // Added this import
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Simple Deal model
class Deal {
  final int id;
  final String name;
  final String description;
  final String? image;

  Deal({
    required this.id,
    required this.name,
    required this.description,
    this.image,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'No Name',
      description: json['description'] ?? 'No Description',
      image: json['image'],
    );
  }
}

// Category model
class Category {
  final int id;
  final String catname;
  final String catdes;
  final String? catimage;
   
  Category({
    required this.id,
    required this.catname,
    required this.catdes,
    this.catimage,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      catname: json['catname'] ?? 'No Name',
      catdes: json['catdes'] ?? 'No Description',
      catimage: json['catimage'],
    );
  }
}

class DealsScreen extends StatefulWidget {
  const DealsScreen({Key? key}) : super(key: key);

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  List<Deal> deals = [];
  List<Category> categories = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  bool isDarkMode = false;

  // Supabase configuration
  static const String supabaseUrl = 'https://krasyurpxjwqolqqwsxz.supabase.co';
  static const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtyYXN5dXJweGp3cW9scXF3c3h6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAxNzk4MTEsImV4cCI6MjA2NTc1NTgxMX0.PUd0iJnl9wxgOkslZPxBwAvohVcN2wGefOPaEk-Fklw';
// aon public key 
// project key 
  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await Future.wait([
      fetchDeals(),
      fetchCategories(),
    ]);
  }

  Future<void> fetchDeals() async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/dealsdiscount?select=*&order=id.desc'),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          deals = data.map((item) => Deal.fromJson(item)).toList();
        });
      } else {
        throw Exception('Failed to load deals');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Error loading deals ';
      });
      print('Error fetching deals: ');
    }
  }

  Future<void> fetchCategories() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/categorie?select=*&order=id.asc'),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          categories = data.map((item) => Category.fromJson(item)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Error loading categories: $e';
      });
      print('Error fetching categories: $e');
    }
    
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  // Handle booking action
  void _handleBookMe(Deal deal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(deal: deal),
      ),
    );
  }

  // Handle category tap - Updated method
  void _handleCategoryTap(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryBookingScreen(category: category),
      ),
    );
  }

  Color get primaryColor => isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : const Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assests/images/logo.png',
            height: 32,
            width: 32,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.business,
                color: textColor,
                size: 24,
              );
            },
          ),
        ),
        title: null,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: toggleTheme,
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: textColor,
                size: 24,
              ),
              tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchData,
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.pink.shade300,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading deals and categories...',
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading data',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorMessage,
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: fetchData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade300,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Deals Section
                        if (deals.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Special Deals',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 220,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: deals.length,
                              itemBuilder: (context, index) {
                                final deal = deals[index];
                                return Container(
                                  width: 200,
                                  margin: const EdgeInsets.only(right: 16.0),
                                  child: _buildDealCard(deal),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                        
                        
                        // Categories Section
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Categories',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        if (categories.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.category_outlined,
                                    size: 64,
                                    color: textColor.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No categories available',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Categories will appear here once added',
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3, // Reduced from 4 to 3 for larger boxes
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.9, // Increased from 0.8 to give more height
                              ),
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                return _buildCategoryCard(category);
                              },
                            ),
                          ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildDealCard(Deal deal) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.pink.shade300,
                Colors.orange.shade300,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Background Image
              if (deal.image != null && deal.image!.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    deal.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container();
                    },
                  ),
                ),
              
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              
              // Content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deal.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Expanded(
                        child: Text(
                          deal.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 15,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Simple Book Me Button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => _handleBookMe(deal),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Book Me',
                                    style: TextStyle(
                                      color: Colors.pink.shade400,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.pink.shade400,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return GestureDetector(
      onTap: () => _handleCategoryTap(category),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Category Image - Just the image without container
          Container(
            width: 60,
            height: 60,
            child: category.catimage != null && category.catimage!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      category.catimage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.category,
                            color: Colors.grey.shade400,
                            size: 30,
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.category,
                      color: Colors.grey.shade400,
                      size: 30,
                    ),
                  ),
          ),
          
          const SizedBox(height: 8),
          
          // Category Name
          Text(
            category.catname,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}