package com.newstory.newstorybackend.domain.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

@Getter
public class SocialLoginRequest {

  @NotBlank private String token;
}
