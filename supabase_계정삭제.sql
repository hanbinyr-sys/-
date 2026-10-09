-- ─────────────────────────────────────────────────────────────
-- 붕어빵 타이쿤 · 앱 안에서 계정 삭제
-- (애플 App Store 5.1.1(v), 구글 플레이 계정 삭제 요건)
--
-- Supabase 대시보드 → SQL Editor 에 붙여넣고 Run 한 번.
-- 로그인한 본인 계정만 지울 수 있고, 남의 계정은 못 지운다.
-- ─────────────────────────────────────────────────────────────

create or replace function public.delete_bungeo_account()
returns void
language plpgsql
security definer           -- 계정 테이블(auth.users)을 지울 권한으로 실행
set search_path = ''       -- 경로 하이재킹 방지 (Supabase 보안 권장)
as $$
declare
  uid uuid := auth.uid();  -- 요청을 보낸 본인의 id. 클라이언트가 조작 불가
begin
  if uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  delete from public.bungeo_saves where user_id = uid;  -- 가게 기록
  delete from auth.users          where id      = uid;  -- 계정 자체 (세션도 함께 정리됨)
end;
$$;

-- 로그인한 사용자(익명 포함)만 호출 가능. 비로그인·공개 호출은 차단.
revoke all     on function public.delete_bungeo_account() from public, anon;
grant  execute on function public.delete_bungeo_account() to authenticated;
