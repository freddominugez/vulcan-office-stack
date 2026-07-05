# desktop/context/

Contexto e memoria entre sessoes Claude Code para o v1 do Vulcan Office
desktop.

## Ordem de leitura (obrigatoria numa nova sessao)

1. **`OBJETIVO.md`** - o que e por que. Le primeiro. Sempre.
2. **`HANDOFF-SESSION-1.md`** - memoria detalhada da sessao macOS que
   congelou os commits D1..D10, tentou 3 tags no CI grátis (falharam) e
   reencaminhou para A-local.
3. **`COMO-USAR-NO-WINDOWS.md`** - passo a passo para o dono do repo
   preparar a maquina Windows e abrir a sessao Claude Code local.

## Arquivos de apoio

- **`vulcanoffice-branding.py`**: config para o `ONLYOFFICE/build_tools`
  consumir via `configure.py --branding=<pasta que contem este arquivo>
  --branding-name=vulcanoffice`. O script `build-local-windows.ps1` copia
  este arquivo para `build_tools/scripts/vulcanoffice-branding.py` na hora
  do build.
- **`README.md`**: este arquivo.

## Prompt para colar no primeiro turno da sessao Windows

```
Voce esta em vulcan-office-stack (Windows local). Leia nesta ordem antes de
qualquer acao:
  1) desktop/context/OBJETIVO.md
  2) desktop/context/HANDOFF-SESSION-1.md
  3) desktop/context/COMO-USAR-NO-WINDOWS.md
Nao refaca D1..D10. Nao patche upstream. Confirme pre-requisitos com o
dono, depois execute desktop/build/build-local-windows.ps1 -Version
9.3.1-vulcan.4 como Administrator. Reporte progresso a cada milestone
(clone, configure, core done, sdkjs done, web-apps done, desktop-apps
done, package done). Ao gerar o .exe, teste instalacao local e reporte
hash sha256 ao dono antes de publicar. Ao publicar, use tag
v9.3.1-vulcan.4 com o binario anexado via gh release upload. Rode D12
(auditor) via subagent.
```
