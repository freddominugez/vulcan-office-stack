# desktop/context/

Contexto e memoria entre sessoes Claude Code para o v1 do Vulcan Office
desktop.

## Arquivos

- **`HANDOFF-SESSION-1.md`**: memoria completa da sessao macOS que congelou
  os commits D1..D10, tentou 3 tags no CI grátis (falharam) e reencaminhou
  para o caminho A-local. Leitura obrigatoria antes de qualquer acao na
  sessao Windows.
- **`vulcanoffice-branding.py`**: config para o `ONLYOFFICE/build_tools`
  consumir via `configure.py --branding=<pasta que contem este arquivo>
  --branding-name=vulcanoffice`. O script `build-local-windows.ps1` copia
  este arquivo para `build_tools/scripts/vulcanoffice-branding.py` na hora
  do build.
- **`README.md`**: este arquivo.

## Como usar

Numa nova sessao Claude Code no Windows, primeiro turno:

```
Voce esta em vulcan-office-stack (Windows local). Leia
desktop/context/HANDOFF-SESSION-1.md integralmente antes de qualquer acao.
Depois, confirme pre-requisitos com o dono e execute
desktop/build/build-local-windows.ps1 -Version 9.3.1-vulcan.4 como
Administrator. Reporte progresso a cada milestone.
```

O Claude vai ler o handoff e assumir o contexto sem que voce precise
repetir historia.
