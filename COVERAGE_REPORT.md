# Coverage Report - Funcionalidade Uplink

**Data:** 24 de dezembro de 2025  
**Commit:** ea963eb

## 📊 Resumo Geral

- **Coverage Total:** 80.1% (335 de 418 linhas)
- **Testes Novos:** 19 testes adicionados
- **Testes Totais:** 185 (179 passando)

## 🎯 Novos Testes Adicionados

### ProxyPackageMetadataUseCase (10 testes)
- ✅ Encoding de pacotes com escopo (@scope/name → @scope%2fname)
- ✅ Validação de estrutura de resposta esperada
- ✅ Encoding de caracteres especiais
- ✅ Construção de URL correta para NPM Registry
- ✅ Processamento de resposta JSON

### NpmPackumentPresenter (9 testes)
- ✅ Response com status 200 e headers corretos
- ✅ Serialização de metadata como JSON
- ✅ Preservação de pacotes com escopo
- ✅ Mapeamento de erros (404 → not_found, 403 → forbidden)
- ✅ Tratamento de múltiplos status codes

## 📈 Cobertura por Módulo

### ✅ 100% Coverage
- `infrastructure/api/presenter/artifact/npm_packument_presenter.dart` - 8/8 linhas
- `domain/value_objects/external_id.dart` - 15/15 linhas
- `domain/value_objects/password.dart` - 14/14 linhas
- `domain/value_objects/username.dart` - 16/16 linhas
- `domain/exceptions/domain_exception.dart` - 13/13 linhas
- `application/usecase/api_key/list_api_keys_usecase.dart` - 7/7 linhas

### 🔄 Cobertura Parcial
- `application/usecase/auth/login_usecase.dart` - 26% (6/23 linhas)
- `application/exceptions/application_exception.dart` - 62% (5/8 linhas)
- `infrastructure/services/auth/hash_service.dart` - 0% (necessita integração)

## 🎯 Próximos Passos

1. Adicionar testes de integração com HTTP mock para ProxyPackageMetadataUseCase
2. Aumentar coverage de LoginUsecase (atualmente 26%)
3. Adicionar testes para os controllers modificados
4. Implementar testes E2E para fluxo completo de uplink

## 🚀 Highlights

- **NpmPackumentPresenter:** Cobertura completa (100%)
- **Value Objects:** Alta qualidade de testes (>90%)
- **Domain Layer:** Bem testado com coverage consistente
- **Application Layer:** 19 novos testes adicionados com sucesso
