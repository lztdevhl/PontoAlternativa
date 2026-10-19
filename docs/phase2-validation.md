# Fase 2.5 — Validação e Hardening

Data da validação: 18/10/2026  
Projeto: Alternativa Ponto  
Escopo: somente ambiente local; nenhuma conexão, migration ou alteração remota foi executada.

## 1. Ambiente testado

| Item | Resultado |
|---|---|
| Sistema operacional | Windows 11 Home Single Language, build 26300 |
| Node.js | v24.21.0 |
| npm | 11.19.0 |
| Supabase CLI | 2.121.0 disponível pelo cache do `npx --no-install` |
| Docker Desktop | Não instalado/disponível no PATH |
| Postgres local Supabase | Indisponível na porta 54322 |

O Docker Desktop não foi instalado automaticamente. O Supabase CLI exige Docker Desktop ou Podman para subir o banco local.

## 2. Resultado dos comandos

### Supabase local

| Comando | Resultado |
|---|---|
| `npx --no-install supabase --version` | PASSOU — 2.121.0 |
| `npx --no-install supabase start` | BLOQUEADO — Docker/Podman não encontrado |
| `npx --no-install supabase db reset --local` | BLOQUEADO — serviço local indisponível |
| `npx --no-install supabase test db` | BLOQUEADO — conexão recusada em `127.0.0.1:54322` |
| `npx --no-install supabase db lint --local` | BLOQUEADO — conexão recusada em `127.0.0.1:54322` |
| `npm run supabase:validate` | BLOQUEADO no `db reset --local`; o script agora usa `npx --no-install` e não instala ferramentas implicitamente |

As migrations não foram aplicadas nem localmente, porque o runtime necessário não está disponível. Nenhum comando remoto (`db push`, `link`, `reset --linked` ou equivalente) foi executado.

### Aplicação

| Comando | Resultado |
|---|---|
| `npm run typecheck` | PASSOU |
| `npm test` | PASSOU — 1 arquivo, 3 testes |
| `npm run lint` | PASSOU |
| `npm run build` | PASSOU — Next.js 16.4.1/Turbopack |
| `npm install --package-lock-only --ignore-scripts --dry-run` | PASSOU |

O build em Next 16 reporta apenas a depreciação da convenção `middleware`; a migração para `proxy` fica pendente para uma alteração isolada.

## 3. Testes de autorização

`supabase/tests/phase2_rls.sql` contém 30 asserts: os 18 testes originais e 12 testes adicionais para:

- isolamento entre empresas e colegas da mesma equipe;
- tentativa de transferência de estabelecimento por usuário comum;
- acesso anônimo a empresas e eventos;
- alteração de eventos e marcações por usuário comum;
- transferência indevida de vínculo entre empresas;
- sobreposição de vínculos históricos;
- matrícula duplicada;
- grants do RPC de cadastro;
- `SECURITY DEFINER` com `search_path=public`.

Status: **NÃO EXECUTADOS**. A ausência de Docker/Postgres impede declarar qualquer teste pgTAP aprovado, inclusive os 18 originais.

A inspeção estática confirmou que as funções `SECURITY DEFINER` declaradas pelas migrations usam `set search_path = public`. O RPC `create_employee_with_assignment` teve `EXECUTE` revogado de `public`, `anon` e `service_role`, mantendo-o somente para `authenticated`. Isso não transforma `service_role` ou o proprietário do banco em um papel protegido por RLS: esses papéis podem ignorar RLS, e a validação efetiva ainda precisa ocorrer no banco local.

## 4. Correções efetuadas

1. Criada a migration incremental `20261018230000_phase2_hardening.sql`.
2. Adicionada validação para impedir vínculo de funcionário com outra empresa, preservando transferências históricas entre estabelecimentos da mesma empresa.
3. Restringido o `EXECUTE` do RPC de cadastro.
4. Ampliado `supabase/tests/phase2_rls.sql` de 18 para 30 asserts.
5. Atualizados `next` e `eslint-config-next` para `16.4.1`, versão corrigida indicada no comunicado oficial de 14/10/2026.
6. Migrado `eslint.config.mjs` para os exports flat de `eslint-config-next@16.4.1`.
7. Atualizado `supabase:validate` para `npx --no-install`, evitando instalação silenciosa de CLI.
8. O Next 16 atualizou `tsconfig.json` com `jsx: react-jsx` e os tipos de desenvolvimento do Next.

## 5. Dependências e vulnerabilidades

Versões finais relevantes:

- Next.js: `16.4.1`;
- React/React DOM: `19.3.1` resolvidos pelo lockfile;
- `eslint-config-next`: `16.4.1`;
- Vitest: `3.2.7`;
- Tailwind CSS: `3.4.19`.

### Produção

`npm audit --omit=dev --json`:

```text
0 info, 0 low, 0 moderate, 0 high, 0 critical
```

O upgrade para Next 16.4.1 removeu o caminho produtivo `next -> postcss@8.4.31`. A versão 16.4.1 usa `postcss@8.5.23`.

### Todas as dependências

`npm audit --json`:

```text
3 moderate, 7 high, 2 critical, total 12
```

As vulnerabilidades restantes são de desenvolvimento/transitivas:

- `vitest@3.2.7` → `tinypool@1.1.1` — GHSA-5gmw-xhrv-c9v3 e GHSA-85c8-ppgw-ccpr, críticas; correção sugerida: Vitest 5.0.5.
- `vitest@3.2.7` → `@vitest/mocker@3.2.7` — GHSA-82fw-gwwq-j7x9, moderada; correção sugerida: Vitest 5.0.5.
- `tailwindcss@3.4.19` → `braces`, `chokidar`, `fast-glob`, `micromatch`, `postcss-nested` e `postcss-selector-parser` — incluindo GHSA-vfj7-8cjw-p6xm e GHSA-rj75-hqrm-r3gf; correção sugerida: Tailwind 4.3.3.
- `eslint-config-next@16.4.1` → `@next/eslint-plugin-next`/`fast-glob` — o audit oferece apenas uma resolução incompatível com a linha atual, portanto não foi aplicada.

Não foi usado `npm audit fix --force`. As atualizações para Vitest 5 e Tailwind 4 foram deixadas para uma tarefa própria, pois são majors com potencial de alteração de configuração e comportamento.

O comunicado oficial do Next.js de 14/10/2026 recomenda `15.5.28` para a linha 15 e `16.4.1` para a linha 16, corrigindo duas falhas críticas e uma alta. A linha 16.4.1 foi adotada nesta validação: <https://nextjs.org/blog/nextjs-security-update-october-14-2026>.

## 6. Comandos para configurar o Supabase dev

Executar manualmente, após instalar e iniciar o Docker Desktop:

```powershell
# verificar o Docker Desktop em um terminal novo
docker version

# verificar/obter o CLI de forma consciente
npx supabase --version

# somente banco local
npx supabase start
npx supabase db reset --local
npx supabase test db
npx supabase db lint --local

# validação do projeto
npm run supabase:validate
```

Referências oficiais: [fluxo local do Supabase](https://supabase.com/docs/guides/local-development/cli-workflows) e [testes/lint do banco](https://supabase.com/docs/guides/local-development/cli/testing-and-linting).

Não executar `supabase db push`, `supabase link`, `supabase db reset --linked` ou qualquer comando remoto sem aprovação explícita.

## 7. Avaliação de riscos e pendências

- **Bloqueador:** migrations, pgTAP e `db lint` não foram executados por falta de Docker/Postgres local.
- **Bloqueador:** os 18 testes originais e os 12 adicionais não podem ser declarados aprovados sem execução.
- O fluxo completo de transferência de funcionário ainda precisa ser implementado como operação administrativa transacional; a migration atual apenas impede vínculos entre empresas e preserva histórico.
- Permanecem vulnerabilidades críticas/altas somente no conjunto de desenvolvimento; devem ser tratadas antes de abrir o pipeline de testes para código não confiável.
- A convenção `middleware` está depreciada no Next 16; migrar para `proxy` antes de avançar a superfície de autenticação.
- RLS não deve ser tratado como controle contra `service_role`, proprietário do banco ou administrador; revisão operacional de grants e acesso ao projeto Supabase continua necessária.
- O projeto ainda não declara conformidade legal, nem implementa REP-P completo, AFD, AEJ ou assinaturas.

## 8. Status

# BLOQUEADO

O código da aplicação e o audit de produção estão aprovados nesta máquina, mas a Fase 2.5 não pode ser aprovada integralmente porque o banco local não foi iniciado e nenhum teste pgTAP foi executado. A Fase 3 não deve ser iniciada até a execução local das migrations, dos 30 asserts, do `db lint` e da revisão das vulnerabilidades de desenvolvimento.
