package com.newstory.newstorybackend.domain.widget.service;

import com.newstory.newstorybackend.domain.convert.entity.ConversionCache;
import com.newstory.newstorybackend.domain.convert.repository.ConversionCacheRepository;
import com.newstory.newstorybackend.domain.widget.dto.TodayCardResponse;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class WidgetService {

  private final ConversionCacheRepository conversionCacheRepository;

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
