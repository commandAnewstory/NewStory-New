package com.newstory.newstorybackend.domain.user.dto;

import jakarta.validation.constraints.Size;
import java.util.List;
import lombok.Getter;

@Getter
public class UpdateUserRequest {

  @Size(min = 1, max = 50)
  private String nickname;

  private Boolean widgetEnabled;

  /** 관심 카테고리. null이면 변경 안 함, 빈 배열이면 전체로 초기화 */
  private List<String> interestCategories;
}
