-- Alternativa Ponto | Fase 2.5
-- Restringe a resolucao de nomes das funcoes SECURITY DEFINER ao catalogo
-- implicito e aos schemas explicitamente qualificados nos corpos SQL.

alter function public.user_has_company_access(uuid)
  set search_path = '';
alter function public.user_has_establishment_access(uuid)
  set search_path = '';
alter function public.user_has_role(public.app_role)
  set search_path = '';

alter function public.validate_user_role_scope()
  set search_path = '';
alter function public.validate_employee_scope()
  set search_path = '';
alter function public.validate_employee_assignment_scope()
  set search_path = '';
alter function public.validate_schedule_assignment_scope()
  set search_path = '';
alter function public.user_has_company_role(uuid, public.app_role[])
  set search_path = '';
alter function public.user_has_establishment_role(uuid, public.app_role[])
  set search_path = '';
alter function public.current_user_employee_id()
  set search_path = '';
alter function public.user_can_view_employee(uuid)
  set search_path = '';
alter function public.user_can_manage_employee(uuid)
  set search_path = '';
alter function public.user_can_manage_establishment(uuid)
  set search_path = '';
alter function public.user_can_view_schedule(uuid)
  set search_path = '';
alter function public.prevent_immutable_mutation()
  set search_path = '';
alter function public.audit_employee_change()
  set search_path = '';
alter function public.create_employee_with_assignment(
  uuid, uuid, uuid, uuid, uuid, text, text, text, text, date
)
  set search_path = '';
alter function public.validate_employee_assignment_employee_company()
  set search_path = '';
