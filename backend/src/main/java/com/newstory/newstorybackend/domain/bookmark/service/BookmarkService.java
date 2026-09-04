package com.newstory.newstorybackend.domain.bookmark.service;

import com.newstory.newstorybackend.domain.bookmark.dto.BookmarkResponse;
import com.newstory.newstorybackend.domain.bookmark.entity.Bookmark;
import com.newstory.newstorybackend.domain.bookmark.repository.BookmarkRepository;
import com.newstory.newstorybackend.domain.convert.entity.ConvertedResult;
import com.newstory.newstorybackend.domain.convert.repository.ConvertedResultRepository;
import com.newstory.newstorybackend.domain.user.entity.User;
import com.newstory.newstorybackend.global.exception.ConflictException;
import com.newstory.newstorybackend.global.exception.NotFoundException;
import com.newstory.newstorybackend.global.exception.UnauthorizedException;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class BookmarkService {

  private final BookmarkRepository bookmarkRepository;
  private final ConvertedResultRepository convertedResultRepository;

  @Transactional(readOnly = true)
  public List<BookmarkResponse> getBookmarks(Long userId) {
    return bookmarkRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
        .map(BookmarkResponse::new)
        .toList();
  }

  @Transactional
  public void addBookmark(Long resultId, User user) {
    if (bookmarkRepository.existsByUserIdAndResultId(user.getId(), resultId)) {
      throw new ConflictException("이미 보관함에 추가된 항목입니다.");
    }

    ConvertedResult result =
        convertedResultRepository
            .findById(resultId)
            .orElseThrow(() -> new NotFoundException("변환 결과를 찾을 수 없습니다."));

    bookmarkRepository.save(Bookmark.builder().user(user).result(result).build());
  }

  @Transactional
  public void removeBookmark(Long resultId, Long userId) {
    Bookmark bookmark =
        bookmarkRepository
            .findByUserIdAndResultId(userId, resultId)
            .orElseThrow(() -> new NotFoundException("보관함 항목을 찾을 수 없습니다."));

    if (!bookmark.getUser().getId().equals(userId)) {
      throw new UnauthorizedException("접근 권한이 없습니다.");
    }

    bookmarkRepository.delete(bookmark);
  }
}
