package com.newstory.newstorybackend.domain.widget.dto;

import com.newstory.newstorybackend.domain.convert.entity.ConversionCache;
import lombok.Getter;

@Getter
public class TodayCardResponse {

  private final Long articleId;
  private final String title;
  private final String convertedText;
  private final String readingTimeLabel;

  public TodayCardResponse(ConversionCache cache) {
    this.articleId = cache.getArticle().getId();
    this.title = cache.getArticle().getTitle();
    this.convertedText = cache.getConvertedText();
    this.readingTimeLabel =
        com.newstory.newstorybackend.global.common.ReadingTimeCalculator.calculate(
            cache.getConvertedText());
  }
}
