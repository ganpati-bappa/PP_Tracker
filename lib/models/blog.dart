import 'package:collection/collection.dart';

enum BlogStatus { draft, published, archived }

class BlogComment {
  final String id;
  final String authorName;
  final String message;
  final DateTime timestamp;

  BlogComment({
    required this.id,
    required this.authorName,
    required this.message,
    required this.timestamp,
  });
}

class Blog {
  final String id;
  final String title;
  final String content;
  final String preview;
  final String authorId;
  final String authorName;
  final String category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime lastEditedAt;
  final String? imageUrl;
  final int views;
  final Set<String> likedBy; // Store user IDs
  final List<BlogComment> comments;
  final BlogStatus status;

  Blog({
    required this.id,
    required this.title,
    required this.content,
    required this.preview,
    required this.authorId,
    required this.authorName,
    required this.category,
    required this.tags,
    required this.createdAt,
    required this.lastEditedAt,
    this.imageUrl,
    this.views = 0,
    this.likedBy = const {},
    this.comments = const [],
    this.status = BlogStatus.published,
  });

  int get likeCount => likedBy.length;
  int get commentCount => comments.length;
  int get estimatedReadTime => (content.split(' ').length / 200).ceil();

  double get engagementScore {
    // Basic engagement score: likes * 2 + comments * 3 + views * 0.5
    // Adjusted by recency (decay over time could be added here)
    return (likeCount * 2.0) + (commentCount * 3.0) + (views * 0.5);
  }

  Blog copyWith({
    String? title,
    String? content,
    String? preview,
    String? category,
    List<String>? tags,
    DateTime? lastEditedAt,
    String? imageUrl,
    int? views,
    Set<String>? likedBy,
    List<BlogComment>? comments,
    BlogStatus? status,
  }) {
    return Blog(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      preview: preview ?? this.preview,
      authorId: authorId,
      authorName: authorName,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      views: views ?? this.views,
      likedBy: likedBy ?? this.likedBy,
      comments: comments ?? this.comments,
      status: status ?? this.status,
    );
  }
}
