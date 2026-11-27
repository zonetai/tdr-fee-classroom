# 容積代金檢核教室

政大地政「都市更新與容積代金估價實務」115-1 教學工具。單一靜態頁，無建置步驟。

- `index.html`：網站本體（GitHub Pages 直接提供）
- `schema.sql`：Supabase 資料表、RLS 與存取函式，於 SQL Editor 執行一次
- 連線資料庫：在 `index.html` 內 `const SB = { url: '', key: '' }` 填入專案 URL 與 anon public key；留空則網站照常運作但不記錄

資料表：`quiz_answers`（判斷題）、`review_results`（審查演練）、`ai_logs`（AI 使用紀錄）、`group_cases`（各組參數，憑組密碼）。
學生端只能新增，不能讀取他人紀錄。學號未經驗證，可能被冒填，成績採計前請與繳交資料交叉核對。

教學用工具，檢核門檻非審議依據。

## AI 助教

「AI 助教」分頁直接呼叫 Supabase Edge Function `tdr-tutor`（原始碼在 `supabase/functions/tdr-tutor/index.ts`，做法比照 zonetai/appraiser-exam-platform 的 `grade`）。函式部署在與該平台相同的 Supabase 專案，沿用其 `ANTHROPIC_API_KEY`，金鑰不進前端。端點網址寫在 `index.html` 的 `const AI = { endpoint }`，留空則只提供「複製提示詞」。

- 只接受 `https://zonetai.github.io` 來源；需學號（6 至 12 碼英數字）。
- 限流：每學號每小時 20 次、每 IP 300 次、全站 600 次（可用 `TUTOR_HOURLY_PER_STUDENT`、`TUTOR_HOURLY_PER_IP`、`TUTOR_HOURLY_TOTAL` 調整），模型可用 `TUTOR_MODEL` 指定。限流只在同一執行個體內有效，請另在 Anthropic Console 設定每月用量上限。
- 函式不儲存對話；學生按「存入使用紀錄」才會寫入 `ai_logs`。

## 教師頁

網址後綴 `#teacher`（頁尾也有入口）。輸入教師密碼後，讀取全班的測驗、審查演練、AI 使用紀錄與各組參數，顯示各組總覽、學生明細、各題答對率，並可匯出 CSV。

啟用方式：在 Supabase 的 SQL Editor 執行一次 `teacher.sql`，執行前把檔案裡「請改成您的教師密碼」改成自己的密碼（至少 10 個字）。資料庫只存密碼雜湊，密碼不寫進網頁或 repo；學生端的 anon key 仍然讀不到任何資料。

AI 助教的每一輪對話會自動寫入 `ai_logs`（模式欄標示「自動」），學生另外按「存入使用紀錄」的整段紀錄與修正也在同一張表。
