-- Alternativa Ponto | Fase 2
-- Migration incremental. Não aplicar remotamente sem aprovação explícita.

create extension if not exists btree_gist;

create type public.employee_status as enum ('active', 'inactive', 'on_leave');

alter table public.employees
  add column if not exists job_title text,
  add column if not exists manager_employee_id uuid references public.employees(id) on delete restrict,
  add column if not exists status public.employee_status not null default 'active';

alter table public.employees
  drop constraint if exists employees_no_self_manager;

alter table public.employees
  add constraint employees_no_self_manager check (manager_employee_id is null or manager_employee_id <> id);

-- Histórico de lotações, gestores, cargos e jornadas. Nunca sobrescreve um vínculo anterior.
create table public.employee_assignments (
  id uuid primary key default gen_random_uuid(),
  employee_id uuid not null references public.employees(id) on delete restrict,
  company_id uuid not null references public.companies(id) on delete restrict,
  establishment_id uuid not null references public.establishments(id) on delete restrict,
  department_id uuid references public.departments(id) on delete restrict,
  manager_employee_id uuid references public.employees(id) on delete restrict,
  work_schedule_id uuid references public.work_schedules(id) on delete restrict,
  registration_code text not null,
  job_title text not null,
  status public.employee_status not null default 'active',
  valid_from date not null,
  valid_to date,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  valid_range daterange generated always as (
    daterange(valid_from, case when valid_to is null then null else valid_to + 1 end, '[)')
  ) stored,
  check (valid_to is null or valid_to >= valid_from),
  check (manager_employee_id is null or manager_employee_id <> employee_id),
  unique (employee_id, valid_from),
  exclude using gist (employee_id with =, valid_range with &&)
);

create index employee_assignments_establishment_idx on public.employee_assignments(establishment_id);
create index employee_assignments_manager_idx on public.employee_assignments(manager_employee_id);
create index employee_assignments_schedule_idx on public.employee_assignments(work_schedule_id);

create or replace function public.validate_user_role_scope()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  establishment_company_id uuid;
begin
  if new.establishment_id is not null then
    select company_id into establishment_company_id
      from public.establishments where id = new.establishment_id;
    if establishment_company_id is null or establishment_company_id <> new.company_id then
      raise exception 'user role establishment does not belong to company' using errcode = '23514';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists user_roles_validate_scope on public.user_roles;
create trigger user_roles_validate_scope
  before insert or update on public.user_roles
  for each row execute function public.validate_user_role_scope();

create or replace function public.validate_employee_scope()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  manager_establishment_id uuid;
  department_establishment_id uuid;
begin
  if new.department_id is not null then
    select establishment_id into department_establishment_id
      from public.departments where id = new.department_id;
    if department_establishment_id is null or department_establishment_id <> new.establishment_id then
      raise exception 'employee department does not belong to establishment' using errcode = '23514';
    end if;
  end if;

  if new.manager_employee_id is not null then
    select establishment_id into manager_establishment_id
      from public.employees where id = new.manager_employee_id;
    if manager_establishment_id is null or manager_establishment_id <> new.establishment_id then
      raise exception 'employee manager does not belong to establishment' using errcode = '23514';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists employees_validate_scope on public.employees;
create trigger employees_validate_scope
  before insert or update on public.employees
  for each row execute function public.validate_employee_scope();

create or replace function public.validate_employee_assignment_scope()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  establishment_company_id uuid;
  department_establishment_id uuid;
  schedule_establishment_id uuid;
  manager_establishment_id uuid;
begin
  select company_id into establishment_company_id
    from public.establishments where id = new.establishment_id;
  if establishment_company_id is null or establishment_company_id <> new.company_id then
    raise exception 'employee assignment establishment does not belong to company' using errcode = '23514';
  end if;

  if new.department_id is not null then
    select establishment_id into department_establishment_id
      from public.departments where id = new.department_id;
    if department_establishment_id is null or department_establishment_id <> new.establishment_id then
      raise exception 'employee assignment department does not belong to establishment' using errcode = '23514';
    end if;
  end if;

  if new.work_schedule_id is not null then
    select establishment_id into schedule_establishment_id
      from public.work_schedules where id = new.work_schedule_id;
    if schedule_establishment_id is null or schedule_establishment_id <> new.establishment_id then
      raise exception 'employee assignment schedule does not belong to establishment' using errcode = '23514';
    end if;
  end if;

  if new.manager_employee_id is not null then
    select establishment_id into manager_establishment_id
      from public.employees where id = new.manager_employee_id;
    if manager_establishment_id is null or manager_establishment_id <> new.establishment_id then
      raise exception 'employee assignment manager does not belong to establishment' using errcode = '23514';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists employee_assignments_validate_scope on public.employee_assignments;
create trigger employee_assignments_validate_scope
  before insert or update on public.employee_assignments
  for each row execute function public.validate_employee_assignment_scope();

create or replace function public.validate_schedule_assignment_scope()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  employee_establishment_id uuid;
  schedule_establishment_id uuid;
begin
  select establishment_id into employee_establishment_id
    from public.employees where id = new.employee_id;
  select establishment_id into schedule_establishment_id
    from public.work_schedules where id = new.work_schedule_id;
  if employee_establishment_id is null or schedule_establishment_id is null or employee_establishment_id <> schedule_establishment_id then
    raise exception 'schedule assignment crosses establishments' using errcode = '23514';
  end if;
  return new;
end;
$$;

drop trigger if exists schedule_assignments_validate_scope on public.schedule_assignments;
create trigger schedule_assignments_validate_scope
  before insert or update on public.schedule_assignments
  for each row execute function public.validate_schedule_assignment_scope();

create or replace function public.user_has_company_role(
  target_company_id uuid,
  target_roles public.app_role[]
)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.user_roles
    where user_id = auth.uid()
      and company_id = target_company_id
      and role = any(target_roles)
  );
$$;

create or replace function public.user_has_establishment_role(
  target_establishment_id uuid,
  target_roles public.app_role[]
)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.user_roles ur
    join public.establishments e on e.company_id = ur.company_id
    where ur.user_id = auth.uid()
      and e.id = target_establishment_id
      and ur.role = any(target_roles)
      and (ur.establishment_id is null or ur.establishment_id = target_establishment_id)
  );
$$;

create or replace function public.current_user_employee_id()
returns uuid language sql stable security definer set search_path = public as $$
  select id from public.employees
  where user_id = auth.uid() and status = 'active'
  limit 1;
$$;

create or replace function public.user_can_view_employee(target_employee_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.employees e
    where e.id = target_employee_id
      and (
        e.user_id = auth.uid()
        or public.user_has_establishment_role(e.establishment_id, array['owner', 'admin', 'hr', 'auditor']::public.app_role[])
        or exists (
          select 1
          from public.employee_assignments a
          where a.employee_id = e.id
            and a.manager_employee_id = public.current_user_employee_id()
            and a.status = 'active'
            and a.valid_from <= current_date
            and (a.valid_to is null or a.valid_to >= current_date)
            and public.user_has_establishment_role(a.establishment_id, array['manager']::public.app_role[])
        )
      )
  );
$$;

create or replace function public.user_can_manage_employee(target_employee_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.employees e
    where e.id = target_employee_id
      and public.user_has_establishment_role(e.establishment_id, array['owner', 'admin', 'hr']::public.app_role[])
  );
$$;

create or replace function public.user_can_manage_establishment(target_establishment_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.user_has_establishment_role(target_establishment_id, array['owner', 'admin', 'hr']::public.app_role[]);
$$;

create or replace function public.user_can_view_schedule(target_schedule_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.work_schedules ws
    where ws.id = target_schedule_id
      and (
        public.user_has_establishment_role(ws.establishment_id, array['owner', 'admin', 'hr', 'manager', 'auditor']::public.app_role[])
        or exists (
          select 1 from public.employee_assignments a
          join public.employees e on e.id = a.employee_id
          where a.work_schedule_id = ws.id
            and e.user_id = auth.uid()
            and a.status = 'active'
            and a.valid_from <= current_date
            and (a.valid_to is null or a.valid_to >= current_date)
        )
      )
  );
$$;

create or replace function public.prevent_immutable_mutation()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  raise exception '% is append-only and cannot be modified', tg_table_name using errcode = '55000';
end;
$$;

drop trigger if exists rep_events_immutable on public.rep_events;
create trigger rep_events_immutable
  before update or delete on public.rep_events
  for each row execute function public.prevent_immutable_mutation();

drop trigger if exists time_punches_immutable on public.time_punches;
create trigger time_punches_immutable
  before update or delete on public.time_punches
  for each row execute function public.prevent_immutable_mutation();

drop trigger if exists audit_logs_immutable on public.audit_logs;
create trigger audit_logs_immutable
  before update or delete on public.audit_logs
  for each row execute function public.prevent_immutable_mutation();

create or replace function public.audit_employee_change()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  target_company_id uuid;
  target_establishment_id uuid;
begin
  target_establishment_id := coalesce(new.establishment_id, old.establishment_id);
  select company_id into target_company_id from public.establishments where id = target_establishment_id;
  insert into public.audit_logs(company_id, establishment_id, actor_user_id, action, entity_type, entity_id, metadata)
  values (
    target_company_id,
    target_establishment_id,
    auth.uid(),
    'employee.' || lower(tg_op),
    'employee',
    coalesce(new.id, old.id),
    jsonb_build_object('registration_code', coalesce(new.registration_code, old.registration_code), 'status', coalesce(new.status::text, old.status::text))
  );
  return new;
end;
$$;

drop trigger if exists employees_audit_change on public.employees;
create trigger employees_audit_change
  after insert or update on public.employees
  for each row execute function public.audit_employee_change();

-- The previous policies were broad establishment-level policies. Replace them atomically.
do $$
declare
  policy_row record;
begin
  for policy_row in
    select policyname, tablename
    from pg_policies
    where schemaname = 'public'
      and tablename in (
        'companies', 'establishments', 'departments', 'employees', 'user_roles',
        'work_schedules', 'schedule_assignments', 'devices', 'rep_events',
        'time_punches', 'punch_receipts', 'adjustment_requests',
        'attendance_adjustments', 'leave_records', 'hour_bank_entries',
        'attendance_summaries', 'export_jobs', 'audit_logs', 'employee_assignments'
      )
  loop
    execute format('drop policy if exists %I on public.%I', policy_row.policyname, policy_row.tablename);
  end loop;
end;
$$;

create policy companies_select on public.companies
  for select using (public.user_has_company_access(id));

create policy establishments_select on public.establishments
  for select using (
    public.user_has_establishment_role(id, array['owner', 'admin', 'hr', 'manager', 'auditor']::public.app_role[])
    or exists (select 1 from public.employees e where e.user_id = auth.uid() and e.establishment_id = establishments.id)
  );
create policy establishments_insert on public.establishments
  for insert with check (public.user_has_company_role(company_id, array['owner', 'admin']::public.app_role[]));
create policy establishments_update on public.establishments
  for update using (public.user_has_company_role(company_id, array['owner', 'admin']::public.app_role[]))
  with check (public.user_has_company_role(company_id, array['owner', 'admin']::public.app_role[]));

create policy departments_select on public.departments
  for select using (
    public.user_has_establishment_role(establishment_id, array['owner', 'admin', 'hr', 'manager', 'auditor']::public.app_role[])
    or exists (select 1 from public.employees e where e.user_id = auth.uid() and e.department_id = departments.id)
  );
create policy departments_insert on public.departments
  for insert with check (public.user_can_manage_establishment(establishment_id));
create policy departments_update on public.departments
  for update using (public.user_can_manage_establishment(establishment_id))
  with check (public.user_can_manage_establishment(establishment_id));

create policy employees_select on public.employees
  for select using (public.user_can_view_employee(id));
create policy employees_insert on public.employees
  for insert with check (public.user_has_establishment_role(establishment_id, array['owner', 'admin', 'hr']::public.app_role[]));
create policy employees_update on public.employees
  for update using (public.user_can_manage_employee(id))
  with check (public.user_has_establishment_role(establishment_id, array['owner', 'admin', 'hr']::public.app_role[]));

create policy user_roles_select on public.user_roles
  for select using (
    user_id = auth.uid()
    or public.user_has_company_role(company_id, array['owner', 'admin']::public.app_role[])
  );
create policy user_roles_insert on public.user_roles
  for insert with check (
    user_id <> auth.uid()
    and public.user_has_company_role(company_id, array['owner', 'admin']::public.app_role[])
  );
create policy user_roles_update on public.user_roles
  for update using (
    user_id <> auth.uid()
    and public.user_has_company_role(company_id, array['owner', 'admin']::public.app_role[])
  ) with check (
    user_id <> auth.uid()
    and public.user_has_company_role(company_id, array['owner', 'admin']::public.app_role[])
  );
create policy user_roles_delete on public.user_roles
  for delete using (
    user_id <> auth.uid()
    and public.user_has_company_role(company_id, array['owner', 'admin']::public.app_role[])
  );

create policy work_schedules_select on public.work_schedules
  for select using (public.user_can_view_schedule(id));
create policy work_schedules_insert on public.work_schedules
  for insert with check (public.user_can_manage_establishment(establishment_id));
create policy work_schedules_update on public.work_schedules
  for update using (public.user_can_manage_establishment(establishment_id))
  with check (public.user_can_manage_establishment(establishment_id));

create policy schedule_assignments_select on public.schedule_assignments
  for select using (public.user_can_view_employee(employee_id));
create policy schedule_assignments_insert on public.schedule_assignments
  for insert with check (
    exists (select 1 from public.employees e where e.id = employee_id and public.user_can_manage_establishment(e.establishment_id))
  );
create policy schedule_assignments_update on public.schedule_assignments
  for update using (
    exists (select 1 from public.employees e where e.id = employee_id and public.user_can_manage_establishment(e.establishment_id))
  ) with check (
    exists (select 1 from public.employees e where e.id = employee_id and public.user_can_manage_establishment(e.establishment_id))
  );

alter table public.employee_assignments enable row level security;
create policy employee_assignments_select on public.employee_assignments
  for select using (public.user_can_view_employee(employee_id));
create policy employee_assignments_insert on public.employee_assignments
  for insert with check (public.user_can_manage_establishment(establishment_id));

create policy devices_select on public.devices
  for select using (
    public.user_has_establishment_role(establishment_id, array['owner', 'admin', 'hr', 'manager', 'auditor']::public.app_role[])
    or exists (select 1 from public.employees e where e.id = devices.employee_id and e.user_id = auth.uid())
  );
create policy devices_insert on public.devices
  for insert with check (public.user_can_manage_establishment(establishment_id));
create policy devices_update on public.devices
  for update using (public.user_can_manage_establishment(establishment_id))
  with check (public.user_can_manage_establishment(establishment_id));

create policy rep_events_select on public.rep_events
  for select using (
    (employee_id is not null and public.user_can_view_employee(employee_id))
    or (employee_id is null and public.user_has_establishment_role(establishment_id, array['owner', 'admin', 'hr', 'auditor']::public.app_role[]))
  );
create policy rep_events_insert on public.rep_events
  for insert with check (
    (employee_id = public.current_user_employee_id() and public.user_has_establishment_role(establishment_id, array['employee']::public.app_role[]))
    or (employee_id is not null and public.user_has_establishment_role(establishment_id, array['owner', 'admin', 'hr']::public.app_role[]))
  );

create policy time_punches_select on public.time_punches
  for select using (public.user_can_view_employee(employee_id));
create policy time_punches_insert on public.time_punches
  for insert with check (employee_id = public.current_user_employee_id());

create policy punch_receipts_select on public.punch_receipts
  for select using (
    exists (
      select 1 from public.time_punches p
      where p.id = time_punch_id and public.user_can_view_employee(p.employee_id)
    )
  );

create policy adjustment_requests_select on public.adjustment_requests
  for select using (public.user_can_view_employee(employee_id));
create policy adjustment_requests_insert on public.adjustment_requests
  for insert with check (employee_id = public.current_user_employee_id() and requested_by = auth.uid());
create policy adjustment_requests_update on public.adjustment_requests
  for update using (
    public.user_has_establishment_role(establishment_id, array['owner', 'admin', 'hr']::public.app_role[])
    or (public.user_has_establishment_role(establishment_id, array['manager']::public.app_role[]) and public.user_can_view_employee(employee_id))
  ) with check (
    public.user_has_establishment_role(establishment_id, array['owner', 'admin', 'hr']::public.app_role[])
    or (public.user_has_establishment_role(establishment_id, array['manager']::public.app_role[]) and public.user_can_view_employee(employee_id))
  );

create policy attendance_adjustments_select on public.attendance_adjustments
  for select using (public.user_can_view_employee(employee_id));
create policy attendance_adjustments_insert on public.attendance_adjustments
  for insert with check (
    applied_by = auth.uid()
    and public.user_has_establishment_role(establishment_id, array['owner', 'admin', 'hr']::public.app_role[])
  );

create policy leave_records_select on public.leave_records
  for select using (public.user_can_view_employee(employee_id));
create policy hour_bank_entries_select on public.hour_bank_entries
  for select using (public.user_can_view_employee(employee_id));
create policy attendance_summaries_select on public.attendance_summaries
  for select using (public.user_can_view_employee(employee_id));

create policy export_jobs_select on public.export_jobs
  for select using (public.user_has_establishment_role(establishment_id, array['owner', 'admin', 'hr', 'auditor']::public.app_role[]));
create policy export_jobs_insert on public.export_jobs
  for insert with check (
    requested_by = auth.uid()
    and public.user_has_establishment_role(establishment_id, array['owner', 'admin', 'hr']::public.app_role[])
  );

create policy audit_logs_select on public.audit_logs
  for select using (
    public.user_has_establishment_role(establishment_id, array['owner', 'admin', 'hr', 'auditor']::public.app_role[])
    or (establishment_id is null and public.user_has_company_role(company_id, array['owner', 'admin', 'hr', 'auditor']::public.app_role[]))
  );

-- Provisionamento administrativo transacional para o cadastro inicial.
create or replace function public.create_employee_with_assignment(
  p_establishment_id uuid,
  p_department_id uuid,
  p_manager_employee_id uuid,
  p_work_schedule_id uuid,
  p_user_id uuid,
  p_registration_code text,
  p_full_name text,
  p_email text,
  p_job_title text,
  p_starts_on date default current_date
)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  target_company_id uuid;
  employee_id uuid;
begin
  if not public.user_can_manage_establishment(p_establishment_id) then
    raise exception 'insufficient privilege to create employee' using errcode = '42501';
  end if;
  if nullif(trim(p_registration_code), '') is null or nullif(trim(p_full_name), '') is null or nullif(trim(p_job_title), '') is null then
    raise exception 'registration code, full name and job title are required' using errcode = '22023';
  end if;

  select company_id into target_company_id from public.establishments where id = p_establishment_id;
  if p_department_id is not null and not exists (select 1 from public.departments where id = p_department_id and establishment_id = p_establishment_id) then
    raise exception 'department does not belong to establishment' using errcode = '23514';
  end if;
  if p_work_schedule_id is not null and not exists (select 1 from public.work_schedules where id = p_work_schedule_id and establishment_id = p_establishment_id) then
    raise exception 'work schedule does not belong to establishment' using errcode = '23514';
  end if;
  if p_manager_employee_id is not null and not exists (select 1 from public.employees where id = p_manager_employee_id and establishment_id = p_establishment_id) then
    raise exception 'manager does not belong to establishment' using errcode = '23514';
  end if;

  insert into public.employees(
    user_id, establishment_id, department_id, manager_employee_id, registration_code,
    full_name, email, job_title, active, status
  ) values (
    p_user_id, p_establishment_id, p_department_id, p_manager_employee_id,
    trim(p_registration_code), trim(p_full_name), nullif(trim(p_email), ''), trim(p_job_title), true, 'active'
  ) returning id into employee_id;

  insert into public.employee_assignments(
    employee_id, company_id, establishment_id, department_id, manager_employee_id,
    work_schedule_id, registration_code, job_title, status, valid_from, created_by
  ) values (
    employee_id, target_company_id, p_establishment_id, p_department_id, p_manager_employee_id,
    p_work_schedule_id, trim(p_registration_code), trim(p_job_title), 'active', p_starts_on, auth.uid()
  );

  return employee_id;
end;
$$;

revoke execute on function public.create_employee_with_assignment(uuid, uuid, uuid, uuid, uuid, text, text, text, text, date) from public;
grant execute on function public.create_employee_with_assignment(uuid, uuid, uuid, uuid, uuid, text, text, text, text, date) to authenticated;

revoke update, delete on public.rep_events from authenticated;
revoke update, delete on public.time_punches from authenticated;
revoke update, delete on public.audit_logs from authenticated;
