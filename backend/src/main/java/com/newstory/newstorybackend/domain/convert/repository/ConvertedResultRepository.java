package com.newstory.newstorybackend.domain.convert.repository;

import com.newstory.newstorybackend.domain.convert.entity.ConvertedResult;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ConvertedResultRepository extends JpaRepository<ConvertedResult, Long> {

  List<ConvertedResult> findByUserIdOrderByCreatedAtDesc(Long userId);
}
