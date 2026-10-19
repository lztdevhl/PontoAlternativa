# Arquitetura — Alternativa Ponto

## Escopo desta entrega

Esta entrega implementa somente a Fase 1: scaffold Next.js App Router, integração inicial com Supabase SSR, autenticação por e-mail e senha, proteção de rotas, autorização inicial por papel e layout base para colaborador e RH.

O banco foi descrito em uma migration versionada, mas ela não é aplicada automaticamente. O schema contém o núcleo necessário para evoluir para REP-P, PTRP, documentos, auditoria e exports.

Na Fase 2, o cadastro atual ganhou `job_title`, `manager_employee_id` e `status`. A tabela `employee_assignments` preserva cada vínculo de empresa, estabelecimento, departamento, gestor, cargo, matrícula e jornada com intervalo de validade sem sobreposição. A migration é incremental e não altera o arquivo da Fase 1.

## Módulos de domínio

- **Aplicação do colaborador:** login, meu ponto, histórico, comprovantes, solicitações, banco de horas e perfil.
- **Painel administrativo:** funcionários, jornadas, apuração, solicitações, banco, relatórios e auditoria.
- **REP-P:** eventos originais append-only, NSR por estabelecimento, idempotência, timestamp de servidor e hash encadeado.
- **PTRP:** ajustes, afastamentos, banco de horas e resumos separados dos eventos originais.
- **Documentos e assinaturas:** comprovantes PAdES e arquivos fiscais CAdES ficam planejados; não há assinatura simulada nesta fase.
- **Auditoria, monitoramento e segurança:** RLS, logs, isolamento por estabelecimento, MFA administrativo e observabilidade.

## Fluxo de autenticação e autorização

1. O Supabase Auth autentica o usuário individualmente.
2. O middleware atualiza a sessão e bloqueia as rotas protegidas sem usuário autenticado.
3. O layout da aplicação carrega o papel em `user_roles`.
4. A área `/rh` exige `owner`, `admin`, `hr` ou `auditor` no servidor.
5. O banco repete o isolamento por empresa/estabelecimento com RLS; a UI nunca é a única camada de autorização.

Funções `SECURITY DEFINER` com `search_path` fixo calculam acesso usando apenas `user_roles`, vínculos persistidos e relações no banco. Claims ou metadados editáveis do usuário não são usados para conceder papéis.

## Integridade dos registros

`rep_events` e `time_punches` não recebem políticas de alteração ou exclusão pela aplicação. Um tratamento deve criar entidades próprias (`adjustment_requests` e `attendance_adjustments`) e apontar para a marcação original. O cálculo do NSR e do hash deve ocorrer em transação no serviço REP-P antes da habilitação produtiva.

Na Fase 2, triggers também rejeitam `UPDATE` e `DELETE` de eventos, marcações e logs de auditoria, inclusive quando a operação passa pelo papel de serviço. O cadastro de funcionários gera um `audit_log` append-only.

## Fases incrementais, dependências e aceite

### Fase 1 — fundação (entregue)

Dependências: projeto Supabase e variáveis de ambiente.

Aceite: `npm run typecheck`, `npm test` e `npm run build` passam; login e logout usam Supabase Auth; rotas protegidas redirecionam; área `/rh` valida papel no servidor; migration e documentação estão versionadas.

### Fase 2 — cadastro e operação inicial (entregue)

Dependências: aprovação do schema, seed de ambiente de desenvolvimento, definição dos papéis e MFA administrativo.

Aceite: empresas, estabelecimentos, colaboradores, departamentos, jornadas e dispositivos administráveis; políticas RLS e constraints cobertas por testes pgTAP com usuários fictícios; nenhuma migration remota aplicada por esta entrega.

### Fase 3 — REP-P e marcações online

Dependências: especificação técnica revisada, definição de ARP/NSR, relógio confiável, idempotência e validação de cadeia SHA-256.

Aceite: marcação online gera evento original imutável, comprovante pendente de assinatura real, replay idempotente e testes de concorrência por estabelecimento.

### Fase 4 — PTRP e tratamento

Dependências: regras de jornada aprovadas pelo negócio/jurídico.

Aceite: ajustes e apuração são separados do original, com trilha de auditoria, banco de horas e espelho revisável.

### Fase 5 — documentos e exports

Dependências: certificados ICP-Brasil, política de custódia, PAdES/CAdES e validação técnica externa.

Aceite: AFD, AEJ, espelho e comprovantes são gerados e assinados por integração real; itens sem certificado permanecem explicitamente pendentes.

### Fase 6 — produção e operação

Dependências: revisão jurídica, segurança, LGPD, monitoramento, backup/restauração e aprovação formal.

Aceite: checklist operacional e de segurança aprovado, sem marcação offline oficial antes da validação integral de integridade e sincronização.
