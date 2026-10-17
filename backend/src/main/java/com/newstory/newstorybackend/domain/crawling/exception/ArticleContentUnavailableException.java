package com.newstory.newstorybackend.domain.crawling.exception;

import com.newstory.newstorybackend.global.exception.BusinessException;
import org.springframework.http.HttpStatus;

/** 기사 페이지는 열렸지만 본문을 하나도 뽑지 못한 경우. 빈 본문으로 화면을 그리거나 AI를 부르지 않도록 실패로 돌려준다. */
public class ArticleContentUnavailableException extends BusinessException {

  public ArticleContentUnavailableException() {
    super("기사 본문을 가져오지 못했어요. 원문 사이트에서 확인해 주세요.", HttpStatus.BAD_GATEWAY);
  }
}
