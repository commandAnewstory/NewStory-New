package com.newstory.newstorybackend.domain.ai.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class VerificationResult {

  private final boolean passed;
  private final String rawResponse;

  public static VerificationResult passed() {
    return new VerificationResult(true, null);
  }

  public static VerificationResult failed(String rawResponse) {
    return new VerificationResult(false, rawResponse);
  }
}
