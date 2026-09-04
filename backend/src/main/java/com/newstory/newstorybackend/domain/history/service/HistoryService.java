package com.newstory.newstorybackend.domain.history.service;

import com.newstory.newstorybackend.domain.convert.entity.ConvertedResult;
import com.newstory.newstorybackend.domain.convert.repository.ConvertedResultRepository;
import com.newstory.newstorybackend.domain.history.dto.HistoryResponse;
import com.newstory.newstorybackend.global.exception.NotFoundException;
import com.newstory.newstorybackend.global.exception.UnauthorizedException;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class HistoryService {

  private final ConvertedResultRepository convertedResultRepository;

  @Transactional(readOnly = true)
  public List<HistoryResponse> getHistory(Long userId) {
    return convertedResultRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
        .map(HistoryResponse::new)
        .toList();
  }

  @Transactional
  public void delete(Long resultId, Long userId) {
    ConvertedResult result =
        convertedResultRepository
            .findById(resultId)
            .orElseThrow(() -> new NotFoundException("히스토리를 찾을 수 없습니다."));

    if (result.getUser() == null || !result.getUser().getId().equals(userId)) {
      throw new UnauthorizedException("접근 권한이 없습니다.");
    }

    convertedResultRepository.delete(result);
  }
}
