package com.newstory.newstorybackend.domain.convert.dto;

import com.newstory.newstorybackend.domain.convert.entity.ConvertedResult;
import lombok.Getter;

@Getter
public class ConvertResponse {

  private final Long id;
  private final String style;
  private final String convertedText;
  private final boolean verificationPassed;
  private final String verificationMethod;
  private final int retryCount;

  public ConvertResponse(ConvertedResult result) {
    this.id = result.getId();
    this.style = result.getStyle();
    this.convertedText = result.getConvertedText();
    this.verificationPassed = Boolean.TRUE.equals(result.getVerificationPassed());
    this.verificationMethod = result.getVerificationMethod();
    this.retryCount = result.getRetryCount();
  }
}
