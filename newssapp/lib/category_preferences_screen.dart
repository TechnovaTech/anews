import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/language_provider.dart';

class CategoryPreferencesScreen extends StatefulWidget {
  const CategoryPreferencesScreen({super.key});

  @override
  State<CategoryPreferencesScreen> createState() => _CategoryPreferencesScreenState();
}

class _CategoryPreferencesScreenState extends State<CategoryPreferencesScreen> {
  List<Map<String, dynamic>> _categories = [];
  Set<String> _selected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final interests = prefs.getStringList('interests') ?? [];
      final categories = await ApiService.getCategories();
      
      setState(() {
        _categories = List<Map<String, dynamic>>.from(categories);
        _selected = Set<String>.from(interests);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePreferences() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one interest')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    
    final selectedIds = _categories
        .where((c) => _selected.contains(c['name'].toString()))
        .map((c) => c['_id'].toString())
        .toList();
    
    await prefs.setStringList('interests', _selected.toList());
    await prefs.setStringList('categoryIds', selectedIds);
    
    if (userId != null && userId.isNotEmpty) {
      try {
        final language = prefs.getString('language') ?? 'EN';
        await ApiService.updateUserPreferences(userId, language, selectedIds);
      } catch (e) {
        print('Failed to update backend: $e');
      }
    }
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences updated!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final red = const Color(0xFFDC143C);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(Provider.of<LanguageProvider>(context).translate('category_preferences')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_selected.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Provider.of<LanguageProvider>(context).translate('selected_interests'),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selected.map((name) {
                            return Chip(
                              label: Text(name),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() => _selected.remove(name));
                              },
                              backgroundColor: red,
                              labelStyle: const TextStyle(color: Colors.white),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        Provider.of<LanguageProvider>(context).translate('all_categories'),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      ..._categories.map((cat) {
                        final name = cat['name'].toString();
                        final isSelected = _selected.contains(name);
                        return CheckboxListTile(
                          title: Text(name),
                          value: isSelected,
                          activeColor: red,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selected.add(name);
                              } else {
                                _selected.remove(name);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: _savePreferences,
                      child: Text(Provider.of<LanguageProvider>(context).translate('save')),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
