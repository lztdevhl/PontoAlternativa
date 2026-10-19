-- Alternativa Ponto | Fase 1
-- Esta migration é versionada para revisão. Não aplique em produção sem aprovação.

create extension if not exists pgcrypto;

create type public.app_role as enum ('owner', 'admin', 'hr', 'manager', 'employee', 'auditor');
create type public.punch_kind as enum ('in', 'out', 'break_start', 'break_end');
create type public.rep_event_kind as enum ('punch', 'device_registration', 'clock_adjustment');
create type public.request_status as enum ('pending', 'approved', 'rejected', 'cancelled');

create table public.companies (
  id uuid primary key default gen_random_uuid(),
  legal_name text not null,
  trade_name text,
  tax_id text unique,
  timezone text not null default 'America/Sao_Paulo',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.establishments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  name text not null,
  tax_id text,
  timezone text not null default 'America/Sao_Paulo',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (company_id, name)
);

create table public.departments (
  id uuid primary key default gen_random_uuid(),
  establishment_id uuid not null references public.establishments(id) on delete restrict,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (establishment_id, name)
);

create table public.employees (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references auth.users(id) on delete set null,
  establishment_id uuid not null references public.establishments(id) on delete restrict,
  department_id uuid references public.departments(id) on delete set null,
  registration_code text not null,
  full_name text not null,
  email text,
  active boolean not null default true,
  hired_on date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (establishment_id, registration_code)
);

create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  company_id uuid not null references public.companies(id) on delete restrict,
  establishment_id uuid references public.establishments(id) on delete restrict,
  role public.app_role not null,
  created_at timestamptz not null default now(),
  unique (user_id, company_id, establishment_id, role)
);

create table public.work_schedules (
  id uuid primary key default gen_random_uuid(),
  establishment_id uuid not null references public.establishments(id) on delete restrict,
  name text not null,
  weekly_rules jsonb not null default '{}'::jsonb,
  tolerance_minutes integer not null default 0 check (tolerance_minutes >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.schedule_assignments (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references public.employees(id) on delete restrict,
  work_schedule_id uuid not null references public.work_schedules(id) on delete restrict,
  starts_on date not null,
  ends_on date,
  created_at timestamptz not null default now(),
  check (ends_on is null or ends_on >= starts_on)
);

create table public.devices (
  id uuid primary key default gen_random_uuid(),
  establishment_id uuid not null references public.establishments(id) on delete restrict,
  employee_id uuid references public.employees(id) on delete set null,
  label text not null,
  device_fingerprint_hash text not null,
  last_seen_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

-- REP-P núcleo: eventos são append-only e carregam a origem e a cadeia de integridade.
create table public.rep_events (
  id uuid primary key default gen_random_uuid(),
  establishment_id uuid not null references public.establishments(id) on delete restrict,
  device_id uuid references public.devices(id) on delete restrict,
  employee_id uuid references public.employees(id) on delete restrict,
  event_kind public.rep_event_kind not null,
  nsr bigint not null,
  occurred_at timestamptz not null,
  server_received_at timestamptz not null default now(),
  payload jsonb not null default '{}'::jsonb,
  previous_hash text,
  chain_hash text not null,
  idempotency_key text not null,
  created_at timestamptz not null default now(),
  unique (establishment_id, nsr),
  unique (establishment_id, idempotency_key)
);

-- PTRP não modifica rep_events: cada tratamento referencia seu evento de origem.
create table public.time_punches (
  id uuid primary key default gen_random_uuid(),
  rep_event_id uuid not null unique references public.rep_events(id) on delete restrict,
  establishment_id uuid not null references public.establishments(id) on delete restrict,
  employee_id uuid not null references public.employees(id) on delete restrict,
  kind public.punch_kind not null,
  original_occurred_at timestamptz not null,
  server_received_at timestamptz not null,
  created_at timestamptz not null default now()
);

create table public.punch_receipts (
  id uuid primary key default gen_random_uuid(),
  time_punch_id uuid not null references public.time_punches(id) on delete restrict,
  storage_path text not null,
  sha256 text not null,
  signature_status text not null default 'pending',
  signed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.adjustment_requests (
  id uuid primary key default gen_random_uuid(),
  establishment_id uuid not null references public.establishments(id) on delete restrict,
  employee_id uuid not null references public.employees(id) on delete restrict,
  requested_by uuid not null references auth.users(id) on delete restrict,
  status public.request_status not null default 'pending',
  reason text not null,
  requested_start timestamptz,
  requested_end timestamptz,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.attendance_adjustments (
  id uuid primary key default gen_random_uuid(),
  establishment_id uuid not null references public.establishments(id) on delete restrict,
  employee_id uuid not null references public.employees(id) on delete restrict,
  adjustment_request_id uuid references public.adjustment_requests(id) on delete restrict,
  source_time_punch_id uuid references public.time_punches(id) on delete restrict,
  adjusted_start timestamptz,
  adjusted_end timestamptz,
  justification text not null,
  applied_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table public.leave_records (
  id uuid primary key default gen_random_uuid(),
  establishment_id uuid not null references public.establishments(id) on delete restrict,
  employee_id uuid not null references public.employees(id) on delete restrict,
  starts_on date not null,
  ends_on date not null,
  reason text,
  status public.request_status not null default 'pending',
  created_at timestamptz not null default now(),
  check (ends_on >= starts_on)
);

create table public.hour_bank_entries (
  id uuid primary key default gen_random_uuid(),
  establishment_id uuid not null references public.establishments(id) on delete restrict,
  employee_id uuid not null references public.employees(id) on delete restrict,
  minutes integer not null,
  reference_date date not null,
  source text not null,
  source_id uuid,
  created_at timestamptz not null default now()
);

create table public.attendance_summaries (
  id uuid primary key default gen_random_uuid(),
  establishment_id uuid not null references public.establishments(id) on delete restrict,
  employee_id uuid not null references public.employees(id) on delete restrict,
  reference_date date not null,
  worked_minutes integer not null default 0,
  scheduled_minutes integer not null default 0,
  balance_minutes integer not null default 0,
  calculation_version text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (employee_id, reference_date, calculation_version)
);

create table public.export_jobs (
  id uuid primary key default gen_random_uuid(),
  establishment_id uuid not null references public.establishments(id) on delete restrict,
  requested_by uuid not null references auth.users(id) on delete restrict,
  export_type text not null check (export_type in ('afd', 'aej', 'attendance_report')),
  status text not null default 'queued' check (status in ('queued', 'running', 'completed', 'failed')),
  storage_path text,
  sha256 text,
  signature_status text not null default 'pending',
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete restrict,
  establishment_id uuid references public.establishments(id) on delete restrict,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now()
);

create index establishments_company_id_idx on public.establishments(company_id);
create index employees_establishment_id_idx on public.employees(establishment_id);
create index rep_events_establishment_occurred_idx on public.rep_events(establishment_id, occurred_at);
create index time_punches_employee_occurred_idx on public.time_punches(employee_id, original_occurred_at);
create index audit_logs_establishment_occurred_idx on public.audit_logs(establishment_id, occurred_at desc);

create or replace function public.set_updated_at()
returns trigger language plpgsql security invoker set search_path = public as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger companies_set_updated_at before update on public.companies for each row execute function public.set_updated_at();
create trigger establishments_set_updated_at before update on public.establishments for each row execute function public.set_updated_at();
create trigger departments_set_updated_at before update on public.departments for each row execute function public.set_updated_at();
create trigger employees_set_updated_at before update on public.employees for each row execute function public.set_updated_at();
create trigger work_schedules_set_updated_at before update on public.work_schedules for each row execute function public.set_updated_at();
create trigger attendance_summaries_set_updated_at before update on public.attendance_summaries for each row execute function public.set_updated_at();

create or replace function public.user_has_company_access(target_company_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.user_roles where user_id = auth.uid() and company_id = target_company_id);
$$;

create or replace function public.user_has_establishment_access(target_establishment_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.user_roles ur
    where ur.user_id = auth.uid()
      and (ur.establishment_id = target_establishment_id or (ur.establishment_id is null and ur.company_id = (select e.company_id from public.establishments e where e.id = target_establishment_id)))
  );
$$;

create or replace function public.user_has_role(target_role public.app_role)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.user_roles where user_id = auth.uid() and role = target_role);
$$;

-- Todas as tabelas ficam protegidas. Eventos originais não recebem políticas de UPDATE/DELETE.
alter table public.companies enable row level security;
alter table public.establishments enable row level security;
alter table public.departments enable row level security;
alter table public.employees enable row level security;
alter table public.user_roles enable row level security;
alter table public.work_schedules enable row level security;
alter table public.schedule_assignments enable row level security;
alter table public.devices enable row level security;
alter table public.rep_events enable row level security;
alter table public.time_punches enable row level security;
alter table public.punch_receipts enable row level security;
alter table public.adjustment_requests enable row level security;
alter table public.attendance_adjustments enable row level security;
alter table public.leave_records enable row level security;
alter table public.hour_bank_entries enable row level security;
alter table public.attendance_summaries enable row level security;
alter table public.export_jobs enable row level security;
alter table public.audit_logs enable row level security;

create policy companies_select on public.companies for select using (public.user_has_company_access(id));
create policy companies_manage on public.companies for all using (public.user_has_role('owner')) with check (public.user_has_role('owner'));

create policy establishments_access on public.establishments for select using (public.user_has_company_access(company_id));
create policy establishments_manage on public.establishments for all using (public.user_has_company_access(company_id) and (public.user_has_role('owner') or public.user_has_role('admin'))) with check (public.user_has_company_access(company_id));

create policy departments_access on public.departments for select using (public.user_has_establishment_access(establishment_id));
create policy departments_manage on public.departments for all using (public.user_has_establishment_access(establishment_id) and (public.user_has_role('owner') or public.user_has_role('admin') or public.user_has_role('hr'))) with check (public.user_has_establishment_access(establishment_id));

create policy employees_access on public.employees for select using (public.user_has_establishment_access(establishment_id));
create policy employees_manage on public.employees for all using (public.user_has_establishment_access(establishment_id) and (public.user_has_role('owner') or public.user_has_role('admin') or public.user_has_role('hr'))) with check (public.user_has_establishment_access(establishment_id));

create policy user_roles_self_or_admin on public.user_roles for select using (user_id = auth.uid() or public.user_has_company_access(company_id));
create policy user_roles_admin on public.user_roles for all using (public.user_has_role('owner') or public.user_has_role('admin')) with check (public.user_has_role('owner') or public.user_has_role('admin'));

create policy schedules_access on public.work_schedules for select using (public.user_has_establishment_access(establishment_id));
create policy schedules_manage on public.work_schedules for all using (public.user_has_establishment_access(establishment_id) and (public.user_has_role('owner') or public.user_has_role('admin') or public.user_has_role('hr'))) with check (public.user_has_establishment_access(establishment_id));
create policy assignments_access on public.schedule_assignments for select using (exists (select 1 from public.employees e where e.id = employee_id and public.user_has_establishment_access(e.establishment_id)));
create policy devices_access on public.devices for select using (public.user_has_establishment_access(establishment_id));
create policy devices_manage on public.devices for all using (public.user_has_establishment_access(establishment_id) and (public.user_has_role('owner') or public.user_has_role('admin'))) with check (public.user_has_establishment_access(establishment_id));

create policy rep_events_access on public.rep_events for select using (public.user_has_establishment_access(establishment_id));
create policy rep_events_insert on public.rep_events for insert with check (public.user_has_establishment_access(establishment_id));
create policy time_punches_access on public.time_punches for select using (public.user_has_establishment_access(establishment_id));
create policy punch_receipts_access on public.punch_receipts for select using (exists (select 1 from public.time_punches p where p.id = time_punch_id and public.user_has_establishment_access(p.establishment_id)));

create policy adjustment_requests_access on public.adjustment_requests for select using (public.user_has_establishment_access(establishment_id));
create policy adjustment_requests_insert on public.adjustment_requests for insert with check (public.user_has_establishment_access(establishment_id) and requested_by = auth.uid());
create policy adjustment_requests_review on public.adjustment_requests for update using (public.user_has_establishment_access(establishment_id) and (public.user_has_role('owner') or public.user_has_role('admin') or public.user_has_role('hr')));
create policy attendance_adjustments_access on public.attendance_adjustments for select using (public.user_has_establishment_access(establishment_id));
create policy attendance_adjustments_insert on public.attendance_adjustments for insert with check (public.user_has_establishment_access(establishment_id) and applied_by = auth.uid());
create policy leave_records_access on public.leave_records for select using (public.user_has_establishment_access(establishment_id));
create policy hour_bank_access on public.hour_bank_entries for select using (public.user_has_establishment_access(establishment_id));
create policy summary_access on public.attendance_summaries for select using (public.user_has_establishment_access(establishment_id));
create policy exports_access on public.export_jobs for select using (public.user_has_establishment_access(establishment_id));
create policy exports_insert on public.export_jobs for insert with check (public.user_has_establishment_access(establishment_id) and requested_by = auth.uid());
create policy audit_access on public.audit_logs for select using (public.user_has_establishment_access(establishment_id) or public.user_has_company_access(company_id));

-- O append-only deve ser reforçado também por grants no papel de aplicação e por revisão operacional.
revoke update, delete on public.rep_events from authenticated;
revoke update, delete on public.time_punches from authenticated;
