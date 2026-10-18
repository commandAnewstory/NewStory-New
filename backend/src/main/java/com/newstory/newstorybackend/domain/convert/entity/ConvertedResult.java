package com.newstory.newstorybackend.domain.convert.entity;

import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import com.newstory.newstorybackend.domain.user.entity.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "converted_results")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class ConvertedResult {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "article_id", nullable = false)
  private NewsArticle article;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id")
  private User user;

  @Column(nullable = false, length = 20)
  private String style;

  @Column(name = "converted_text", nullable = false, columnDefinition = "TEXT")
  private String convertedText;

  /** true only when Claude verify() actually passed. */
  @Column(name = "verification_passed", nullable = false)
  @Builder.Default
  private Boolean verificationPassed = false;

  /**
   * gemma_verified — Gemma converted, Claude verified and passed. claude_fallback — Claude did the
   * final conversion (no verification passed).
   */
  @Column(name = "verification_method", length = 30)
  private String verificationMethod;

  @Column(name = "retry_count", nullable = false)
  @Builder.Default
  private Integer retryCount = 0;

  @Column(name = "is_feed", nullable = false)
  @Builder.Default
  private Boolean isFeed = false;

  @Column(nullable = false, length = 10)
  @Builder.Default
  private String level = "MEDIUM";

  @Column(name = "viewed_at", nullable = false)
  @Builder.Default
  private LocalDateTime viewedAt = LocalDateTime.now();

  @Column(name = "hidden_from_history", nullable = false)
  @Builder.Default
  private Boolean hiddenFromHistory = false;

  @CreationTimestamp
  @Column(name = "created_at", nullable = false, updatable = false)
  private LocalDateTime createdAt;

  /** 같은 기사·스타일·레벨을 다시 봤을 때: 최신 캐시 내용으로 맞추고, 본 시간 갱신, 히스토리에 다시 노출. */
  public void reuse(ConversionCache cache) {
    this.convertedText = cache.getConvertedText();
    this.verificationPassed = cache.getVerificationPassed();
    this.verificationMethod = cache.getVerificationMethod();
    this.retryCount = cache.getRetryCount();
    this.viewedAt = LocalDateTime.now();
    this.hiddenFromHistory = false;
  }

  public void hideFromHistory() {
    this.hiddenFromHistory = true;
  }
}
