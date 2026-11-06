-- Run this after checking that no views, triggers, or external systems depend
-- on registrations.id or registrations.registration_id.
-- The admin panel identifies registrations by their unique email.
begin;

do $$
begin
    if exists (
        select 1
        from pg_constraint
        where contype = 'f'
          and confrelid = 'public.registrations'::regclass
    ) then
        raise exception
            'Cannot remove registrations.id while another table has a foreign key to registrations. Review those references first.';
    end if;

    if exists (
        select 1
        from public.registrations
        group by lower(btrim(email))
        having count(*) > 1
    ) then
        raise exception
            'Cannot identify registrations by email while duplicate normalized email addresses exist.';
    end if;
end
$$;

create unique index if not exists registrations_email_unique_idx
    on public.registrations (lower(btrim(email)));

alter table public.registrations
    drop constraint if exists registrations_pkey,
    drop column if exists id,
    drop column if exists registration_id;

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

commit;
