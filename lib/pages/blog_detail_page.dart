import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/blog.dart';
import '../services/blog_service.dart';
import '../components/blog_card.dart';

class BlogDetailPage extends StatefulWidget {
  final Blog blog;

  const BlogDetailPage({super.key, required this.blog});

  @override
  State<BlogDetailPage> createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  final BlogService _blogService = BlogService();
  late Blog _currentBlog;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentBlog = widget.blog;
    _blogService.incrementViews(_currentBlog.id);
  }

  void _handleLike() {
    setState(() {
      _blogService.toggleLike(_currentBlog.id, 'current_user'); // Mock user ID
      _currentBlog = _blogService.getAllBlogs().firstWhere((b) => b.id == _currentBlog.id);
    });
  }

  void _handleBookmark() {
    setState(() {
      _blogService.toggleBookmark(_currentBlog.id);
    });
  }

  void _handleAddComment() {
    if (_commentController.text.trim().isEmpty) return;

    final newComment = BlogComment(
      id: DateTime.now().toString(),
      authorName: 'You',
      message: _commentController.text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _blogService.addComment(_currentBlog.id, newComment);
      _currentBlog = _blogService.getAllBlogs().firstWhere((b) => b.id == _currentBlog.id);
      _commentController.clear();
    });
    
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final relatedBlogs = _blogService.getRelatedBlogs(_currentBlog);

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
          actions: [
            IconButton(
              icon: Icon(
                _blogService.isBookmarked(_currentBlog.id) ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.pink,
              ),
              onPressed: _handleBookmark,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.pink),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Image
              if (_currentBlog.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(_currentBlog.imageUrl!, fit: BoxFit.cover),
                )
              else
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.image_outlined, size: 80, color: Colors.pink.shade100),
                ),
              const SizedBox(height: 20),

              // Title & Meta
              Text(
                _currentBlog.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.pink.shade100,
                    child: Text(_currentBlog.authorName[0], style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_currentBlog.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        '${DateFormat.yMMMd().format(_currentBlog.createdAt)} • ${_currentBlog.estimatedReadTime} min read',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Content
              Text(
                _currentBlog.content,
                style: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF4A4A4A)),
              ),
              const SizedBox(height: 24),

              // Tags
              Wrap(
                spacing: 8,
                children: _currentBlog.tags.map((tag) => Chip(
                  label: Text('#$tag', style: const TextStyle(fontSize: 12, color: Colors.pink)),
                  backgroundColor: Colors.white.withOpacity(0.8),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                )).toList(),
              ),
              const SizedBox(height: 24),

              // Interaction Row
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _handleLike,
                    icon: Icon(
                      _currentBlog.likedBy.contains('current_user') ? Icons.favorite : Icons.favorite_border,
                      color: Colors.pink,
                    ),
                    label: Text('${_currentBlog.likeCount} Likes', style: const TextStyle(color: Colors.pink)),
                  ),
                  const Spacer(),
                  Text('${_currentBlog.views} Views', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
              const Divider(height: 40),

              // Comments Section
              const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ..._currentBlog.comments.map((comment) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(DateFormat.yMMMd().format(comment.timestamp), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment.message, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              )).toList(),

              // Add Comment
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixIcon: IconButton(icon: const Icon(Icons.send, color: Colors.pink), onPressed: _handleAddComment),
                ),
              ),

              const SizedBox(height: 40),

              // Related Blogs
              if (relatedBlogs.isNotEmpty) ...[
                const Text('Related Articles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...relatedBlogs.map((blog) => BlogCard(blog: blog)).toList(),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
