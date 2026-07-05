# Objetivo do projeto (leia isto primeiro)

> Quem esta lendo: qualquer sessao Claude Code que abre este repositorio pela
> primeira vez. Este arquivo diz **o que estamos construindo** e **por que**.
> Detalhes historicos ficam em `HANDOFF-SESSION-1.md`. Detalhes tecnicos de
> como executar ficam em `COMO-USAR-NO-WINDOWS.md`.

## 1. Missao em uma frase

**Produzir um instalador Windows customizado do Vulcan Office e publica-lo
gratis para download em GitHub Releases, cumprindo integralmente a licenca
AGPL-3.0 do upstream.**

## 2. O que e o Vulcan Office (produto final)

Um **rebranding** do Euro-Office Desktop Editors (por sua vez fork do
ONLYOFFICE Desktop Editors), assinado como marca **Vulcan**, para uso pelos
usuarios do ecossistema Vulcan em computadores Windows. Nao e software
novo. E o mesmo editor de documentos, planilhas e apresentacoes, so que:

- Instala em `C:\Program Files\Vulcan Office\`
- Executavel chamado `VulcanOffice.exe`
- Icone Vulcan no menu Iniciar
- Nome "Vulcan Office" em Add/Remove Programs
- Menu **Sobre** dentro do editor mostrando avisos legais AGPL, credito ao
  upstream e link para o codigo fonte publico
- Tela inicial (splash) e sidebar com logo Vulcan

Tudo que o editor faz de verdade (editar .docx, .xlsx, .pptx, .pdf) e
identico ao Euro-Office/ONLYOFFICE. Nao ha mudanca de funcionalidade.

## 3. Onde o binario final vai ficar

**Repositorio publico**: <https://github.com/freddominugez/vulcan-office-stack>

**Pagina de releases**: <https://github.com/freddominugez/vulcan-office-stack/releases>

Cada versao vai como uma tag `v<versao-do-engine>-vulcan.<n>`, por exemplo
`v9.3.1-vulcan.4`. Anexos por release:

- `VulcanOffice-Setup-x64-<versao>.exe` (o instalavel)
- `sha256sums.txt` (hash SHA-256 do exe)
- `sha256sums.txt.asc` (assinatura GPG do arquivo acima, se disponivel)
- `releases-pubkey.asc` (chave publica GPG para verificar a assinatura)

Downloads publicos servem no dominio proprio em
`https://vulcanoffice.com/downloads/` (Caddy espelha os assets do GitHub
Release).

## 4. Por que este projeto existe

O ecossistema Vulcan opera um Nextcloud (`drive.vulcanoffice.com`) e um
DocumentServer (`office.vulcanoffice.com`) para colaboracao de documentos
online. Muitos usuarios pediram uma opcao **offline**: um editor de
documentos que abre `.docx`/`.xlsx`/`.pptx` no proprio PC, com marca
Vulcan, sem depender de conexao com a nuvem Vulcan.

Ao inves de escrever um editor do zero (impossivel), reusamos o
Euro-Office Desktop Editors (AGPL-3.0), aplicamos nossa marca e
distribuimos. A AGPL nos obriga a:

1. Manter os copyrights originais visiveis
2. Publicar o codigo fonte correspondente do binario que distribuimos
3. Deixar clara a licenca (aviso "sem garantia") ao usuario

Este repositorio (`vulcan-office-stack`) cumpre a obrigacao 2. Ele
publica **as modificacoes que aplicamos sobre o upstream** para gerar
o binario Vulcan. O upstream permanece no local original, apenas pinado
por commit SHA em `desktop/UPSTREAM.md`.

## 5. Como funciona para o usuario final Windows

O que o usuario Vulcan vai fazer:

1. Vai em `vulcanoffice.com/downloads` (ou GitHub Releases).
2. Baixa `VulcanOffice-Setup-x64-<versao>.exe`.
3. Executa. O Windows SmartScreen mostra "O Windows protegeu o seu PC"
   porque o binario nao esta assinado com certificado Authenticode (v1).
   O usuario clica em "Mais informacoes" -> "Executar assim mesmo".
4. Instalador roda, mostra as licencas AGPL, aceita, instala em
   `C:\Program Files\Vulcan Office\`.
5. Cria atalho no menu Iniciar em `Vulcan\Vulcan Office`.
6. Abre o editor, comeca a usar.
7. Se precisar desinstalar: Painel de Controle -> Programas -> desinstalar
   "Vulcan Office". Documentos do usuario ficam intocados.

## 6. O que a Vulcan **nao** entrega ao usuario no v1

Fora do escopo v1 (planejado para v2 ou versoes futuras):

- Certificado Authenticode (SmartScreen fica silencioso apos a assinatura).
- Instalador Linux (`.deb`, `.rpm`, `.AppImage`).
- Instalador macOS (`.dmg`).
- File associations: v1 nao rouba os `.docx`/`.xlsx`/`.pptx` do usuario;
  ele continua com o Office ou LibreOffice que ja tinha, e abre o Vulcan
  Office manualmente quando quiser.
- Auto-update embutido: para atualizar, baixar novo instalador manualmente.
- Traducao alem de pt-BR e en-US.
- Recompilacao do engine ONLYOFFICE core. Recompilamos apenas o **shell**
  (a casca Qt/C++ que embrulha o engine).

## 7. Arquitetura resumida do binario final

O `.exe` final e um instalador Inno Setup que contem:

```
Vulcan Office\
├── VulcanOffice.exe             ← shell Qt (recompilado por nos, marca Vulcan)
├── DocumentEditor.exe            ← engine ONLYOFFICE core (upstream unmodified)
├── editors\
│   ├── documenteditor\           ← web-apps ONLYOFFICE (upstream unmodified)
│   ├── spreadsheeteditor\
│   ├── presentationeditor\
│   └── pdfeditor\
├── Qt6*.dll, QtWebEngine*.dll    ← Qt runtime (LGPL-3.0, dinamicamente linkado)
├── icudt.dll, ...                ← bibliotecas de terceiros
├── fonts\                        ← fontes livres (SIL OFL 1.1)
├── AGPL-3.0.txt                  ← licenca completa
├── NOTICE.txt                    ← copyrights + oferta de codigo fonte
├── THIRD-PARTY.md                ← atribuicoes Qt, CEF, OpenSSL, etc
└── about.html                    ← tela Sobre do menu
```

**Recompilamos**: `VulcanOffice.exe` (shell Qt) e o `about.html`, mais os
recursos de icone/logo/texto embutidos no `.exe`.

**Empacotamos sem modificar**: engine ONLYOFFICE core (`DocumentEditor.exe`
e libs), web-apps, Qt, CEF, fontes, bibliotecas de terceiros.

## 8. Compliance AGPL-3.0 em uma paragrafo

Este repositorio (`vulcan-office-stack`) publica todas as modificacoes
Vulcan sobre o upstream. Cada release tag pina os SHAs upstream em
`desktop/UPSTREAM.md`, garantindo que qualquer pessoa possa reproduzir o
binario de qualquer versao. O menu **Sobre** dentro do `.exe` linka de
volta para este repositorio na tag correspondente. O texto integral da
AGPL vai empacotado no `.exe` como `AGPL-3.0.txt`, e o `NOTICE.txt`
preserva copyrights de Ascensio System SIA e Euro-Office. Isso satisfaz
AGPL-3.0 secoes 5(a), 5(c), 5(d) e 6(d) para distribuicao binaria offline.

## 9. Estado atual (leia `HANDOFF-SESSION-1.md` para detalhes)

- Commits D1..D10 congelados na branch `main`. Contem: overlay de branding
  (icones, logos, strings pt-BR/en-US), config do instalador Inno Setup,
  notices legais, chave GPG dedicada de release, script de branding
  determinista.
- Tres tags empurradas ao GitHub falharam no CI grátis por limites de
  disco (~14 GB no runner, precisamos ~100 GB para o build_tools).
- Sessao macOS terminou pivotando para **A-local**: compilar tudo na
  maquina Windows do dono do repo em vez de usar CI.
- Proxima acao: rodar `desktop/build/build-local-windows.ps1` no
  Windows. Duracao esperada 4 a 6 horas.
- Ao terminar, publicar como release `v9.3.1-vulcan.4`.

## 10. Mapa do repositorio

```
vulcan-office-stack/
├── LICENSE, NOTICE, README.md    # nivel top: sobre o projeto todo
├── docker-compose.yml            # infra web (drive.vulcanoffice.com), fora do desktop
├── branding/, caddy/, scripts/, systemd/, vulcanoffice-patch/
│                                 # tudo relacionado ao stack web, NAO tocar no v1 desktop
└── desktop/                      # TUDO deste projeto v1 mora aqui
    ├── README.md                 # escopo v1, AGPL header, reproducao
    ├── UPSTREAM.md               # pins de commit
    ├── branding/                 # ícones, logos, strings, About, notices
    │   ├── branding.ps1          # override para make.ps1 upstream
    │   ├── GUIDS.md              # UpgradeCode e ProductCodes por locale
    │   ├── icons/, logos/, strings/, about/
    │   └── ...
    ├── build/                    # scripts de build
    │   ├── generate-assets.py    # regenera .ico e SVGs
    │   ├── apply-branding.sh     # overlay determinista sobre upstream
    │   └── build-local-windows.ps1  # ← ENTRY POINT A-local
    ├── keys/                     # chave GPG publica + README
    ├── source-offer/             # oferta escrita AGPL §6(d)
    └── context/                  # ← VOCE ESTA AQUI
        ├── OBJETIVO.md           # ← este arquivo, leia primeiro
        ├── HANDOFF-SESSION-1.md  # memoria detalhada da sessao 1
        ├── COMO-USAR-NO-WINDOWS.md  # passo a passo pro dono
        ├── vulcanoffice-branding.py  # config para build_tools
        └── README.md             # indice
```

## 11. Guardas (o que NUNCA fazer)

- **Nao mudar** o nome do produto. "Vulcan Office" com espaco. Fim.
- **Nao mudar** o `UpgradeCode`. E `46396341-96D0-416A-8CB2-948502A31356`
  para sempre. Se mudar, upgrades futuros no Windows do usuario quebram.
- **Nao regerar** GUIDs de `desktop/branding/GUIDS.md`. Adicionar novas
  colunas para novas versoes, nao substituir as antigas.
- **Nao regerar** a chave GPG (fingerprint
  `13E3 C257 5E73 4C89 10D5 205A 43CE DF20 090D 3550`).
- **Nao imprimir** conteudo de chave privada em log ou output.
- **Nao patchar** o upstream (ONLYOFFICE/build_tools, /core, /sdkjs,
  /web-apps, Euro-Office/desktop-apps, /DesktopEditors). Toda modificacao
  Vulcan e overlay determinista via nossos scripts.
- **Nao force-push** para o remoto.
- **Nao deletar** tags remotas que ja tem Release anexado. Publicar `.N+1`.
- **Nao adicionar** file associations no v1. Nao mexer no que o usuario
  ja tem associado a `.docx`, `.xlsx`, `.pptx`.
- **Nao promover** release se auditoria D12 nao aprovar.

## 12. Primeiro turno da sessao Claude Code

Ordem de leitura obrigatoria:
1. Este arquivo (`desktop/context/OBJETIVO.md`) - o que e por que.
2. `desktop/context/HANDOFF-SESSION-1.md` - o que ja foi feito e por que.
3. `desktop/context/COMO-USAR-NO-WINDOWS.md` - como executar do zero.
4. Guardas do §11 acima.

So depois disso, agir.
