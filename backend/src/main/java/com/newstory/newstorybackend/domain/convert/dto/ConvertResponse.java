package com.newstory.newstorybackend.domain.convert.dto;

import com.newstory.newstorybackend.domain.convert.entity.ConvertedResult;
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
  }
}
