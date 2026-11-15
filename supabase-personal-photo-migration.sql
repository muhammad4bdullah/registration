-- Run in the Supabase SQL Editor before deploying the personal-photo form changes.
-- Uploaded delegate photos remain private; owners and the AMUN registration admin can access them.

alter table public.registrations
    add column if not exists personal_photo_path text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'personal-photos',
    'personal-photos',
    false,
    5242880,
    array['image/jpeg', 'image/png']
)
on conflict (id) do update
set
    name = excluded.name,
    public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "AMUN users upload own personal photos" on storage.objects;
drop policy if exists "AMUN users read own personal photos" on storage.objects;
drop policy if exists "AMUN admins read personal photos" on storage.objects;
drop policy if exists "AMUN users delete own personal photos" on storage.objects;

create policy "AMUN users upload own personal photos"
    on storage.objects
    for insert
    to authenticated
    with check (
        bucket_id = 'personal-photos'
        and (storage.foldername(name))[2] = (select auth.uid())::text
        and (storage.foldername(name))[3] = 'personal-photos'
        and (storage.foldername(name))[1] in ('registrations', 'delegations')
    );

create policy "AMUN users read own personal photos"
    on storage.objects
    for select
    to authenticated
    using (
        bucket_id = 'personal-photos'
        and (storage.foldername(name))[2] = (select auth.uid())::text
        and (storage.foldername(name))[3] = 'personal-photos'
        and (storage.foldername(name))[1] in ('registrations', 'delegations')
    );

create policy "AMUN admins read personal photos"
    on storage.objects
    for select
    to authenticated
    using (
        bucket_id = 'personal-photos'
        and lower(coalesce((select auth.jwt() ->> 'email'), '')) = 'registeration-team@mun.com'
    );

create policy "AMUN users delete own personal photos"
    on storage.objects
    for delete
    to authenticated
    using (
        bucket_id = 'personal-photos'
        and (storage.foldername(name))[2] = (select auth.uid())::text
        and (storage.foldername(name))[3] = 'personal-photos'
        and (storage.foldername(name))[1] in ('registrations', 'delegations')
    );
