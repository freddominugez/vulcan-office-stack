# Como abrir a sessao Claude Code no Windows para o build A-local

> Leia este arquivo antes de instalar qualquer coisa. Toda a informacao esta
> aqui, na ordem em que voce vai precisar. Sem travessao no texto (norma do
> ecossistema Vulcan).

## 1. Preparar a maquina Windows

Instale **antes** de abrir o Claude Code. Ordem importa (VS 2022 primeiro
porque outros passos dependem do compilador C++ instalado por ele).

Requisitos de hardware:
- Windows 10 22H2 ou Windows 11 (23H2 ou 24H2).
- **100 GB de disco livre** no drive que voce vai usar como workspace
  (padrao do script: `C:\`; mudar com `-WorkDir D:\vulcan-build`).
- 16 GB de RAM (8 GB compila, mas com swap intenso).
- 4 cores ou mais.

Instalacoes:

1. **Visual Studio 2022 Community** (gratis).
   Baixe em https://visualstudio.microsoft.com/pt-br/vs/community/
   Na tela de instalacao, marque:
   - Workload "Desktop development with C++".
   - Componentes individuais: "MSVC v143 build tools" e "Windows 11 SDK".

2. **Chocolatey** (gerenciador de pacotes) para os demais.
   Abra PowerShell como Administrator e cole:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   [System.Net.ServicePointManager]::SecurityProtocol = 3072
   iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
   ```

3. **Ferramentas via choco**, ainda em PowerShell Administrator:
   ```powershell
   choco install strawberryperl -y
   choco install python -y
   choco install nodejs-lts -y
   choco install git -y
   choco install innosetup -y
   choco install gh -y
   choco install powershell-core -y
   ```

4. **Reinicie o PowerShell** para pegar o PATH novo.

5. **Git long paths** (necessario, senao o clone do build_tools falha):
   ```powershell
   git config --global core.longpaths true
   ```

6. **Qt 6.7.2 msvc2019_64**.
   Baixe o instalador online em https://www.qt.io/download-open-source
   Cadastro necessario. Na tela de componentes:
   - Marque **Qt 6.7.2 -> msvc2019 64-bit**
   - Marque **Qt WebEngine** e **Qt Positioning**.
   - Instale em path curto: `C:\Qt\` (o instalador cria `C:\Qt\6.7.2\`).

7. **Autenticar `gh` (GitHub CLI)** no seu usuario:
   ```powershell
   gh auth login
   ```
   Escolha HTTPS, autentique pelo browser.

## 2. Clonar o repo Vulcan

```powershell
cd $env:USERPROFILE\Documents
git clone https://github.com/freddominugez/vulcan-office-stack
cd vulcan-office-stack
```

## 3. Abrir o Claude Code na pasta

Se ainda nao tem, instale:
```powershell
winget install Anthropic.ClaudeCode
```

Abra:
```powershell
cd $env:USERPROFILE\Documents\vulcan-office-stack
claude
```

## 4. Prompt para colar no primeiro turno da sessao

Cole exatamente este bloco quando o Claude Code abrir. Ele foi escrito para
ser autocontido; a sessao Windows nao precisa saber do que rolou na sessao
macOS que criou os commits ate `27c544e`.

```
Voce esta em vulcan-office-stack (Windows local). Leia
desktop/context/HANDOFF-SESSION-1.md integralmente antes de qualquer acao.
Nao refaca D1..D10. Nao patche upstream. Confirme pre-requisitos com o
dono, depois execute desktop/build/build-local-windows.ps1 -Version
9.3.1-vulcan.4 como Administrator. Reporte progresso a cada milestone
(clone, configure, core done, sdkjs done, web-apps done, desktop-apps
done, package done). Ao gerar o .exe, teste instalacao local e reporte
hash sha256 ao dono antes de publicar. Ao publicar, use tag
v9.3.1-vulcan.4 com o binario anexado via gh release upload. Rode D12
(auditor) via subagent.
```

## 5. O que vai acontecer

1. O Claude vai ler `desktop/context/HANDOFF-SESSION-1.md` (~14 KB) e
   entender tudo que ja foi decidido.
2. Vai te perguntar se voce preparou os pre-requisitos do passo 1 acima.
   Responda "sim, tudo instalado".
3. Vai iniciar `pwsh -File desktop/build/build-local-windows.ps1 -Version 9.3.1-vulcan.4`.
4. O script vai:
   - Verificar cada dependencia (VS 2022, Qt, Perl, Python, Node, Inno, disco).
     Se algo faltar, aborta com mensagem clara.
   - Clonar `ONLYOFFICE/build_tools` em `C:\vulcan-build\build_tools\`.
   - Injetar `vulcanoffice-branding.py` no build_tools.
   - Rodar `python configure.py` (2-5 min).
   - Rodar `python make.py` (**3 a 5 horas**, compila core, sdkjs, web-apps,
     desktop-apps). Aqui voce pode ir tomar um cafe.
   - Aplicar overlay Vulcan em cima do checkout de desktop-apps do workspace.
   - Empacotar via `desktop-apps\package\make.ps1`.
   - Copiar o `.exe` final para `desktop\build\out\`.
5. Ao terminar, voce vai encontrar em `desktop\build\out\`:
   - `VulcanOffice-Setup-x64-9.3.1-vulcan.4.exe`
   - `sha256sums.txt`
   - `build-manifest.txt`
6. O Claude vai te pedir para testar a instalacao localmente.
7. Depois de aprovado, publica a release:
   ```powershell
   gh release create v9.3.1-vulcan.4 `
     --repo freddominugez/vulcan-office-stack `
     --title "Vulcan Office 9.3.1-vulcan.4 (Windows x64, unsigned)" `
     --notes-file desktop\build\out\build-manifest.txt `
     desktop\build\out\VulcanOffice-Setup-x64-9.3.1-vulcan.4.exe `
     desktop\build\out\sha256sums.txt
   ```
8. Rodar auditoria D12.

## 6. Se algo falhar

- **`configure.py` para com "qmake not found"**: cheque `-QtDir` do script;
  o padrao e `C:\Qt\6.7.2\msvc2019_64`.
- **`make.py` roda 3h e falha em linkedit**: cheque disco. Se ficar
  <20 GB, limpa `C:\vulcan-build\build_tools\out\<subrepo>\build\` e retenta.
- **`apply-branding.sh` diz "desktop-apps checkout nao encontrado"**: o
  layout do build_tools pode variar. Reportar a saida ao Claude para ele
  ajustar o `build-local-windows.ps1` como D-fix-N.
- **Falta MSVC C++ runtime na maquina de teste**: instalar
  `Microsoft Visual C++ 2015-2022 Redistributable (x64)`.

## 7. Guardas (mesmas do handoff)

- NUNCA `git push --force`.
- NUNCA alterar `UpgradeCode 46396341-96D0-416A-8CB2-948502A31356`.
- NUNCA regerar ProductCodes ja em `desktop/branding/GUIDS.md`.
- NUNCA regerar a chave GPG (fingerprint
  `13E3 C257 5E73 4C89 10D5 205A 43CE DF20 090D 3550`).
- NUNCA imprimir conteudo de chave privada em log ou output.
- NUNCA deletar tags remotas com Release anexado. Publicar `.N+1`.
- NUNCA mudar nome do produto ("Vulcan Office" com espaco).
- NUNCA adicionar file associations `.docx/.xlsx/.pptx` no v1.
- NUNCA habilitar auto-update no v1.
- NUNCA patchar `build_tools`, `core`, `sdkjs`, `web-apps` ou upstream
  `desktop-apps`. So overlay via nossos scripts.

## 8. Contato de emergencia

Se algo travar e voce precisar de decisao humana, o Claude no Windows deve
pedir ao dono do repo (`freddominugez`, frederico.dominguez@gmail.com)
antes de qualquer acao destrutiva.
