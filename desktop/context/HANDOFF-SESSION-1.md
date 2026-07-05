# Handoff da sessao 1 para sessao Windows (A-local)

> Este arquivo e a memoria completa da sessao Claude Code que planejou e comitou
> o v1 do desktop Vulcan Office. Cole ele no primeiro turno da nova sessao no
> Windows para o Claude continuar sem re-auditar. Escrito em portugues sem
> travessao, conforme AGENTS.md do ecossistema Vulcan.

---

## 1. O que voce vai ler aqui

- Contexto integral da sessao 1 (macOS).
- Estado real do repo `freddominugez/vulcan-office-stack` na tag em curso.
- Decisao vigente: **A-local**, compilar tudo na maquina Windows local do dono.
- Roadmap de execucao para a sessao Windows.
- Guardas: o que NAO fazer, com motivo.
- Artefatos de apoio ja no repo: `build/build-local-windows.ps1` (esqueleto),
  `build/vulcanoffice-branding.py` (config para `--branding` do build_tools).

## 2. Escopo travado

- **Produto**: `Vulcan Office` (com espaco).
- **Executavel**: `VulcanOffice.exe`.
- **Pasta padrao**: `C:\Program Files\Vulcan Office\`.
- **AppUserModelID**: `com.vulcanoffice.desktop`.
- **UpgradeCode fixo**: `46396341-96D0-416A-8CB2-948502A31356`.
- **Alvo v1**: Windows x64. **Sem** Authenticode (SmartScreen bate uma vez).
  Sem file associations. Sem auto-update.
- **Compliance**: AGPL-3.0 §5(a)(c)(d), §6(d), §7(a). Source publico em
  `github.com/freddominugez/vulcan-office-stack`.

## 3. Historia da sessao 1

### 3.1. Ponto de partida

O dono pediu:
- Investigar `github.com/Euro-Office/desktop-apps`.
- Planejar instaladores desktop customizados de Vulcan Office.
- Menu Sobre com avisos legais para cumprir a licenca.
- Icones em `~/Documents/vulcanappsadmin.git/vulcanoffice/ASSETS`.
- Modificacoes publicas em `github.com/freddominugez/vulcan-office-stack`.

### 3.2. Decisoes tomadas

| # | Ponto | Decisao |
|---|---|---|
| a | Nome do produto | "Vulcan Office" (com espaco) |
| b | Bundle base | `com.vulcanoffice.desktop` (sem esquema prévio) |
| c | Downloads | `vulcanoffice.com/downloads` (unica fonte oficial) |
| d | Assinatura Authenticode | Nenhuma no v1 (SmartScreen aceitavel) |
| e | Escopo v1 | Windows x64 apenas |
| f | UpgradeCode | Gerado novo, travado em `desktop/branding/GUIDS.md` |
| g | Ambiente de build inicial | GitHub Actions windows-latest (mudou para A-local, ver 3.5) |
| h | Chave GPG | Dedicada `Vulcan Office Releases <releases@vulcanoffice.com>`, ed25519 |

### 3.3. Estrutura entregue em `desktop/`

```
desktop/
├── README.md                       # AGPL-3.0 header, escopo v1, reproducao
├── UPSTREAM.md                     # pins de commit dos upstreams
├── branding/
│   ├── branding.ps1                # override para make.ps1 upstream
│   ├── GUIDS.md                    # UpgradeCode + 12 ProductCodes por LCID
│   ├── icons/vulcanoffice.ico      # multi-size 16..256
│   ├── logos/                      # 5 SVGs (light, dark, about, about-white, loading)
│   ├── strings/
│   │   ├── pt-BR.ts                # Qt Linguist, brand rename
│   │   └── en-US.ts
│   └── about/
│       ├── about.html              # 8 blocos legais
│       ├── AGPL-3.0.txt            # texto integral
│       ├── NOTICE.txt              # copyrights preservados
│       └── THIRD-PARTY.md          # Qt, CEF, OpenSSL, fontes
├── build/
│   ├── generate-assets.py          # regenera .ico + SVGs a partir de PNG source
│   ├── apply-branding.sh           # overlay idempotente sobre checkout upstream
│   └── build-local-windows.ps1     # ADICIONADO NESTA MENSAGEM (A-local entry point)
├── keys/
│   ├── releases-pubkey.asc         # publica; commitada
│   └── README.md                   # fingerprint, revogacao, como usar
├── source-offer/
│   └── HOW-TO-GET-SOURCE.md        # oferta escrita AGPL §6(d)
└── context/
    ├── HANDOFF-SESSION-1.md        # este arquivo
    └── vulcanoffice-branding.py    # ADICIONADO NESTA MENSAGEM (config build_tools)
```

### 3.4. Commits publicos ja em `main`

```
53909df  docs(desktop-installers): prompt executavel (OFFICEWEBAPPS)
5941f96  desktop(D-fix-2): usar Inno Setup preinstalado
8879b53  desktop(D-fix-1): full 40-char SHA no fetch do upstream
a5f3986  desktop(D9): GPG release key (ed25519) + CI signing wiring
90a0db4  desktop(D8): GitHub Actions build-windows.yml
51990a7  desktop(D10): AGPL 6(d) written source offer
efeac92  desktop(D7): strings pt-BR e en-US para Qt Linguist
fb9e1f4  desktop(D6): apply-branding.sh idempotente
e824e44  desktop(D5): About dialog + legal notices (AGPL 5(a)(c)(d))
3154bd3  desktop(D4): branding.ps1 overlay for upstream make.ps1
145bdc6  desktop(D3): brand assets (multi-size .ico + 5 logo SVGs)
f6b43af  desktop(D2): fix Windows installer GUIDs
84593ba  desktop(D1): bootstrap desktop/ subtree with upstream pinning
```

O contrato original esta em outro repo local do dono
(`OFFICEWEBAPPS/specs/vulcan-office-desktop-installers/contract.md`, commit
`611b775`), fora do checkout do Windows. Considere-o congelado e integrado
neste handoff.

### 3.5. O que quebrou no CI e por que mudamos para A-local

Tres tags foram empurradas, todas falharam:

| Tag | Run | Falhou em | Motivo |
|---|---|---|---|
| `v9.3.1-vulcan.1` | 28747784213 | Clone upstream | `git fetch` exige SHA de 40 chars, passei 12 |
| `v9.3.1-vulcan.2` | 28749185104 | Install Inno Setup | Runner ja tem 6.7.1; choco recusou downgrade |
| `v9.3.1-vulcan.3` | 28751028665 | Build via make.ps1 | `make.ps1` do upstream so **empacota**, nao compila |

O D-fix-3 abriu a caixa de Pandora: descobri que `Euro-Office/desktop-apps/package/make.ps1`
espera achar um binario **JA COMPILADO** em `..\..\build_tools\out\win_64\<CompanyName>\<ProductName>\`.
Ou seja, o pipeline real e:

1. Clonar `ONLYOFFICE/build_tools` (nao existe `Euro-Office/build_tools`; usa-se o do upstream ONLYOFFICE).
2. `python3 configure.py --platform win_64 --module "desktop" --branding=<pasta> ...`
3. `python3 make.py`  (compila core, sdkjs, web-apps, desktop-apps por 4-6h em Windows).
4. So depois, `desktop-apps/package/make.ps1` empacota o `.exe`.

O runner grátis do GitHub Actions **nao cabe**: build_tools recomenda 100 GB
de disco (windows-latest tem 14 GB) e o build leva 5-8h no Windows (timeout
do job e 6h). Matematicamente inviavel no CI grátis.

### 3.6. Decisao final desta sessao 1: A-local

Alternativas apresentadas ao dono:
- **A-local**: build no Windows do dono. 4-6h. Zero custo.
- **A-hosted**: dono provisiona uma maquina Windows como self-hosted runner.
- **A-cloud-paid**: runner GH pago (`windows-latest-l`). ~US$25-40 para o v1.
- **B**: repack do binario oficial Euro-Office com nossa marca. 5-10 min por iteracao.

Dono escolheu **"recompilar o shell"** e, informado do custo real, ficou em
A. Esta sessao termina em A-local. **Iteracoes futuras** podem migrar para
A-hosted (self-hosted runner) usando os mesmos scripts.

## 4. Direcao vigente: A-local

### 4.1. O que voce (Claude na sessao Windows) vai fazer

1. **Ler este arquivo integral antes de qualquer acao.**
2. Confirmar com o dono que ele ja tem o Windows preparado (prereqs no §5).
3. Executar `desktop\build\build-local-windows.ps1` em uma sessao PowerShell
   Administrator, monitorando stdout e capturando log.
4. Se algum passo falhar, aplicar D-fix-N no script commitado antes de retentar.
   **Nao patchar `build_tools`, `core`, `sdkjs` ou `desktop-apps` upstream.**
5. Quando o `.exe` sair, testar instalacao localmente antes de publicar.
6. Publicar como release manual em `freddominugez/vulcan-office-stack` na
   tag `v9.3.1-vulcan.4` (a 1..3 ficam no historico como red X).
7. Rodar auditoria D12 apos publicar.

### 4.2. Nao mexer no `.github/workflows/build-windows.yml`

O workflow atual esta broken para A-local (foi escrito para make.ps1 puro
que nao vai funcionar). Duas opcoes:
- **Deixar como esta** e nao empurrar novas tags que disparam CI: o workflow
  simplesmente nao vai ser invocado.
- **Reescrever** o workflow para so publicar `.exe` que voce subir via CLI
  (`gh release upload`). Esta e a mudanca recomendada assim que o build local
  funcionar (D13 no roadmap).

Guardar D13 para depois do primeiro `.exe` funcional.

## 5. Pre-requisitos no Windows

O dono precisa ter:

- Windows 10 22H2 ou Windows 11 (23H2/24H2).
- 100 GB de disco livre em uma unidade que aceite paths longos (`C:\` ou `D:\`).
- 16 GB RAM (8 GB e o minimo, mas swap intenso).
- Visual Studio 2022 Community ou superior com:
  - Workload "Desktop development with C++".
  - MSVC v143 build tools.
  - Windows 10/11 SDK.
- Qt 6.7.2 msvc2019_64 (ou msvc2022_64) instalado em path curto tipo
  `C:\Qt\6.7.2\`.
- Python 3.10 ou superior no PATH.
- Perl (Strawberry) no PATH.
- Node.js 20 LTS.
- Git for Windows com Long Paths habilitado
  (`git config --global core.longpaths true`).
- PowerShell 7 (`pwsh.exe`) preferivel sobre Windows PowerShell.
- Chocolatey opcional para instalar Perl, Python, node, etc.
- Inno Setup 6 instalado em `C:\Program Files (x86)\Inno Setup 6\`.

O script `build-local-windows.ps1` **checa** todos esses prereqs antes de
comecar, e aborta com mensagem clara se algo falta.

## 6. Roadmap D-items pos-A-local

Depois do primeiro `.exe` compilado e testado, os itens a fechar sao:

- **D-fix-3 (novo)**: reescrever `apply-branding.sh` para funcionar sobre
  o layout completo do build_tools (nao so `desktop-apps`), levando os
  overlays para `core/`, `sdkjs/`, `web-apps/` conforme necessario. Alguns
  arquivos hoje mirados em `desktop-apps/win-linux/res/icons/` podem
  aparecer em outros repos (por exemplo `sdkjs/apps/documenteditor/main/`
  para o logo dentro do editor). Investigacao ao rodar o build.
- **D11-v2**: republicar tag `v9.3.1-vulcan.4` (a 1..3 ficam como falhas
  historicas; nao delete). Attach do `.exe` gerado localmente.
- **D12**: auditoria via subagent.
- **D13**: workflow CI reescrito para trabalhar so como "publicador":
  aceita `.exe` que o operador anexa via `gh release upload`. Sem
  compilar. Simplifica ate a paisagem de A-hosted amanha.

## 7. Guardas (proibicoes)

Herdados do prompt executavel entregue na sessao 1. Todos ainda valem.

- NUNCA `git push --force`.
- NUNCA alterar `UpgradeCode 46396341-96D0-416A-8CB2-948502A31356`. Imutavel.
- NUNCA regerar ProductCodes ja em `GUIDS.md`. Adicionar coluna nova para
  novas versoes preservando historico.
- NUNCA regerar a chave GPG. Fingerprint
  `13E3 C257 5E73 4C89 10D5 205A 43CE DF20 090D 3550` esta no GitHub Secret
  `GPG_RELEASE_PRIVATE_KEY` e cobre ate 2028-07-04.
- NUNCA imprimir conteudo da chave privada em qualquer log ou output.
- NUNCA deletar tags remotas ja com Release anexado. Publicar `.N+1`.
- NUNCA mudar nome do produto ("Vulcan Office" com espaco, congelado).
- NUNCA adicionar file associations (`.docx`, `.xlsx`, `.pptx`) no v1.
- NUNCA habilitar auto-update embutido no v1.
- NUNCA promover release se D12 nao aprovar.
- NUNCA patchar sources upstream (`build_tools`, `core`, `sdkjs`, `web-apps`,
  `desktop-apps` upstream). So overlay via nossos scripts.

## 8. Se travar

- **`configure.py` erra por dep faltando**: instalar dep, retentar. Se o dep
  nao existe (versao errada de compilador), abrir D-fix-N no script.
- **`make.py` compila 3h e falha em linkedit**: verificar disk space; se
  <20 GB, limpar e retentar. Se erro persistir, capturar stderr completo
  e reportar ao dono.
- **`.exe` gerado mas roda com erro na instalacao**: 90% das vezes e falta
  de dll do MSVC 2022 redistributable no target machine. Testar em VM.
- **`.exe` instala mas nao abre**: rodar em terminal para pegar mensagem;
  falta de MSVC C++ runtime ou de Visual C++ Redistributable e comum.

## 9. Como usar este handoff no Claude Code Windows

1. Clonar: `git clone https://github.com/freddominugez/vulcan-office-stack`.
2. `cd vulcan-office-stack`.
3. Abrir sessao Claude Code no diretorio.
4. Colar como primeira mensagem:

   > Voce esta em vulcan-office-stack (Windows local). Sua tarefa e compilar o
   > `.exe` do Vulcan Office v9.3.1-vulcan.4 seguindo A-local. Leia
   > `desktop/context/HANDOFF-SESSION-1.md` integralmente antes de qualquer
   > acao. Nao refaca D1..D10. Nao patche upstream. Confirme pre-requisitos
   > com o dono, depois execute `desktop/build/build-local-windows.ps1` como
   > Administrator. Reporte progresso a cada milestone (clone, configure,
   > core done, sdkjs done, web-apps done, desktop-apps done, package done).
   > Ao gerar o `.exe`, teste instalacao local e reporte hash sha256 ao dono
   > antes de publicar. Ao publicar, use tag v9.3.1-vulcan.4 com o binario
   > anexado via `gh release upload`. Rode D12 (auditor) via subagent.

5. Deixar o Claude ler o handoff e comecar.

## 10. Contatos e credenciais

- Dono do repo: `freddominugez` <frederico.dominguez@gmail.com>.
- `gh` CLI ja autenticado no laptop macOS da sessao 1 (keyring). No Windows
  sera preciso `gh auth login` na primeira vez, ou passar PAT via
  variavel de ambiente.
- Chave GPG privada: **NAO** mover para o Windows sem necessidade.
  O `.exe` local nao precisa ser assinado com GPG (a assinatura acontece
  no upload, feito manualmente com uma chamada `gpg --detach-sign` local ou
  via `gh workflow run publish.yml`).

## 11. Historico de tentativas ate agora

- v1 planejado no CI grátis => falhou (limites de disco/tempo).
- v1 replanejado para A-local => este handoff.
- Proxima acao: rodar `build-local-windows.ps1` na maquina Windows.
