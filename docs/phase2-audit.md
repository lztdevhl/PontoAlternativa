# Auditoria da Fase 2

## Migration da Fase 1

O arquivo `20261018210000_initial_schema.sql` foi preservado. A Fase 2 usa a migration incremental `20261018220000_phase2_security_employee_registry.sql`.

### Pontos corrigidos

- `employees` passou a ter cargo, gestor atual e status.
- `employee_assignments` preserva histórico de empresa, estabelecimento, departamento, gestor, matrícula, cargo e jornada.
- `btree_gist` + `EXCLUDE` impedem dois vínculos sobrepostos para a mesma pessoa.
- Triggers impedem vínculos entre empresas/estabelecimentos incompatíveis.
- `user_roles` exige que o estabelecimento pertença à empresa declarada.
- Funcionário vê apenas seu registro, jornadas, solicitações e marcações; gestor vê sua equipe persistida; RH/admin têm escopo administrativo.
- Nenhuma política permite que o próprio usuário insira, altere ou remova seu papel.
- Eventos REP-P, marcações e logs de auditoria recebem trigger append-only além das políticas/grants.
- Alterações de cadastro geram `audit_logs`.

### Pontos que continuam pendentes

- A migration não foi executada nesta máquina nem em projeto remoto.
- Testes pgTAP ainda precisam ser executados com Supabase CLI + Docker.
- O fluxo de alteração/transferência de vínculos históricos ainda deve ganhar uma tela e uma operação transacional própria.
- A consistência completa de `rep_events` (NSR, ARP, cadeia SHA-256 e relógio confiável) permanece na Fase 3.

## Dependências

`npm audit` encontrou 14 vulnerabilidades: 2 moderadas, 8 altas e 2 críticas no conjunto completo; no conjunto de produção, 1 moderada e 1 alta, ambas pela cadeia Next/PostCSS. `npm audit fix --dry-run` não propôs alterações compatíveis sem upgrade major.

Não foi executado `npm audit fix --force`. Os upgrades sugeridos envolvem Next 16, Tailwind 4 e Vitest 5, que exigem revisão e testes de compatibilidade.

## Critério de aprovação local

1. Instalar Supabase CLI e Docker Desktop.
2. Executar `supabase start`.
3. Executar `npm run supabase:validate`.
4. Confirmar os 18 testes pgTAP e revisar o plano antes de qualquer `supabase link` ou `supabase db push`.
