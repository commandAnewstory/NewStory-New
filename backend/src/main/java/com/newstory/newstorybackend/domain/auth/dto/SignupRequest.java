package com.newstory.newstorybackend.domain.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;

@Getter
public class SignupRequest {

  @NotBlank @Email private String email;

  @NotBlank
  @Size(min = 8)
  private String password;

  @NotBlank
  @Size(min = 1, max = 50)
  private String nickname;
}
