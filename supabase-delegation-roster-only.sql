-- Run in the Supabase SQL Editor after public.delegations exists.
-- Existing head-delegate data is preserved; new submissions use submitted_by_user_id.
-- Institution country is optional for new delegation submissions.

alter table public.delegations
    add column if not exists submitted_by_user_id uuid
        references auth.users(id) on delete cascade;

update public.delegations
set submitted_by_user_id = head_delegate_user_id
where submitted_by_user_id is null
  and head_delegate_user_id is not null;

alter table public.delegations
    alter column submitted_by_user_id set not null,
    alter column head_delegate_user_id drop not null,
    alter column head_delegate_name drop not null,
    alter column head_delegate_email drop not null,
    alter column head_delegate_phone drop not null,
    alter column country drop not null;

create index if not exists delegations_submitted_by_user_id_idx
    on public.delegations (submitted_by_user_id);

grant usage on schema public to authenticated;
grant insert, select, update on public.delegations to authenticated;

drop policy if exists "amun_temporary_pause_delegations_insert" on public.delegations;
drop policy if exists "Submit own delegation" on public.delegations;

create policy "Submit own delegation"
    on public.delegations
    for insert
    to authenticated
    with check (submitted_by_user_id = (select auth.uid()));
