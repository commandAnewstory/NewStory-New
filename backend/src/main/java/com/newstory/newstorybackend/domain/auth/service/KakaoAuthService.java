package com.newstory.newstorybackend.domain.auth.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.newstory.newstorybackend.domain.auth.dto.SocialUserInfo;
import com.newstory.newstorybackend.global.exception.UnauthorizedException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Slf4j
@Service
public class KakaoAuthService {

  private static final String USER_INFO_URL = "https://kapi.kakao.com/v2/user/me";
  private static final String PROVIDER = "kakao";

  private final RestTemplate restTemplate;
  private final ObjectMapper objectMapper = new ObjectMapper();

  public KakaoAuthService(RestTemplate restTemplate) {
    this.restTemplate = restTemplate;
  }

  public SocialUserInfo getUserInfo(String accessToken) {
    HttpHeaders headers = new HttpHeaders();
    headers.setBearerAuth(accessToken);
    headers.set("Content-type", "application/x-www-form-urlencoded;charset=utf-8");

    try {
      ResponseEntity<String> response =
          restTemplate.exchange(
              USER_INFO_URL, HttpMethod.GET, new HttpEntity<>(headers), String.class);

      JsonNode root = objectMapper.readTree(response.getBody());
      String providerId = root.path("id").asText();
      String email =
          root.path("kakao_account").path("email").isMissingNode()
              ? providerId + "@kakao.com"
              : root.path("kakao_account").path("email").asText();

      return new SocialUserInfo(PROVIDER, providerId, email);
    } catch (Exception e) {
      log.error("카카오 사용자 정보 조회 실패: {}", e.getMessage());
      throw new UnauthorizedException("유효하지 않은 카카오 토큰입니다.");
    }
  }
}
