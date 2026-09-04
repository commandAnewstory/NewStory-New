package com.newstory.newstorybackend.domain.auth.service;

import com.newstory.newstorybackend.domain.auth.dto.LoginRequest;
import com.newstory.newstorybackend.domain.auth.dto.LoginResponse;
import com.newstory.newstorybackend.domain.auth.dto.RefreshRequest;
import com.newstory.newstorybackend.domain.auth.dto.SignupRequest;
import com.newstory.newstorybackend.domain.auth.dto.TokenResponse;
import com.newstory.newstorybackend.domain.user.entity.User;
import com.newstory.newstorybackend.domain.user.repository.UserRepository;
import com.newstory.newstorybackend.global.auth.JwtUtil;
import com.newstory.newstorybackend.global.auth.RefreshTokenStore;
import com.newstory.newstorybackend.global.exception.ConflictException;
import com.newstory.newstorybackend.global.exception.UnauthorizedException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

  private final UserRepository userRepository;
  private final PasswordEncoder passwordEncoder;
  private final JwtUtil jwtUtil;
  private final RefreshTokenStore refreshTokenStore;

  @Transactional
  public void signup(SignupRequest request) {
    if (userRepository.existsByEmail(request.getEmail())) {
      throw new ConflictException("이미 사용 중인 이메일입니다.");
    }
    User user =
        User.builder()
            .email(request.getEmail())
            .password(passwordEncoder.encode(request.getPassword()))
            .nickname(request.getNickname())
            .build();
    userRepository.save(user);
  }

  @Transactional(readOnly = true)
  public LoginResponse login(LoginRequest request) {
    User user =
        userRepository
            .findByEmail(request.getEmail())
            .orElseThrow(() -> new UnauthorizedException("이메일 또는 비밀번호가 올바르지 않습니다."));

    if (user.getPassword() == null
        || !passwordEncoder.matches(request.getPassword(), user.getPassword())) {
      throw new UnauthorizedException("이메일 또는 비밀번호가 올바르지 않습니다.");
    }

    String accessToken = jwtUtil.generateAccessToken(user.getId(), user.getEmail());
    String refreshToken = jwtUtil.generateRefreshToken(user.getId());
    refreshTokenStore.save(refreshToken, user.getId());

    return new LoginResponse(accessToken, refreshToken, user.getNickname());
  }

  public void logout(String refreshToken) {
    refreshTokenStore.delete(refreshToken);
  }

  @Transactional(readOnly = true)
  public TokenResponse refresh(RefreshRequest request) {
    String refreshToken = request.getRefreshToken();

    if (!refreshTokenStore.exists(refreshToken)) {
      throw new UnauthorizedException("유효하지 않은 토큰입니다.");
    }
    if (!jwtUtil.validateToken(refreshToken)) {
      refreshTokenStore.delete(refreshToken);
      throw new UnauthorizedException("유효하지 않은 토큰입니다.");
    }

    Long userId = jwtUtil.getUserIdFromToken(refreshToken);
    User user =
        userRepository
            .findById(userId)
            .orElseThrow(() -> new UnauthorizedException("유효하지 않은 토큰입니다."));

    return new TokenResponse(jwtUtil.generateAccessToken(user.getId(), user.getEmail()));
  }
}
