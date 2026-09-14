package com.newstory.newstorybackend.domain.user.service;

import com.newstory.newstorybackend.domain.user.dto.UpdateUserRequest;
import com.newstory.newstorybackend.domain.user.dto.UserResponse;
import com.newstory.newstorybackend.domain.user.entity.User;
import com.newstory.newstorybackend.domain.user.repository.UserRepository;
import com.newstory.newstorybackend.global.exception.UnauthorizedException;
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
    return new UserResponse(managed);
  }
}
