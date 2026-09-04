package com.newstory.newstorybackend.domain.convert.dto;

import com.newstory.newstorybackend.domain.convert.entity.ConvertedResult;
import com.newstory.newstorybackend.global.common.ReadingTimeCalculator;
import java.util.List;
import lombok.Getter;

@Getter
public class ConvertResponse {

  private final Long id;
  private final String style;
  private final String convertedText;
  private final boolean verificationPassed;
  private final String verificationMethod;
  private final int retryCount;
  private final boolean cachedResult;
  private final List<GlossaryItem> glossary;
  private final String readingTimeLabel;

  public ConvertResponse(
      ConvertedResult result, boolean cachedResult, List<GlossaryItem> glossary) {
    this.id = result.getId();
    this.style = result.getStyle();
    this.convertedText = result.getConvertedText();
    this.verificationPassed = Boolean.TRUE.equals(result.getVerificationPassed());
    this.verificationMethod = result.getVerificationMethod();
    this.retryCount = result.getRetryCount();
    this.cachedResult = cachedResult;
    this.glossary = glossary != null ? glossary : List.of();
    this.readingTimeLabel =
        "card".equals(result.getStyle())
            ? ReadingTimeCalculator.calculate(result.getConvertedText())
            : null;
  }
}
