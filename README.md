# Alternativa Ponto

Sistema interno de ponto eletrônico com aplicação mobile/PWA para colaboradores e painel web para RH.

## Fase 1 entregue

- Next.js App Router + TypeScript + Tailwind CSS.
- Supabase SSR preparado para Auth e sessão por cookies.
- Login, logout, proteção de rotas e autorização inicial por papel.
- Layout base para colaborador e RH.
- Migration versionada com empresas, estabelecimentos, colaboradores, jornadas, REP-P, PTRP, documentos, exports e auditoria.
- RLS e regras de imutabilidade para registros originais descritas na migration.
- Testes unitários das regras de autorização.

## Fase 2 entregue

- Migration incremental de segurança e cadastro em `supabase/migrations/20261018220000_phase2_security_employee_registry.sql`.
- Cargo, gestor, status, associação com usuário e histórico de vínculos em `employee_assignments`.
- Políticas RLS por funcionário, equipe, empresa e estabelecimento.
- Papéis protegidos contra alteração pelo próprio usuário.
- Triggers de integridade referencial, escopo entre empresa/estabelecimento, auditoria de funcionários e imutabilidade de registros originais.
- Seed exclusivamente fictício em `supabase/seed.sql` e testes SQL reais em `supabase/tests/phase2_rls.sql`.

## Rodar localmente

Requisitos: Node.js 20+ e um projeto Supabase de desenvolvimento.

```bash
npm install
copy .env.example .env.local
npm run typecheck
npm test
npm run build
npm run dev
```

Preencha `.env.local` com `NEXT_PUBLIC_SUPABASE_URL` e `NEXT_PUBLIC_SUPABASE_ANON_KEY`. Crie usuários fictícios no Supabase Auth para testar; não use dados reais de funcionários.

## Supabase dev local

O repositório inclui [supabase/config.toml](supabase/config.toml) para um projeto local/dev. A CLI do Supabase e o Docker são pré-requisitos para executar o banco local. A validação nunca aponta para um projeto remoto:

```bash
supabase start
npm run supabase:validate
```

O comando `supabase:validate` recria somente o banco local, carrega `supabase/seed.sql` e executa os testes pgTAP em `supabase/tests/phase2_rls.sql`. Não use `supabase db push` ou qualquer comando remoto sem revisão e aprovação explícitas.

Para testar a aplicação com o projeto local, use as chaves exibidas por `supabase status` em `.env.local` e mantenha as credenciais do seed restritas ao ambiente local.

## Migration

`supabase/migrations/20261018210000_initial_schema.sql` é somente um artefato versionado para revisão. Não foi aplicado por este projeto. Antes de aplicar em qualquer ambiente, revise o SQL, crie backup e obtenha aprovação explícita.

Com Supabase CLI, depois da aprovação e apontando para um projeto de desenvolvimento:

```bash
supabase db reset
```

Não execute isso em produção. A política de deploy deve incluir revisão, backup e rollback.

## Rotas atuais

- `/login` — autenticação.
- `/dashboard` — visão geral do colaborador.
- `/ponto` — scaffold de marcação; permanece desabilitado até o REP-P.
- `/historico`, `/solicitacoes`, `/perfil` — telas base.
- `/rh` — painel administrativo protegido por papel.

## Próximo passo

Revisar e aprovar a migration, configurar um projeto Supabase de desenvolvimento com MFA administrativo e executar testes RLS com usuários fictícios. Só depois iniciar a Fase 2 de cadastro e gestão de jornadas.

Consulte [docs/architecture.md](docs/architecture.md), [docs/compliance.md](docs/compliance.md) e [supabase/tests/phase2_rls.sql](supabase/tests/phase2_rls.sql) para dependências, critérios de aceite e pendências legais/técnicas.
