package com.newstory.newstorybackend.domain.ai.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.newstory.newstorybackend.domain.ai.dto.VerificationResult;
import java.util.List;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Slf4j
@Component
public class ClaudeApiClient {

  private static final String API_URL = "https://api.anthropic.com/v1/messages";
  private static final String MODEL = "claude-opus-4-7";

  private final String apiKey;
  private final RestTemplate restTemplate;
  private final ObjectMapper objectMapper = new ObjectMapper();

  public ClaudeApiClient(@Value("${claude.api-key}") String apiKey, RestTemplate restTemplate) {
    this.apiKey = apiKey;
    this.restTemplate = restTemplate;
  }

  public String convert(String originalContent, String style) {
    String prompt = buildConvertPrompt(originalContent, style);
    return callClaude(prompt);
  }

  public VerificationResult verify(String originalContent, String convertedText) {
    String prompt = buildVerifyPrompt(originalContent, convertedText);
    String response = callClaude(prompt);

    if (response.trim().toUpperCase().startsWith("PASS")) {
      return VerificationResult.passed();
    }
    return VerificationResult.failed(response);
  }

  private String callClaude(String prompt) {
    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(MediaType.APPLICATION_JSON);
    headers.set("x-api-key", apiKey);
    headers.set("anthropic-version", "2023-06-01");

    Map<String, Object> body =
        Map.of(
            "model",
            MODEL,
            "max_tokens",
            4096,
            "messages",
            List.of(Map.of("role", "user", "content", prompt)));

    HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);

    try {
      String response = restTemplate.postForObject(API_URL, entity, String.class);
      JsonNode root = objectMapper.readTree(response);
      return root.path("content").get(0).path("text").asText();
    } catch (Exception e) {
      log.error("Claude API 호출 실패: {}", e.getMessage());
      throw new RuntimeException("Claude API 호출 실패", e);
    }
  }

  private String buildConvertPrompt(String content, String style) {
    return switch (style) {
      case "fairy_tale" ->
          "다음 뉴스 기사를 초등학생도 이해할 수 있는 동화체로 변환해주세요. 사실은 그대로 유지하고 형식만 바꾸세요.\n\n" + content;
      case "novel" -> "다음 뉴스 기사를 몰입감 있는 소설체로 변환해주세요. 사실은 그대로 유지하고 형식만 바꾸세요.\n\n" + content;
      case "card" -> "다음 뉴스 기사를 핵심만 담은 카드요약 형식(bullet 5개 이하)으로 변환해주세요.\n\n" + content;
      default -> throw new IllegalArgumentException("지원하지 않는 스타일: " + style);
    };
  }

  private String buildVerifyPrompt(String original, String converted) {
    return """
                원본 뉴스 기사와 변환된 텍스트를 비교하여 사실 왜곡 여부를 검증해주세요.
                사실이 정확히 유지되었으면 첫 줄에 "PASS"를 출력하세요.
                문제가 있으면 첫 줄에 "FAIL"을 쓰고, 구체적인 문제점을 설명해주세요.

                [원본]
                %s

                [변환]
                %s
                """
        .formatted(original, converted);
  }
}
