package com.newstory.newstorybackend.domain.convert.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;

@Getter
public class ConvertRequest {

  @NotBlank private String url;

  @NotBlank
  @Pattern(regexp = "fairy_tale|novel|card", message = "style은 fairy_tale, novel, card 중 하나여야 합니다.")
  private String style;

  @Pattern(regexp = "LOW|MEDIUM|HIGH", message = "level은 LOW, MEDIUM, HIGH 중 하나여야 합니다.")
  private String level;
}
