package com.newstory.newstorybackend.domain.user.service;

import com.newstory.newstorybackend.domain.user.dto.UpdateUserRequest;
import com.newstory.newstorybackend.domain.user.dto.UserResponse;
import com.newstory.newstorybackend.domain.user.entity.InterestCategories;
import com.newstory.newstorybackend.domain.user.entity.User;
import com.newstory.newstorybackend.domain.user.repository.UserRepository;
import com.newstory.newstorybackend.global.exception.BadRequestException;
import com.newstory.newstorybackend.global.exception.UnauthorizedException;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserService {

  private final UserRepository userRepository;

  @Transactional(readOnly = true)
  public UserResponse getMe(User user) {
    return new UserResponse(user);
  }

  @Transactional
  public UserResponse updateMe(User user, UpdateUserRequest request) {
    User managed =
        userRepository
            .findById(user.getId())
            .orElseThrow(() -> new UnauthorizedException("사용자를 찾을 수 없습니다."));
    if (request.getNickname() != null) {
      managed.updateNickname(request.getNickname());
    }
    if (request.getWidgetEnabled() != null) {
      managed.updateWidgetEnabled(request.getWidgetEnabled());
    }
    if (request.getInterestCategories() != null) {
      List<String> requested = request.getInterestCategories();
      List<String> invalid =
          requested.stream().filter(c -> !InterestCategories.ALLOWED.contains(c)).toList();
      if (!invalid.isEmpty()) {
        throw new BadRequestException("지원하지 않는 카테고리입니다: " + String.join(", ", invalid));
      }
      managed.updateInterestCategories(requested.stream().distinct().toList());
    }
    return new UserResponse(managed);
  }
}
