$lines = Get-Content 'd:\asiaze news\newssapp\lib\main.dart'

$handler = @'

  Future<void> _handleNotificationTap(dynamic notif) async {
    final contentType = notif['contentType'];
    final contentId = notif['contentId'];

    if (contentId == null || contentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content not available')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('language') ?? 'EN';
      final language = langCode == 'HIN' ? 'hindi' : (langCode == 'BEN' ? 'bengali' : 'english');

      if (contentType == 'News') {
        final news = await ApiService.getNews(language: language);
        final article = news.firstWhere(
          (n) => n['_id'].toString() == contentId.toString(),
          orElse: () => null,
        );

        if (article != null && mounted) {
          final lang = Provider.of<LanguageProvider>(context, listen: false);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(
                imageUrl: article['image'] ?? 'asset:refranceimages/Group (16).png',
                title: lang.getNewsContent(article, 'title'),
                subtitle: lang.getNewsContent(article, 'summary'),
                meta: 'ASIAZE • ${formatPublishedDate(article['publishedAt'])}',
                explanation: lang.getNewsContent(article, 'explanation'),
              ),
            ),
          );
        }
      } else if (contentType == 'Reel') {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VideosScreen()),
          );
        }
      } else if (contentType == 'Story') {
        final stories = await ApiService.getStories();
        final storyIndex = stories.indexWhere(
          (s) => s['_id'].toString() == contentId.toString(),
        );

        if (storyIndex != -1 && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StoryViewerScreen(
                stories: stories,
                initialIndex: storyIndex,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load content: $e')),
        );
      }
    }
  }
'@

$newContent = @()
for($i=0; $i -lt $lines.Length; $i++) {
    $newContent += $lines[$i]
    if($i -eq 4137) {
        $newContent += $handler
    }
}

$newContent | Set-Content 'd:\asiaze news\newssapp\lib\main.dart'
