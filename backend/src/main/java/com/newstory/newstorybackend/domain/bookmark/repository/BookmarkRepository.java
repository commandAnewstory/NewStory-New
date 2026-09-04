package com.newstory.newstorybackend.domain.bookmark.repository;

import com.newstory.newstorybackend.domain.bookmark.entity.Bookmark;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BookmarkRepository extends JpaRepository<Bookmark, Long> {

  List<Bookmark> findByUserIdOrderByCreatedAtDesc(Long userId);

  Optional<Bookmark> findByUserIdAndResultId(Long userId, Long resultId);

  boolean existsByUserIdAndResultId(Long userId, Long resultId);
}
