-- Seed exclusivamente local/dev. Não executar em produção.
-- As credenciais abaixo são fictícias e servem apenas para testes locais.

-- Usuários de desenvolvimento:
-- admin@empresa-a.test / DevOnly-Admin!2026
-- gestor@empresa-a.test / DevOnly-Manager!2026
-- ana@empresa-a.test / DevOnly-Ana!2026
-- bruno@empresa-a.test / DevOnly-Bruno!2026
-- carla@empresa-b.test / DevOnly-Carla!2026

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'admin@empresa-a.test', crypt('DevOnly-Admin!2026', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'gestor@empresa-a.test', crypt('DevOnly-Manager!2026', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'ana@empresa-a.test', crypt('DevOnly-Ana!2026', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'bruno@empresa-a.test', crypt('DevOnly-Bruno!2026', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'carla@empresa-b.test', crypt('DevOnly-Carla!2026', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now())
on conflict (id) do nothing;

insert into auth.identities (id, user_id, provider_id, identity_data, provider, created_at, updated_at)
select gen_random_uuid(), id, id::text, jsonb_build_object('sub', id::text, 'email', email), 'email', now(), now()
from auth.users
where id in (
  '00000000-0000-0000-0000-000000000101',
  '00000000-0000-0000-0000-000000000102',
  '00000000-0000-0000-0000-000000000103',
  '00000000-0000-0000-0000-000000000104',
  '00000000-0000-0000-0000-000000000105'
)
on conflict (provider_id, provider) do nothing;

insert into public.companies (id, legal_name, trade_name, tax_id)
values
  ('10000000-0000-0000-0000-000000000001', 'Empresa Aurora Tecnologia Ltda.', 'Aurora Tech', '00.000.000/0001-01'),
  ('10000000-0000-0000-0000-000000000002', 'Empresa Horizonte Serviços Ltda.', 'Horizonte Serviços', '00.000.000/0001-02')
on conflict (id) do nothing;

insert into public.establishments (id, company_id, name, tax_id)
values
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Sede São Paulo', '00.000.000/0002-01'),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'Unidade Campinas', '00.000.000/0002-02')
on conflict (id) do nothing;

insert into public.departments (id, establishment_id, name)
values
  ('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'Operações'),
  ('30000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000001', 'Produto'),
  ('30000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000002', 'Atendimento')
on conflict (id) do nothing;

insert into public.work_schedules (id, establishment_id, name, weekly_rules, tolerance_minutes)
values
  ('40000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'Comercial 08:00–17:00', '{"monday":{"start":"08:00","end":"17:00"},"tuesday":{"start":"08:00","end":"17:00"},"wednesday":{"start":"08:00","end":"17:00"},"thursday":{"start":"08:00","end":"17:00"},"friday":{"start":"08:00","end":"17:00"}}', 10),
  ('40000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', 'Administrativo 09:00–18:00', '{"monday":{"start":"09:00","end":"18:00"},"tuesday":{"start":"09:00","end":"18:00"},"wednesday":{"start":"09:00","end":"18:00"},"thursday":{"start":"09:00","end":"18:00"},"friday":{"start":"09:00","end":"18:00"}}', 10)
on conflict (id) do nothing;

insert into public.user_roles (user_id, company_id, establishment_id, role)
values
  ('00000000-0000-0000-0000-000000000101', '10000000-0000-0000-0000-000000000001', null, 'admin'),
  ('00000000-0000-0000-0000-000000000102', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'manager'),
  ('00000000-0000-0000-0000-000000000103', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'employee'),
  ('00000000-0000-0000-0000-000000000104', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'employee'),
  ('00000000-0000-0000-0000-000000000105', '10000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', 'employee')
on conflict (user_id, company_id, establishment_id, role) do nothing;

-- O gestor também é um funcionário, para que o vínculo de gestão seja referencial.
insert into public.employees (
  id, user_id, establishment_id, department_id, registration_code, full_name, email,
  job_title, manager_employee_id, active, status
) values
  ('50000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000102', '20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'A-0001', 'Gestor de Operações (Fictício)', 'gestor@empresa-a.test', 'Gestor de Operações', null, true, 'active'),
  ('50000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000103', '20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'A-0002', 'Ana de Teste', 'ana@empresa-a.test', 'Analista de Operações', '50000000-0000-0000-0000-000000000001', true, 'active'),
  ('50000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000104', '20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002', 'A-0003', 'Bruno de Teste', 'bruno@empresa-a.test', 'Analista de Produto', '50000000-0000-0000-0000-000000000001', true, 'active'),
  ('50000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000105', '20000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000003', 'B-0001', 'Carla de Teste', 'carla@empresa-b.test', 'Analista de Atendimento', null, true, 'active')
on conflict (id) do nothing;

insert into public.employee_assignments (
  id, employee_id, company_id, establishment_id, department_id, manager_employee_id,
  work_schedule_id, registration_code, job_title, status, valid_from, created_by
) values
  ('60000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', null, '40000000-0000-0000-0000-000000000001', 'A-0001', 'Gestor de Operações', 'active', '2026-01-01', '00000000-0000-0000-0000-000000000101'),
  ('60000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', 'A-0002', 'Analista de Operações', 'active', '2026-01-01', '00000000-0000-0000-0000-000000000101'),
  ('60000000-0000-0000-0000-000000000003', '50000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', 'A-0003', 'Analista de Produto', 'active', '2026-01-01', '00000000-0000-0000-0000-000000000101'),
  ('60000000-0000-0000-0000-000000000004', '50000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000003', null, '40000000-0000-0000-0000-000000000002', 'B-0001', 'Analista de Atendimento', 'active', '2026-01-01', '00000000-0000-0000-0000-000000000101')
on conflict (id) do nothing;
