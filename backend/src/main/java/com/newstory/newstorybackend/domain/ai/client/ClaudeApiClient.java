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

  public String convert(String originalContent, String style, String level) {
    String prompt = buildConvertPrompt(originalContent, style, level);
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

  private String buildConvertPrompt(String content, String style, String level) {
    String glossaryInstruction = buildGlossaryInstruction(level);
    return switch (style) {
      case "fairy_tale" ->
          "다음 뉴스 기사를 초등학생도 이해할 수 있는 동화체로 변환해주세요. 사실은 그대로 유지하고 형식만 바꾸세요.\n\n"
              + glossaryInstruction
              + "\n\n"
              + content;
      case "novel" ->
          "다음 뉴스 기사를 몰입감 있는 소설체로 변환해주세요. 사실은 그대로 유지하고 형식만 바꾸세요.\n\n"
              + glossaryInstruction
              + "\n\n"
              + content;
      case "card" ->
          "다음 뉴스 기사를 핵심만 담은 카드요약 형식(bullet 5개 이하)으로 변환해주세요.\n\n"
              + glossaryInstruction
              + "\n\n"
              + content;
      default -> throw new IllegalArgumentException("지원하지 않는 스타일: " + style);
    };
  }

  private String buildGlossaryInstruction(String level) {
    String countGuide =
        switch (level) {
          case "LOW" -> "7개 이상 (많은 용어를 설명해줘야 하는 독자 대상)";
          case "HIGH" -> "1~2개 (배경지식이 풍부한 독자 대상, 꼭 필요한 핵심 용어만)";
          default -> "3~5개";
        };
    return """
        변환 본문 안에서 독자가 이해하기 어려울 수 있는 용어 %s을 골라,
        해당 용어가 처음 등장하는 위치에 {{term:용어|뜻풀이}} 형식으로 인라인 마킹하세요.
        마킹 규칙:
        - 한 용어는 최초 1회만 마킹
        - 마커가 없어도 문장이 자연스럽게 읽혀야 함
        - 예: "정부가 {{term:물가|상품과 서비스의 평균 가격 수준}}를 안정시키겠다고 밝혔다."
        용어 마킹이 불필요하면 마커 없이 변환 텍스트만 출력해도 됩니다."""
        .formatted(countGuide);
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
