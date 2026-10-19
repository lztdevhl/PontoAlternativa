# Compliance e limites técnicos

Este documento registra decisões de segurança e pontos que continuam pendentes de validação técnica, jurídica ou documental. A aplicação não deve declarar conformidade legal apenas por possuir telas ou tabelas.

## Princípios implementados na base

- Autenticação individual via Supabase Auth.
- Autorização no servidor e isolamento por empresa/estabelecimento via RLS.
- Eventos REP-P e marcações originais modelados como append-only.
- Idempotência por estabelecimento e chave de evento.
- Preservação do instante original e do recebimento pelo servidor.
- Correções em entidades separadas, com justificativa e responsável.
- Storage de documentos planejado como privado, referenciado por caminho e SHA-256.
- Nenhum dado real de funcionário é usado nos testes.
- Papéis são mantidos em `user_roles` e não em campos de perfil livremente editáveis.
- Acesso de funcionário é limitado ao próprio registro e às próprias marcações; gestor depende de vínculo persistido de equipe.
- O histórico de vínculos de funcionário não é apagado nem sobrescrito.
- O seed usa exclusivamente endereços `.test`, IDs determinísticos e senhas de desenvolvimento; não é um conjunto de credenciais de produção.

## Não implementado nesta fase

- MFA administrativo efetivamente ativado no projeto Supabase.
- Cálculo transacional completo de ARP, NSR e cadeia SHA-256 conforme leiautes oficiais.
- AFD pelo REP-P, AEJ, espelho e regras completas de apuração.
- Assinaturas PAdES/CAdES com certificado ICP-Brasil.
- Validação contra autoridade certificadora, política de retenção e evidências de auditoria.
- Registro ou validação de qualquer propriedade intelectual, INPI ou requisito contratual.
- Marcação offline oficial. O botão permanece desabilitado até que integridade, nonce, fila, conflito, relógio e sincronização sejam implementados e validados.
- Testes RLS remotos ou execução de migrations em qualquer projeto Supabase; esta entrega só prepara o procedimento local.

## Controles obrigatórios antes de produção

1. Revisar a migration com segurança, jurídico e responsável pelo domínio trabalhista.
2. Configurar MFA e políticas de recuperação de conta no Supabase.
3. Definir retenção, exportação, eliminação e atendimento de direitos LGPD.
4. Testar RLS com usuários de todos os papéis, empresas e estabelecimentos.
5. Validar relógio, concorrência, NSR, hash, idempotência e recuperação de falhas.
6. Integrar certificados reais em cofre apropriado e validar PAdES/CAdES.
7. Executar migrações apenas após aprovação, backup e plano de rollback.

## Aviso de responsabilidade

O código é um scaffold técnico. Ele não constitui parecer jurídico, certificação de REP-P/PTRP, validação de conformidade com portarias ou garantia de validade de documentos assinados.
