-- Run in the Supabase SQL Editor.
-- These policies permit signed-in users to manage only their own registration documents.
-- Keep both storage buckets private.

update storage.buckets
set public = false
where id in ('payment-proofs', 'b-form-images');

drop policy if exists "Registration users upload own documents" on storage.objects;
drop policy if exists "Registration users read own documents" on storage.objects;
drop policy if exists "Registration users delete own documents" on storage.objects;
drop policy if exists "amun_temporary_pause_document_uploads" on storage.objects;
drop policy if exists "Delegate payment proof uploads" on storage.objects;
drop policy if exists "Delegate B-Form image uploads" on storage.objects;

create policy "Registration users upload own documents"
    on storage.objects
    for insert
    to authenticated
    with check (
        (storage.foldername(name))[1] = 'registrations'
        and (storage.foldername(name))[2] = (select auth.uid())::text
        and (
            (bucket_id = 'payment-proofs' and (storage.foldername(name))[3] = 'proofs')
            or
            (bucket_id = 'b-form-images' and (storage.foldername(name))[3] = 'b-forms')
        )
    );

create policy "Registration users read own documents"
    on storage.objects
    for select
    to authenticated
    using (
        (storage.foldername(name))[1] = 'registrations'
        and (storage.foldername(name))[2] = (select auth.uid())::text
        and (
            (bucket_id = 'payment-proofs' and (storage.foldername(name))[3] = 'proofs')
            or
            (bucket_id = 'b-form-images' and (storage.foldername(name))[3] = 'b-forms')
        )
    );

create policy "Registration users delete own documents"
    on storage.objects
    for delete
    to authenticated
    using (
        (storage.foldername(name))[1] = 'registrations'
        and (storage.foldername(name))[2] = (select auth.uid())::text
        and (
            (bucket_id = 'payment-proofs' and (storage.foldername(name))[3] = 'proofs')
            or
            (bucket_id = 'b-form-images' and (storage.foldername(name))[3] = 'b-forms')
        )
    );

grant insert on table public.registrations to authenticated;

drop policy if exists "amun_temporary_pause_registrations_insert" on public.registrations;
drop policy if exists "AMUN admin access guard" on public.registrations;

create policy "AMUN admin access guard"
    on public.registrations
    as restrictive
    for all
    to authenticated
    using (
        lower(coalesce((select auth.jwt() ->> 'email'), '')) = 'registeration-team@mun.com'
        or lower(btrim(email)) = amun_registration_email_for_current_user()
    )
    with check (
        lower(coalesce((select auth.jwt() ->> 'email'), '')) = 'registeration-team@mun.com'
        or lower(btrim(email)) = amun_registration_email_for_current_user()
    );
