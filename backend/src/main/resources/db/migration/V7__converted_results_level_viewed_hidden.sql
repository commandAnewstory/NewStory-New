-- 같은 사용자가 같은 기사·스타일·레벨을 다시 열면 기존 행을 재사용한다 (2026-10-12 결정, 서브플랜 15 A안)
ALTER TABLE converted_results ADD COLUMN level VARCHAR(10) NOT NULL DEFAULT 'MEDIUM';

-- 히스토리 정렬 기준: 처음 만든 시간이 아니라 마지막으로 본 시간
ALTER TABLE converted_results ADD COLUMN viewed_at TIMESTAMP;
UPDATE converted_results SET viewed_at = created_at;
ALTER TABLE converted_results ALTER COLUMN viewed_at SET NOT NULL;
ALTER TABLE converted_results ALTER COLUMN viewed_at SET DEFAULT NOW();

-- 보관함에 있는 항목을 히스토리에서 지우면 행을 지우지 않고 히스토리에서만 숨긴다 (2026-10-12 결정)
ALTER TABLE converted_results ADD COLUMN hidden_from_history BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX idx_converted_results_user_article_style_level
    ON converted_results (user_id, article_id, style, level);
