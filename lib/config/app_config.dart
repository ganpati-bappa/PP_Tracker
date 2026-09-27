/// Which backend the blog module talks to.
enum BlogBackend {
  /// In-memory [MockBlogRepository] — no network, great for local UI work,
  /// widget tests and demos.
  mock,

  /// Cloud Firestore [FirestoreBlogRepository] — the production data layer.
  firestore,
}

/// Compile-time app configuration.
///
/// Flipping [blogBackend] is the *only* change needed to switch the entire blog
/// module between the mock and Firestore — everything above the
/// `BlogRepository` interface is backend-agnostic.
class AppConfig {
  AppConfig._();

  /// The active blog backend. Firestore is the production default; switch to
  /// [BlogBackend.mock] for offline development or tests.
  static const BlogBackend blogBackend = BlogBackend.firestore;

  static bool get usesFirestore => blogBackend == BlogBackend.firestore;
}
