package com.newstory.newstorybackend.domain.news.service;

import com.newstory.newstorybackend.domain.news.dto.NewsItem;
import com.newstory.newstorybackend.domain.news.dto.NewsPageResponse;
import com.newstory.newstorybackend.domain.news.entity.ArticleView;
import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import com.newstory.newstorybackend.domain.news.repository.ArticleViewRepository;
import com.newstory.newstorybackend.domain.news.repository.NewsArticleRepository;
import com.newstory.newstorybackend.global.exception.BadRequestException;
import com.newstory.newstorybackend.global.exception.NotFoundException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class NewsService {

  private final NewsArticleRepository newsArticleRepository;
  private final ArticleViewRepository articleViewRepository;

  static final int MAX_KEYWORD_LENGTH = 50;

  @Transactional(readOnly = true)
  public NewsPageResponse getNews(String category, String keyword, int page, int size) {
    // 직접 변환으로 저장된 기사는 발행시각이 없다 — DESC 기본(NULLS FIRST)이면 홈 맨 위를 차지해서 맨 뒤로
    PageRequest pageable =
        PageRequest.of(page, size, Sort.by(Sort.Order.desc("publishedAt").nullsLast()));
    String cat = (category == null || category.isBlank()) ? null : category;
    String kw = keyword == null ? "" : keyword.strip();
    if (kw.length() > MAX_KEYWORD_LENGTH) {
      throw new BadRequestException("검색어는 " + MAX_KEYWORD_LENGTH + "자 이하로 입력해주세요.");
    }

    Page<NewsArticle> result;
    if (!kw.isEmpty()) {
      result = newsArticleRepository.searchByTitle(likePattern(kw), cat, pageable);
    } else if (cat != null) {
      result = newsArticleRepository.findByCategory(cat, pageable);
    } else {
      result = newsArticleRepository.findAll(pageable);
    }
    return new NewsPageResponse(result.map(NewsItem::new));
  }

  /** 사용자가 입력한 %, _ 가 와일드카드로 해석되지 않도록 이스케이프하고 양쪽에 % 를 붙인다. */
  static String likePattern(String keyword) {
    String escaped =
        keyword
            .toLowerCase(Locale.ROOT)
            .replace("\\", "\\\\")
            .replace("%", "\\%")
            .replace("_", "\\_");
    return "%" + escaped + "%";
  }

  @Transactional(readOnly = true)
  public NewsItem getNewsById(Long id) {
    return newsArticleRepository
        .findById(id)
        .map(NewsItem::new)
        .orElseThrow(() -> new NotFoundException("기사를 찾을 수 없습니다."));
  }

  @Transactional(readOnly = true)
  public List<String> getCategories() {
    return newsArticleRepository.findDistinctCategories();
  }

  @Transactional(readOnly = true)
  public List<NewsItem> getPopular(int limit) {
    Pageable pageable = PageRequest.of(0, limit);
    return newsArticleRepository.findTopByViewCount(pageable).stream().map(NewsItem::new).toList();
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
