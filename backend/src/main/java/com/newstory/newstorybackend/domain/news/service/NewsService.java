package com.newstory.newstorybackend.domain.news.service;

import com.newstory.newstorybackend.domain.news.dto.NewsItem;
import com.newstory.newstorybackend.domain.news.entity.ArticleView;
import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import com.newstory.newstorybackend.domain.news.repository.ArticleViewRepository;
import com.newstory.newstorybackend.domain.news.repository.NewsArticleRepository;
import com.newstory.newstorybackend.global.exception.NotFoundException;
import java.time.LocalDateTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class NewsService {

  private final NewsArticleRepository newsArticleRepository;
  private final ArticleViewRepository articleViewRepository;

  @Transactional(readOnly = true)
  public List<NewsItem> getNews(String category, int page, int size) {
    PageRequest pageable = PageRequest.of(page, size, Sort.by("publishedAt").descending());
    if (category == null || category.isBlank()) {
      return newsArticleRepository.findAll(pageable).map(NewsItem::new).toList();
    }
    return newsArticleRepository.findByCategory(category, pageable).map(NewsItem::new).toList();
  }

  @Transactional(readOnly = true)
  public List<String> getCategories() {
    return newsArticleRepository.findDistinctCategories();
  }

  @Transactional(readOnly = true)
  public List<NewsItem> getPopular(int limit) {
    return newsArticleRepository
        .findAll(PageRequest.of(0, limit, Sort.by("createdAt").descending()))
        .map(NewsItem::new)
        .toList();
  }

  @Transactional
  public void recordView(Long articleId) {
    NewsArticle article =
        newsArticleRepository
            .findById(articleId)
            .orElseThrow(() -> new NotFoundException("기사를 찾을 수 없습니다."));

    ArticleView view = ArticleView.builder().article(article).viewedAt(LocalDateTime.now()).build();

    articleViewRepository.save(view);
  }
}
