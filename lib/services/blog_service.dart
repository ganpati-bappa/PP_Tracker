import '../models/blog.dart';

class BlogService {
  static final BlogService _instance = BlogService._internal();
  factory BlogService() => _instance;
  BlogService._internal();

  final List<Blog> _blogs = _generateInitialBlogs();
  final Set<String> _bookmarkedBlogIds = {};

  static List<Blog> _generateInitialBlogs() {
    final List<Blog> list = [];
    final categories = [
      'Period Pain', 'Hygiene', 'PMS', 'Nutrition', 
      'First Period Guide', 'PCOS', 'Hormones', 'Myths & Facts'
    ];
    
    final authors = [
      'Dr. Sarah Wilson', 'Nurse Jane Doe', 'Chef Mike', 
      'School Counselor Amy', 'Dr. Emily Chen', 'Fitness Coach Alex'
    ];

    for (int i = 1; i <= 100; i++) {
      final category = categories[i % categories.length];
      final author = authors[i % authors.length];
      
      // Generate long-form content based on the index to ensure 100 unique articles
      String title = '';
      String content = '';
      List<String> tags = [];

      if (i == 1) {
        title = 'Comprehensive Guide to Understanding Period Cramps';
        content = _generateCrampsArticle();
        tags = ['cramps', 'pain management', 'health'];
      } else if (i == 2) {
        title = 'Mastering Menstrual Hygiene: A Complete Manual';
        content = _generateHygieneArticle();
        tags = ['hygiene', 'safety', 'tips'];
      } else if (i == 3) {
        title = 'Optimal Nutrition for Every Phase of Your Cycle';
        content = _generateNutritionArticle();
        tags = ['food', 'diet', 'nutrition'];
      } else if (i == 4) {
        title = 'Navigating PMS: Understanding and Managing Mood Swings';
        content = _generatePMSArticle();
        tags = ['mood', 'pms', 'mental health'];
      } else if (i == 5) {
        title = 'The Ultimate First Period Guide for Teens and Parents';
        content = _generateFirstPeriodArticle();
        tags = ['beginner', 'education', 'first period'];
      } else {
        // Generate the other 95 articles with unique topics
        final topicIndex = i % 20;
        final topics = [
          'Hydration and its Impact on Menstrual Flow',
          'Yoga Poses for Instant Cramp Relief',
          'The Link Between Sleep and Hormonal Balance',
          'Breaking Down PCOS: Symptoms and Management',
          'Iron Deficiency and Fatigue During Your Period',
          'Menstrual Cups vs. Tampons: Which is Right for You?',
          'Tracking Your Cycle: Why Data Matters for Health',
          'Managing Stress to Regulate Your Menstrual Cycle',
          'Skin Health and the Menstrual Cycle',
          'Magnesium: The Secret Mineral for Period Relief',
          'Exercise Intensity Throughout Your Cycle',
          'Understanding Irregular Periods in Your 20s',
          'Debunking Common Menstrual Myths',
          'The Role of Estrogen in Female Health',
          'Managing Heavy Flow: Tips and Solutions',
          'Post-Period Care: Rebuilding Your Energy',
          'Environmental Impact of Menstrual Products',
          'Hormonal Birth Control and the Body',
          'Mindfulness Practices for Menstrual Wellness',
          'Acupuncture and Traditional Chinese Medicine for Periods'
        ];
        title = topics[topicIndex] + ' (Volume $i)';
        content = _generateGenericLongFormContent(topics[topicIndex], i);
        tags = [category.toLowerCase().replaceAll(' ', '_'), 'wellness', 'health'];
      }

      list.add(Blog(
        id: i.toString(),
        title: title,
        preview: content.substring(0, 150) + '...',
        content: content,
        authorId: 'auth_$i',
        authorName: author,
        category: category,
        tags: tags,
        createdAt: DateTime.now().subtract(Duration(days: i)),
        lastEditedAt: DateTime.now().subtract(Duration(days: i)),
        views: (1000 / i).round() + 50,
        likedBy: i % 3 == 0 ? {'user_1'} : {},
      ));
    }
    return list;
  }

  static String _generateCrampsArticle() {
    return '''# Understanding Period Cramps: Causes and Remedies

## Introduction
Period cramps, medically known as dysmenorrhea, are a common experience for millions of women worldwide. While often dismissed as just a part of being a woman, they can significantly impact daily life, productivity, and overall well-being. This guide delves deep into the science of cramps and provides actionable solutions.

## Why Do Cramps Happen?
The primary culprit behind period cramps is a group of hormone-like substances called prostaglandins. During menstruation, your uterus contracts to help expel its lining. Higher levels of prostaglandins are associated with more severe uterine contractions, leading to more intense pain.

## Types of Dysmenorrhea
1. **Primary Dysmenorrhea:** This is common menstrual cramping that isn't caused by another condition. It usually begins a day or two before your period or when bleeding starts.
2. **Secondary Dysmenorrhea:** This pain is caused by a disorder in the reproductive organs, such as endometriosis, uterine fibroids, or pelvic inflammatory disease.

## Effective Management Strategies
- **Heat Therapy:** Applying a heating pad or hot water bottle to your lower abdomen increases blood flow and relaxes uterine muscles.
- **Dietary Adjustments:** Reducing salt and caffeine intake can help minimize bloating and tension.
- **Physical Activity:** While it's the last thing you might want to do, gentle exercise like walking or swimming releases endorphins, the body's natural painkillers.
- **Supplements:** Magnesium, Vitamin B1, and Omega-3 fatty acids have shown promise in reducing cramp severity.

## When to See a Doctor
If your pain is so severe that it prevents you from daily activities, or if over-the-counter medications provide no relief, it's important to consult a healthcare professional to rule out secondary causes.
''';
  }

  static String _generateHygieneArticle() {
    return '''# Mastering Menstrual Hygiene: A Complete Manual

## Introduction
Maintaining proper menstrual hygiene is not just about comfort; it's a vital aspect of reproductive health. Poor hygiene can lead to infections, irritation, and long-term health complications. This manual covers everything you need to know about staying safe and clean during your cycle.

## Choosing the Right Products
There is no one-size-fits-all product. Your choice depends on your flow, lifestyle, and personal preference:
- **Sanitary Pads:** Great for beginners and light to heavy flow. Look for breathable materials.
- **Tampons:** Ideal for swimming and active sports. Must be changed frequently to avoid Toxic Shock Syndrome (TSS).
- **Menstrual Cups:** Eco-friendly and cost-effective. They collect rather than absorb blood.
- **Period Underwear:** A comfortable, reusable option for light days or as backup.

## Best Practices for Daily Care
1. **Regular Changes:** Change pads every 4-6 hours and tampons every 4 hours. Menstrual cups can be worn up to 12 hours depending on the brand.
2. **Proper Washing:** Clean the external genital area with plain water. Avoid scented soaps or douches which can disrupt the natural pH balance.
3. **Wiping Technique:** Always wipe from front to back to prevent the spread of bacteria.
4. **Hand Hygiene:** Wash your hands thoroughly before and after changing any menstrual product.

## Managing Odor and Discomfort
Natural menstrual odor is normal. However, a strong, foul smell might indicate an infection. Keeping the area dry and changing products regularly are the best ways to manage odor. If you experience persistent itching or unusual discharge, seek medical advice.
''';
  }

  static String _generateNutritionArticle() {
    return '''# Optimal Nutrition for Every Phase of Your Cycle

## Introduction
Your body's nutritional needs fluctuate throughout your menstrual cycle. By aligning your diet with your hormones, you can reduce PMS symptoms, boost energy levels, and improve your overall mood.

## Phase 1: The Menstrual Phase (Days 1-5)
Focus on iron-rich foods to replenish what is lost through bleeding. 
- **What to eat:** Spinach, lentils, red meat (in moderation), and fortified cereals.
- **Tip:** Pair iron with Vitamin C (like oranges or bell peppers) to enhance absorption.

## Phase 2: The Follicular Phase (Days 6-13)
As estrogen levels rise, focus on light, energy-boosting foods.
- **What to eat:** Probiotic-rich foods like yogurt or kimchi to support gut health and estrogen metabolism. Complex carbs like oats and quinoa provide steady energy.

## Phase 3: The Ovulatory Phase (Days 14-16)
You may feel most energetic now. Support your liver as it processes peak hormones.
- **What to eat:** Cruciferous vegetables like broccoli and cauliflower. Berries provide antioxidants for cellular health.

## Phase 4: The Luteal Phase (Days 17-28)
This is when PMS often strikes. Progesterone is high, which can slow digestion and cause cravings.
- **What to eat:** Magnesium-rich foods like dark chocolate and pumpkin seeds to help with mood and cramps. Fiber-rich foods help prevent bloating.

## Summary
Listening to your body's cravings and responding with nutrient-dense choices can transform your experience of your cycle.
''';
  }

  static String _generatePMSArticle() {
    return '''# Navigating PMS: Understanding and Managing Mood Swings

## Introduction
Premenstrual Syndrome (PMS) affects millions, with mood swings being one of the most challenging symptoms. Fluctuating hormones can make you feel like you're on an emotional rollercoaster.

## The Science of Mood Swings
Mood changes are primarily linked to the drop in estrogen and progesterone before your period starts. This drop affects serotonin, a neurotransmitter that plays a crucial role in mood regulation.

## Common Emotional Symptoms
- Irritability and anger
- Anxiety and tension
- Crying spells
- Sleep disturbances
- Social withdrawal

## Management Techniques
1. **Exercise:** Physical activity increases endorphins and can help stabilize mood.
2. **Sleep Hygiene:** Aim for 7-9 hours of quality sleep to prevent irritability caused by fatigue.
3. **Stress Reduction:** Meditation, yoga, or simple breathing exercises can lower cortisol levels.
4. **Limit Alcohol and Caffeine:** Both can exacerbate anxiety and mood fluctuations.

## When it's More Than Just PMS
If mood swings are debilitating, you may have Premenstrual Dysphoric Disorder (PMDD). PMDD is a more severe form of PMS that requires professional medical intervention.
''';
  }

  static String _generateFirstPeriodArticle() {
    return '''# The Ultimate First Period Guide for Teens and Parents

## Introduction
Getting your first period, also called menarche, is a major milestone. It signals that your body is growing up and becoming capable of reproduction. While it can be scary, being prepared makes all the difference.

## When Will it Happen?
Most girls get their first period between ages 12 and 15, but it can happen as early as 8 or as late as 16. Usually, it starts about two years after breast buds begin to develop.

## What to Expect
- **The Color:** It might not be bright red. It can look brown or pinkish at first.
- **The Amount:** The first few periods are often very light.
- **Regularity:** It takes about 1-2 years for your cycle to become regular. Don't worry if you skip a month.

## Building Your Period Kit
A small bag for your school locker or backpack should include:
- Two or three pads
- A clean pair of underwear
- A small pack of wet wipes
- A ziplock bag for disposal or soiled laundry

## Tips for Parents
- Start the conversation early.
- Be positive and celebratory.
- Focus on the biological facts to remove mystery and fear.
- Ensure your teen knows how to use the products.
''';
  }

  static String _generateGenericLongFormContent(String topic, int index) {
    return '''# $topic: A Deep Dive into Wellness

## Introduction
This article explores $topic in the context of menstrual health. Understanding how various lifestyle factors and biological processes intersect is key to achieving long-term wellness. In volume $index of our series, we look at the latest research and practical applications.

## Why This Matters
Often, small changes in our daily routine can have a profound impact on how we experience our menstrual cycles. Research shows that $topic plays a significant role in hormonal balance and symptom management.

## Key Insights
1. **The Biological Connection:** Every system in our body is connected. $topic influences the endocrine system which regulates our periods.
2. **The Environmental Factor:** Our surroundings and habits affect our internal chemistry.
3. **Consistency is Key:** Implementing changes over several cycles is necessary to see results.

## Practical Implementation
- **Step 1:** Observe your current habits for one full cycle.
- **Step 2:** Introduce one small change related to $topic.
- **Step 3:** Document how you feel and adjust as needed.

## Conclusion
Knowledge is power. By educating ourselves on topics like $topic, we take control of our reproductive health. Stay tuned for more deep dives into menstrual wellness.
''';
  }

  List<Blog> getAllBlogs() {
    return List.unmodifiable(_blogs);
  }

  List<Blog> getTrendingBlogs() {
    final sorted = List<Blog>.from(_blogs);
    sorted.sort((a, b) => b.engagementScore.compareTo(a.engagementScore));
    return sorted.take(5).toList();
  }

  List<Blog> getBlogsByCategory(String category) {
    if (category == 'All') return getAllBlogs();
    return _blogs.where((blog) => blog.category == category).toList();
  }

  List<Blog> searchBlogs(String query) {
    final lowerQuery = query.toLowerCase();
    return _blogs.where((blog) {
      final matchesTitle = blog.title.toLowerCase().contains(lowerQuery);
      final matchesContent = blog.content.toLowerCase().contains(lowerQuery);
      final matchesTags = blog.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      return matchesTitle || matchesContent || matchesTags;
    }).toList();
  }

  List<Blog> getRelatedBlogs(Blog currentBlog) {
    return _blogs.where((blog) {
      if (blog.id == currentBlog.id) return false;
      final sameCategory = blog.category == currentBlog.category;
      final sharedTags = blog.tags.any((tag) => currentBlog.tags.contains(tag));
      return sameCategory || sharedTags;
    }).take(3).toList();
  }

  void addBlog(Blog blog) {
    _blogs.insert(0, blog); // Add to the beginning of the list
  }

  void toggleLike(String blogId, String userId) {
    final index = _blogs.indexWhere((b) => b.id == blogId);
    if (index != -1) {
      final blog = _blogs[index];
      final newLikedBy = Set<String>.from(blog.likedBy);
      if (newLikedBy.contains(userId)) {
        newLikedBy.remove(userId);
      } else {
        newLikedBy.add(userId);
      }
      _blogs[index] = blog.copyWith(likedBy: newLikedBy);
    }
  }

  void addComment(String blogId, BlogComment comment) {
    final index = _blogs.indexWhere((b) => b.id == blogId);
    if (index != -1) {
      final blog = _blogs[index];
      _blogs[index] = blog.copyWith(comments: [...blog.comments, comment]);
    }
  }

  void incrementViews(String blogId) {
    final index = _blogs.indexWhere((b) => b.id == blogId);
    if (index != -1) {
      final blog = _blogs[index];
      _blogs[index] = blog.copyWith(views: blog.views + 1);
    }
  }

  void toggleBookmark(String blogId) {
    if (_bookmarkedBlogIds.contains(blogId)) {
      _bookmarkedBlogIds.remove(blogId);
    } else {
      _bookmarkedBlogIds.add(blogId);
    }
  }

  bool isBookmarked(String blogId) {
    return _bookmarkedBlogIds.contains(blogId);
  }

  List<Blog> getBookmarkedBlogs() {
    return _blogs.where((blog) => _bookmarkedBlogIds.contains(blog.id)).toList();
  }
}
