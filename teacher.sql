-- 容積代金檢核教室 教師頁用。於 Supabase SQL Editor 執行一次（schema.sql 已執行過的前提下）。
-- 做兩件事：一、存一組教師密碼的雜湊；二、建立憑教師密碼讀取全班紀錄的函式 teacher_data。
-- 學生端的 anon key 仍然只能新增紀錄，讀不到任何資料；沒有教師密碼就呼叫 teacher_data 只會得到錯誤。

create extension if not exists pgcrypto with schema extensions;

create table if not exists teacher_secret (id int primary key check (id = 1), pass_hash text not null, updated_at timestamptz default now());
alter table teacher_secret enable row level security; -- 不建立任何政策：只有下方函式讀得到

-- ★ 執行前，請把下一行單引號裡的文字改成您自己的教師密碼（至少 10 個字）。之後要換密碼，改掉再執行這一段即可。
insert into teacher_secret (id, pass_hash) values (1, extensions.crypt('請改成您的教師密碼', extensions.gen_salt('bf')))
  on conflict (id) do update set pass_hash = excluded.pass_hash, updated_at = now();

create or replace function teacher_data(p_pass text) returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare h text;
begin
  select pass_hash into h from teacher_secret where id = 1;
  if h is null or p_pass is null or length(p_pass) < 10 or h <> crypt(p_pass, h) or h = crypt('請改成您的教師密碼', h) then
    perform pg_sleep(1); -- 拖慢亂猜密碼
    raise exception 'wrong password';
  end if;
  return jsonb_build_object(
    'quiz', (select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) from (select created_at, student_id, group_code, q_index, chosen, correct from quiz_answers order by id desc limit 30000) t),
    'review', (select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) from (select created_at, student_id, group_code, case_key, hit, miss, false_alarm, picked from review_results order by id desc limit 5000) t),
    'ai', (select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) from (select created_at, student_id, group_code, mode, prompt, ai_answer, correction from ai_logs order by id desc limit 1500) t),
    'cases', (select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb) from (select group_code, updated_by, updated_at, data from group_cases order by group_code) t));
end $$;
revoke all on function teacher_data(text) from public;
grant execute on function teacher_data(text) to anon;
