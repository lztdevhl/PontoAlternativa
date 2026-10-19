-- Alternativa Ponto | Fase 2.5
-- Hardening incremental. Não aplicar remotamente sem aprovação explícita.

-- Um vínculo histórico pode registrar transferência entre estabelecimentos da
-- mesma empresa, mas nunca pode associar um funcionário a outra empresa.
create or replace function public.validate_employee_assignment_employee_company()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  employee_company_id uuid;
begin
  select est.company_id
    into employee_company_id
    from public.employees emp
    join public.establishments est on est.id = emp.establishment_id
   where emp.id = new.employee_id;

  if employee_company_id is null or employee_company_id <> new.company_id then
    raise exception 'employee assignment crosses companies' using errcode = '23514';
  end if;

  return new;
end;
$$;

drop trigger if exists employee_assignments_validate_employee_company
  on public.employee_assignments;
create trigger employee_assignments_validate_employee_company
  before insert or update on public.employee_assignments
  for each row execute function public.validate_employee_assignment_employee_company();

-- O RPC é a única porta de provisionamento exposta ao cliente.
revoke execute on function public.create_employee_with_assignment(
  uuid, uuid, uuid, uuid, uuid, text, text, text, text, date
) from public, anon, service_role;
grant execute on function public.create_employee_with_assignment(
  uuid, uuid, uuid, uuid, uuid, text, text, text, text, date
) to authenticated;
