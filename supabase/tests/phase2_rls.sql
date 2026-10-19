-- Requer supabase db reset com supabase/seed.sql carregado.
-- Execute com: supabase test db
begin;

create extension if not exists pgtap;
select plan(30);

-- Funcionária Ana: somente seu próprio cadastro e sua empresa.
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000103', true);
select is((select count(*) from public.employees), 1::bigint, 'funcionária vê somente seu cadastro');
select is((select count(*) from public.employees where id = '50000000-0000-0000-0000-000000000004'), 0::bigint, 'funcionária não vê cadastro de outra empresa');
select is((select count(*) from public.employees where id = '50000000-0000-0000-0000-000000000003'), 0::bigint, 'funcionária não vê colega da mesma equipe');
select is((select count(*) from public.companies), 1::bigint, 'funcionária vê somente sua empresa');
select is((select count(*) from public.user_roles where user_id <> auth.uid()), 0::bigint, 'funcionária não vê papéis de outros usuários');

-- Gestor: vê a própria equipe, mas não uma equipe externa.
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000102', true);
select is((select count(*) from public.employees), 3::bigint, 'gestor vê sua equipe e seu próprio cadastro');
select is((select count(*) from public.employees where id = '50000000-0000-0000-0000-000000000004'), 0::bigint, 'gestor não vê equipe de outra empresa');

-- Usuário não pode promover a própria conta.
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000103', true);
select throws_ok(
  $$insert into public.user_roles(user_id, company_id, establishment_id, role)
    values (auth.uid(), '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'admin')$$,
  '42501', null, 'funcionária não consegue promover o próprio papel'
);
select throws_ok(
  $$update public.user_roles set role = 'admin' where user_id = auth.uid()$$,
  '42501', null, 'funcionária não consegue alterar o próprio papel'
);
select throws_ok(
  $$select public.create_employee_with_assignment(
    '20000000-0000-0000-0000-000000000001', null, null,
    '40000000-0000-0000-0000-000000000001', null,
    'A-9999', 'Tentativa não autorizada', null, 'Cargo')$$,
  '42501', null, 'cadastro de funcionário exige autorização administrativa'
);
select throws_ok(
  $$update public.employees
       set establishment_id = '20000000-0000-0000-0000-000000000002'
     where id = '50000000-0000-0000-0000-000000000002'$$,
  '42501', null, 'funcionário comum não transfere estabelecimento'
);

-- Administrador da empresa A não atravessa o limite da empresa B.
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000101', true);
select is((select count(*) from public.employees), 3::bigint, 'administrador vê funcionários da sua empresa');
select is((select count(*) from public.employees where id = '50000000-0000-0000-0000-000000000004'), 0::bigint, 'administrador não vê funcionários de outra empresa');

-- Solicitação deve ser criada pelo próprio funcionário.
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000103', true);
select throws_ok(
  $$insert into public.adjustment_requests(
    establishment_id, employee_id, requested_by, reason
  ) values (
    '20000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000003', auth.uid(), 'Tentativa cruzada'
  )$$,
  '42501', null, 'funcionária não cria solicitação para outra pessoa'
);

-- Sem autenticação, dados privados não aparecem.
set local role anon;
select set_config('request.jwt.claim.sub', '', true);
select is((select count(*) from public.employees), 0::bigint, 'usuário anônimo não vê funcionários');
select is((select count(*) from public.companies), 0::bigint, 'usuário anônimo não vê empresas');
select is((select count(*) from public.rep_events), 0::bigint, 'usuário anônimo não vê eventos');

-- As constraints impedem vínculos que cruzam empresa e estabelecimento.
set local role service_role;
select throws_ok(
  $$insert into public.employee_assignments(
    employee_id, company_id, establishment_id, registration_code, job_title, valid_from
  ) values (
    '50000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000001',
    'A-9998', 'Vínculo inválido', '2027-01-01'
  )$$,
  '23514', null, 'vínculo não pode cruzar empresa e estabelecimento'
);
select throws_ok(
  $$insert into public.employee_assignments(
    employee_id, company_id, establishment_id, registration_code, job_title, valid_from
  ) values (
    '50000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000002',
    'B-9998', 'Transferência indevida', '2027-01-01'
  )$$,
  '23514', null, 'vínculo não pode transferir funcionário entre empresas'
);
select throws_ok(
  $$insert into public.employee_assignments(
    employee_id, company_id, establishment_id, registration_code, job_title, valid_from
  ) values (
    '50000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    'A-0002', 'Vínculo sobreposto', '2027-01-01'
  )$$,
  '23P01', null, 'vínculos do mesmo funcionário não podem se sobrepor'
);
select throws_ok(
  $$insert into public.employees(
    establishment_id, registration_code, full_name, job_title
  ) values (
    '20000000-0000-0000-0000-000000000001', 'A-0002', 'Duplicado Fictício', 'Teste'
  )$$,
  '23505', null, 'matrícula duplicada é rejeitada'
);
select ok(
  has_function_privilege(
    'service_role',
    'public.create_employee_with_assignment(uuid,uuid,uuid,uuid,uuid,text,text,text,text,date)',
    'EXECUTE'
  ) = false,
  'RPC de cadastro não é executável pelo papel service_role'
);
select ok(
  has_function_privilege(
    'anon',
    'public.create_employee_with_assignment(uuid,uuid,uuid,uuid,uuid,text,text,text,text,date)',
    'EXECUTE'
  ) = false,
  'RPC de cadastro não é executável anonimamente'
);
select ok(
  (select count(*) from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosecdef
      and p.proconfig @> array['search_path=public']::text[]
      and p.proname in (
        'user_has_company_access', 'user_has_establishment_access', 'user_has_role',
        'validate_user_role_scope', 'validate_employee_scope',
        'validate_employee_assignment_scope', 'validate_schedule_assignment_scope',
        'user_has_company_role', 'user_has_establishment_role',
        'current_user_employee_id', 'user_can_view_employee',
        'user_can_manage_employee', 'user_can_manage_establishment',
        'user_can_view_schedule', 'prevent_immutable_mutation',
        'audit_employee_change', 'create_employee_with_assignment',
        'validate_employee_assignment_employee_company'
      )
  ) = 19,
  'funções SECURITY DEFINER usam search_path fixo em public'
);

-- Eventos e marcações originais são imutáveis mesmo para o papel de serviço.
insert into public.rep_events(
  id, establishment_id, employee_id, event_kind, nsr, occurred_at,
  payload, chain_hash, idempotency_key
) values (
  '70000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  '50000000-0000-0000-0000-000000000002',
  'punch', 999999, '2026-10-18T08:00:00-03:00', '{}', 'dev-chain-hash', 'dev-test-event'
);
insert into public.time_punches(
  id, rep_event_id, establishment_id, employee_id, kind, original_occurred_at, server_received_at
) values (
  '80000000-0000-0000-0000-000000000001',
  '70000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000001',
  '50000000-0000-0000-0000-000000000002',
  'in', '2026-10-18T08:00:00-03:00', '2026-10-18T08:00:02-03:00'
);
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000103', true);
select throws_ok(
  $$update public.rep_events set payload = '{"common_user":true}' where id = '70000000-0000-0000-0000-000000000001'$$,
  '42501', null, 'usuário comum não altera evento original'
);
select throws_ok(
  $$update public.time_punches set kind = 'out' where id = '80000000-0000-0000-0000-000000000001'$$,
  '42501', null, 'usuário comum não altera marcação original'
);
set local role service_role;
select throws_ok(
  $$update public.rep_events set payload = '{"changed":true}' where id = '70000000-0000-0000-0000-000000000001'$$,
  '55000', null, 'rep_event não pode ser alterado'
);
select throws_ok(
  $$delete from public.rep_events where id = '70000000-0000-0000-0000-000000000001'$$,
  '55000', null, 'rep_event não pode ser excluído'
);
select throws_ok(
  $$update public.time_punches set kind = 'out' where id = '80000000-0000-0000-0000-000000000001'$$,
  '55000', null, 'time_punch não pode ser alterado'
);
select throws_ok(
  $$delete from public.time_punches where id = '80000000-0000-0000-0000-000000000001'$$,
  '55000', null, 'time_punch não pode ser excluído'
);

select * from finish();
rollback;
