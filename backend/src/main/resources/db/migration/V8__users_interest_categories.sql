-- 관심 카테고리 (쉼표 구분, 빈 문자열 = 전체). 위젯 "관심 뉴스"에 사용 (서브플랜 백엔드 18)
ALTER TABLE users ADD COLUMN interest_categories VARCHAR(100) NOT NULL DEFAULT '';
