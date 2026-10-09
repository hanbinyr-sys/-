-- ─────────────────────────────────────────────────────────────
-- 붕어빵 타이쿤 · 계정별 저장 테이블
--
-- Supabase 대시보드 → SQL Editor 에 붙여넣고 Run 한 번.
-- 여러 번 실행해도 안전하다. 이미 저장된 게임 기록은 지우지 않는다.
-- 이걸 먼저 실행한 다음 supabase_계정삭제.sql 을 실행한다.
-- ─────────────────────────────────────────────────────────────

-- 계정당 저장 한 줄
create table if not exists public.bungeo_saves (
  user_id    uuid        primary key references auth.users (id) on delete cascade,
  state      jsonb       not null,
  revision   integer     not null default 1,
  updated_at timestamptz not null default now()
);

-- 본인 기록만 읽을 수 있다. 쓰기는 아래 save_bungeo 함수로만 한다.
alter table public.bungeo_saves enable row level security;

drop policy if exists "본인 저장 읽기" on public.bungeo_saves;
create policy "본인 저장 읽기" on public.bungeo_saves
  for select to authenticated
  using ((select auth.uid()) = user_id);

revoke all    on table public.bungeo_saves from public, anon, authenticated;
grant  select on table public.bungeo_saves to authenticated;

-- 저장: 마지막으로 읽은 버전(p_expected_revision)이 서버 버전과 같을 때만 덮어쓴다.
-- 다른 기기가 먼저 저장했으면 40001 오류를 내고, 게임은 충돌 안내를 띄운다.
-- 성공하면 새 버전 번호를 돌려준다.
create or replace function public.save_bungeo(p_state jsonb, p_expected_revision integer)
returns integer
language plpgsql
security definer           -- 테이블 쓰기 권한으로 실행 (직접 쓰기는 막아 둠)
set search_path = ''       -- 경로 하이재킹 방지 (Supabase 보안 권장)
as $$
declare
  uid     uuid := auth.uid();  -- 요청을 보낸 본인의 id. 클라이언트가 조작 불가
  new_rev integer;
begin
  if uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if p_state is null or jsonb_typeof(p_state) <> 'object' then
    raise exception 'invalid save state' using errcode = '22023';
  end if;
  if octet_length(p_state::text) > 1048576 then  -- 1MB (게임의 파일 가져오기 한도와 같음)
    raise exception 'save state too large' using errcode = '22023';
  end if;

  if coalesce(p_expected_revision, 0) = 0 then
    -- 첫 저장. 그 사이 다른 기기가 먼저 만들었으면 충돌
    insert into public.bungeo_saves (user_id, state, revision, updated_at)
    values (uid, p_state, 1, now())
    on conflict (user_id) do nothing
    returning revision into new_rev;
  else
    update public.bungeo_saves
       set state = p_state, revision = revision + 1, updated_at = now()
     where user_id = uid and revision = p_expected_revision
    returning revision into new_rev;
  end if;

  if new_rev is null then
    raise exception 'save conflict' using errcode = '40001';
  end if;
  return new_rev;
end;
$$;

-- 로그인한 사용자(익명 포함)만 호출 가능. 비로그인·공개 호출은 차단.
revoke all     on function public.save_bungeo(jsonb, integer) from public, anon;
grant  execute on function public.save_bungeo(jsonb, integer) to authenticated;
