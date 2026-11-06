alter table public.registrations
    add column if not exists payment_proof_path text,
    drop column if exists school,
    drop column if exists grade,
    drop column if exists city,
    drop column if exists school_contact,
    drop column if exists previous_mun,
    drop column if exists previous_muns,
    drop column if exists awards,
    drop column if exists motivation;

insert into storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
values (
    'payment-proofs',
    'payment-proofs',
    false,
    5242880,
    array['image/jpeg', 'image/png', 'application/pdf']
)
on conflict (id) do update
set
    public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Delegate payment proof uploads" on storage.objects;
create policy "Delegate payment proof uploads"
on storage.objects
for insert
to anon, authenticated
with check (
    bucket_id = 'payment-proofs'
    and (storage.foldername(name))[1] = 'proofs'
    and cardinality(storage.foldername(name)) = 2
);

drop policy if exists "Admins read payment proofs" on storage.objects;
create policy "Admins read payment proofs"
on storage.objects
for select
to authenticated
using (bucket_id = 'payment-proofs');
