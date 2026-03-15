import 'package:flutter/material.dart';
import '../services/blog_service.dart';
import '../models/blog.dart';
import '../components/blog_card.dart';
import 'blog_detail_page.dart';
import 'create_blog_page.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final BlogService _blogService = BlogService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<Blog> _displayBlogs = [];

  final List<String> _categories = [
    'All',
    'Period Pain',
    'Hygiene',
    'PMS',
    'Nutrition',
    'First Period Guide',
    'PCOS',
    'Hormones',
    'Myths & Facts'
  ];

  @override
  void initState() {
    super.initState();
    _refreshBlogs();
  }

  void _refreshBlogs() {
    setState(() {
      if (_searchController.text.isNotEmpty) {
        _displayBlogs = _blogService.searchBlogs(_searchController.text);
      } else {
        _displayBlogs = _blogService.getBlogsByCategory(_selectedCategory);
      }
    });
  }

  void _onSearch(String query) {
    _refreshBlogs();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
      _refreshBlogs();
    });
  }

  Future<void> _navigateAndAddBlog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateBlogPage()),
    );

    if (result == true) {
      _refreshBlogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article published successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trendingBlogs = _blogService.getTrendingBlogs();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Knowledge Hub',
          style: TextStyle(color: Color(0xFF4A4A4A), fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndAddBlog,
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: const InputDecoration(
                  hintText: 'Search "period cramps"...',
                  prefixIcon: Icon(Icons.search, color: Colors.pink),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),

            // Trending Section
            const Text(
              'Trending Now',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: trendingBlogs.length,
                itemBuilder: (context, index) {
                  final blog = trendingBlogs[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BlogDetailPage(blog: blog)),
                    ).then((_) => _refreshBlogs()),
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 15),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFD7881), Color(0xFFFEA3A9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            blog.category,
                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            blog.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.remove_red_eye_outlined, color: Colors.white70, size: 12),
                              const SizedBox(width: 4),
                              Text('${blog.views}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Categories
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => _onCategorySelected(cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.pink : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.pink,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Blog Feed
            const Text(
              'Latest Articles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A)),
            ),
            const SizedBox(height: 12),
            _displayBlogs.isEmpty
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text('No articles found matching your search.'),
                  ))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _displayBlogs.length,
                    itemBuilder: (context, index) {
                      return BlogCard(blog: _displayBlogs[index]);
                    },
                  ),
            const SizedBox(height: 100), // Space for navbar
          ],
        ),
      ),
    );
  }
}
