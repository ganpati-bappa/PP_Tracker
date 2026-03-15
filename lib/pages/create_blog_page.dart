import 'package:flutter/material.dart';
import '../models/blog.dart';
import '../services/blog_service.dart';

class CreateBlogPage extends StatefulWidget {
  const CreateBlogPage({super.key});

  @override
  State<CreateBlogPage> createState() => _CreateBlogPageState();
}

class _CreateBlogPageState extends State<CreateBlogPage> {
  final _formKey = GlobalKey<FormState>();
  final BlogService _blogService = BlogService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  String _selectedCategory = 'Period Pain';

  final List<String> _categories = [
    'Period Pain',
    'Hygiene',
    'PMS',
    'Nutrition',
    'First Period Guide',
    'PCOS',
    'Hormones',
    'Myths & Facts'
  ];

  void _submitBlog() {
    if (_formKey.currentState!.validate()) {
      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final newBlog = Blog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        content: _contentController.text,
        preview: _contentController.text.length > 100 
            ? '${_contentController.text.substring(0, 97)}...' 
            : _contentController.text,
        authorId: 'user_local', // Mock local user ID
        authorName: _authorController.text,
        category: _selectedCategory,
        tags: tags,
        createdAt: DateTime.now(),
        lastEditedAt: DateTime.now(),
        status: BlogStatus.published,
      );

      _blogService.addBlog(newBlog);
      Navigator.pop(context, true); // Return true to indicate success
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.fromARGB(255, 255, 228, 244), Color.fromARGB(255, 254, 249, 223)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Create New Article', style: TextStyle(color: Color(0xFF4A4A4A))),
          iconTheme: const IconThemeData(color: Colors.pink),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Share your knowledge with the community.', 
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 24),
                
                _buildTextField(
                  controller: _titleController,
                  label: 'Blog Title',
                  hint: 'Enter a catchy title...',
                  validator: (v) => v!.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _authorController,
                  label: 'Author Name',
                  hint: 'Your name or pseudonym',
                  validator: (v) => v!.isEmpty ? 'Author name is required' : null,
                ),
                const SizedBox(height: 16),
                
                const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      items: _categories.map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _tagsController,
                  label: 'Tags',
                  hint: 'cramps, health, tips (comma separated)',
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _contentController,
                  label: 'Content',
                  hint: 'Write your full article here...',
                  maxLines: 15,
                  validator: (v) => v!.length < 50 ? 'Content is too short' : null,
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _submitBlog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                    ),
                    child: const Text('Publish Article', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
