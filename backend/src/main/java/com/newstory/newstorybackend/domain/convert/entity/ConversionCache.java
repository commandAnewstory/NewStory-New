package com.newstory.newstorybackend.domain.convert.entity;

import com.newstory.newstorybackend.domain.news.entity.NewsArticle;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.LocalDateTime;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(
    name = "conversion_cache",
    uniqueConstraints = @UniqueConstraint(columnNames = {"article_id", "style"}))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ConversionCache {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "article_id", nullable = false)
  private NewsArticle article;

  @Column(nullable = false, length = 20)
  private String style;

  @Column(nullable = false, columnDefinition = "TEXT")
  private String convertedText;

  @Column(name = "verification_passed", nullable = false)
  private Boolean verificationPassed = false;

  @Column(name = "verification_method", length = 30)
  private String verificationMethod;

  @Column(nullable = false)
  private Integer retryCount = 0;

  @CreationTimestamp
  @Column(name = "created_at", nullable = false, updatable = false)
  private LocalDateTime createdAt;

  @Builder
  public ConversionCache(
      NewsArticle article,
      String style,
      String convertedText,
      Boolean verificationPassed,
      String verificationMethod,
      Integer retryCount) {
    this.article = article;
    this.style = style;
    this.convertedText = convertedText;
    this.verificationPassed = verificationPassed != null ? verificationPassed : false;
    this.verificationMethod = verificationMethod;
    this.retryCount = retryCount != null ? retryCount : 0;
  }
}
