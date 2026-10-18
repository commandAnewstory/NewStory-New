package com.newstory.newstorybackend.domain.widget.service;

import com.newstory.newstorybackend.domain.convert.entity.ConversionCache;
import com.newstory.newstorybackend.domain.convert.repository.ConversionCacheRepository;
import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import com.newstory.newstorybackend.domain.news.repository.NewsArticleRepository;
import com.newstory.newstorybackend.domain.user.entity.InterestCategories;
import com.newstory.newstorybackend.domain.widget.dto.PopularNewsResponse;
import com.newstory.newstorybackend.domain.widget.dto.TodayCardResponse;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class WidgetService {

  static final int POPULAR_COUNT = 3;

  private final ConversionCacheRepository conversionCacheRepository;
  private final NewsArticleRepository newsArticleRepository;

  /**
   * 관심 카테고리의 오늘 인기 뉴스. 오늘(서버 시각 00:00 이후) 올라온 기사 중 오늘 조회수순, 모자라면 같은 카테고리 최신 기사로 채워서 위젯이 비지 않게 한다.
   * [categoriesCsv]가 비었거나 허용값이 하나도 없으면 전체.
   */
  @Transactional(readOnly = true)
  public List<PopularNewsResponse> getPopular(String categoriesCsv) {
    List<String> categories = InterestCategories.parse(categoriesCsv);
    boolean all = categories.isEmpty();
    List<String> filter = all ? InterestCategories.ALLOWED : categories;
    LocalDateTime todayStart = LocalDate.now().atStartOfDay();

    Map<Long, NewsArticle> picked = new LinkedHashMap<>();
    newsArticleRepository
        .findPopularSince(todayStart, all, filter, PageRequest.of(0, POPULAR_COUNT))
        .forEach(a -> picked.putIfAbsent(a.getId(), a));
    if (picked.size() < POPULAR_COUNT) {
      newsArticleRepository
          .findLatestIn(all, filter, PageRequest.of(0, POPULAR_COUNT * 2))
          .forEach(
              a -> {
                if (picked.size() < POPULAR_COUNT) picked.putIfAbsent(a.getId(), a);
              });
    }
    return picked.values().stream().map(PopularNewsResponse::new).toList();
  }

  @Transactional(readOnly = true)
  public List<TodayCardResponse> getTodayCards() {
    LocalDateTime todayStart = LocalDate.now().atStartOfDay();
    List<ConversionCache> caches =
        conversionCacheRepository.findTodayCardCaches(todayStart, PageRequest.of(0, 3));

    if (caches.size() < 3) {
      caches = conversionCacheRepository.findTop3ByStyleOrderByCreatedAtDesc("card");
    }

    return caches.stream().map(TodayCardResponse::new).toList();
  }
}
