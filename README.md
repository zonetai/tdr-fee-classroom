# 容積代金檢核教室

政大地政「都市更新與容積代金估價實務」115-1 教學工具。單一靜態頁，無建置步驟。

- `index.html`：網站本體（GitHub Pages 直接提供）
- `schema.sql`：Supabase 資料表、RLS 與存取函式，於 SQL Editor 執行一次
- 連線資料庫：在 `index.html` 內 `const SB = { url: '', key: '' }` 填入專案 URL 與 anon public key；留空則網站照常運作但不記錄

資料表：`quiz_answers`（判斷題）、`review_results`（審查演練）、`ai_logs`（AI 使用紀錄）、`group_cases`（各組參數，憑組密碼）。
學生端只能新增，不能讀取他人紀錄。學號未經驗證，可能被冒填，成績採計前請與繳交資料交叉核對。

教學用工具，檢核門檻非審議依據。
