-- 容積代金檢核教室 資料表。於 Supabase SQL Editor 執行一次。
-- 學生端使用公開 anon key：只能新增紀錄，不能讀取他人資料；各組參數須憑組密碼存取。老師由 Supabase 後台檢視。
create table if not exists quiz_answers (id bigint generated always as identity primary key, created_at timestamptz default now(),
  student_id text not null check (student_id ~ '^[0-9A-Za-z]{6,12}$'), group_code text, q_index int not null, chosen int not null, correct boolean not null);
create table if not exists review_results (id bigint generated always as identity primary key, created_at timestamptz default now(),
  student_id text not null check (student_id ~ '^[0-9A-Za-z]{6,12}$'), group_code text, case_key text not null, hit int, miss int, false_alarm int, picked jsonb);
create table if not exists ai_logs (id bigint generated always as identity primary key, created_at timestamptz default now(),
  student_id text not null check (student_id ~ '^[0-9A-Za-z]{6,12}$'), group_code text, mode text, prompt text, ai_answer text check (length(ai_answer) < 20000), correction text);
create table if not exists group_cases (group_code text primary key, pin_hash text not null, data jsonb not null, updated_by text, updated_at timestamptz default now());
alter table quiz_answers enable row level security; alter table review_results enable row level security;
alter table ai_logs enable row level security; alter table group_cases enable row level security;
create policy "anon insert" on quiz_answers for insert to anon with check (true);
create policy "anon insert" on review_results for insert to anon with check (true);
create policy "anon insert" on ai_logs for insert to anon with check (true);
-- group_cases 不開放任何 anon 政策，僅能透過下列函式存取
create extension if not exists pgcrypto with schema extensions;
create or replace function save_case(p_group text, p_pin text, p_student text, p_data jsonb) returns void language plpgsql security definer set search_path = public, extensions as $$
declare h text;
begin
  if length(p_pin) < 4 or length(p_group) > 20 or pg_column_size(p_data) > 20000 then raise exception 'invalid input'; end if;
  select pin_hash into h from group_cases where group_code = p_group;
  if h is null then insert into group_cases(group_code, pin_hash, data, updated_by) values (p_group, crypt(p_pin, gen_salt('bf')), p_data, p_student);
  elsif h = crypt(p_pin, h) then update group_cases set data = p_data, updated_by = p_student, updated_at = now() where group_code = p_group;
  else raise exception 'wrong pin'; end if;
end $$;
create or replace function load_case(p_group text, p_pin text) returns jsonb language sql security definer set search_path = public, extensions as $$
  select data from group_cases where group_code = p_group and pin_hash = crypt(p_pin, pin_hash) $$;
grant execute on function save_case(text, text, text, jsonb), load_case(text, text) to anon;
-- 老師檢視用
create or replace view quiz_summary as select student_id, max(group_code) as group_code, count(distinct q_index) as answered,
  count(distinct q_index) filter (where correct) as correct_any, min(created_at) as first_at, max(created_at) as last_at from quiz_answers group by student_id;
alter view quiz_summary set (security_invoker = on);
