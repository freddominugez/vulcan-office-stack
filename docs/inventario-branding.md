# Inventário de branding — Euro-Office DocumentServer

> **Fase 1 (READ-ONLY) do fork Vulcan Office.** Nada foi modificado nos upstreams.
> Documento produzido para o **GATE 1**. Data: 2026-07-12.

Alvo do fork: `Euro-Office/DocumentServer` na tag estável **`v9.3.2`**
(HEAD de `main` = `0b58db7`; `VERSION` = `9.3.2`).

Clones read-only em `upstream/` (gitignored, 2,3 GB).

---

## 1. Mapa dos repositórios

O `DocumentServer` é um repo **agregador**: não tem código de editor próprio, só
build/packaging + **11 submódulos**. Todos os submódulos estão pinados em `v9.3.2`.

| Repo | Tipo | Pin | No escopo do prompt? |
|---|---|---|---|
| DocumentServer | raiz (build/packaging) | `v9.3.2` | sim |
| core | submódulo | `v9.3.2` | sim |
| core-fonts | submódulo | `v9.3.2` | sim |
| document-formats | submódulo | `v9.3.2` | sim |
| sdkjs | submódulo | `v9.3.2` | sim |
| sdkjs-forms | submódulo | `v9.3.2` | sim |
| server | submódulo | `v9.3.2` | sim |
| web-apps | submódulo | `v9.3.2` | sim |
| **document-server-integration** | submódulo | `v9.3.2` | **NÃO — mas contém marca** |
| **document-server-package** | submódulo | `v9.3.2` | **NÃO — mas contém marca** |
| dictionaries | submódulo | `v9.3.2` | não (sem marca relevante) |
| document-templates | submódulo | `v9.3.2` | não (sem marca relevante) |

> ⚠️ **Lacuna de escopo.** O prompt autoriza 8 repos, mas a marca visível também vive
> em `document-server-integration` (a welcome page e o app de exemplo — exatamente o que
> hoje brandeamos por bind-mount) e em `document-server-package` (nome do pacote .deb/.rpm,
> publisher, URLs de suporte). Sem esses dois, o rebrand fica incompleto.

---

## 2. Achado principal: **existe um mecanismo de rebranding oficial**

Este é o achado que muda a estratégia. O upstream **já suporta marcas de terceiros como
cidadãs de primeira classe** — não é preciso `sed` em massa no código-fonte.

**`build/docker-bake.hcl`** expõe:

```hcl
variable "BRANDING_DIR" { default = "." }
variable "COMPANY_NAME" { default = "Euro-Office" }
variable "PRODUCT_NAME" { default = "DocumentServer" }
target "brand-icons" { ## dummy image que não contém marca,
                       ## então a marca default é aplicada implicitamente }
```

**O contrato do `brand-icons`** (extraído dos Dockerfiles) é uma imagem `scratch` cujo
conteúdo espelha os caminhos do repo, sobreposta com `COPY` opcional:

| Dockerfile | Linha | Overlay |
|---|---|---|
| `server/.docker/server.bake.Dockerfile` | 50 | `COPY --from=brand-icons /[s]erver /server/` |
| `document-server-integration/.docker/example.bake.Dockerfile` | 29 | `COPY --from=brand-icons /[d]ocument-server-integration/.../nodejs /app/` |
| `build/.docker/packages.bake.Dockerfile` | 51 | `COPY --from=brand-icons /[d]ocument-server-package /document-server-package/` |

E o build **já reescreve a marca sozinho**:

- `example.bake.Dockerfile:31` → `sed -i "s/Euro-Office/${COMPANY_NAME}/g"`
- `server.bake.Dockerfile:66` → `ENV APP_NAME=${COMPANY_NAME}`
- `packages.bake.Dockerfile:22` → caminhos de instalação viram `/var/www/${COMPANY_NAME_LOW}/documentserver`
- `document-server-package/Makefile:5-16` → `COMPANY_NAME ?=`, `PUBLISHER_NAME ?=`, `PUBLISHER_URL ?=`, `SUPPORT_URL ?=`, `SUPPORT_MAIL ?=` (todos `?=`, ou seja, sobrescrevíveis)

**Precedente existente:** o CI (`.github/workflows/build.yml:160-165`) já constrói uma
**segunda marca** de terceiro:

```yaml
- name: nextcloud-office
  image_name: nextcloud-office-documentserver
  extra_bake_files: "./brands/nextcloud-office-brand/brand-server.hcl"
  extra_targets: "brand-icons,"
```

O repo da marca (`Euro-Office/nextcloud-office-brand`) é **privado (HTTP 404)**, então não
dá para copiá-lo — mas o contrato acima é suficiente para reconstruí-lo.

### Consequência prática

O rebrand Vulcan **não precisa** editar `core`, `sdkjs`, `sdkjs-forms`, `document-formats`
nem `core-fonts` — os cinco repos que concentram ~18k das ~26k ocorrências de marca.
Basta criar `brands/vulcan-office-brand/` + passar `COMPANY_NAME=Vulcan`.
Isso satisfaz "o rebrand DEVE ser reproduzível, não manual" **por construção**,
e sobrevive a merges do upstream sem conflito.

---

## 3. Inventário por categoria

Contagem bruta de ocorrências (case-insensitive, exclui `.git/` e `node_modules/`):

| repo | `onlyoffice` | `euro-office` | `ascensio` | total |
|---|---:|---:|---:|---:|
| DocumentServer (raiz) | 68 | 224 | 3 | 295 |
| core | 291 | 15 | 16.035 | 16.341 |
| core-fonts | 0 | 2 | 0 | 2 |
| document-formats | 2 | 1 | 1 | 4 |
| sdkjs | 179 | 14 | 1.473 | 1.666 |
| sdkjs-forms | 0 | 0 | 60 | 60 |
| server | 130 | 38 | 238 | 406 |
| web-apps | 4.555 | 71 | 1.181 | 5.807 |
| document-server-integration | 783 | 96 | 474 | 1.353 |
| document-server-package | 311 | 46 | 24 | 381 |
| **TOTAL** | **6.319** | **507** | **19.489** | **26.315** |

### COPYRIGHT — **PRESERVAR, nunca tocar** (~19.5k ocorrências, 9.909 arquivos)

Cabeçalhos `Copyright (c) Ascensio System SIA`. São a maioria absoluta do inventário.
Removê-los viola a AGPL. **Ação: nenhuma.** Adicionamos o copyright Vulcan *ao lado*,
nunca no lugar.

| repo | arquivos com header Ascensio |
|---|---:|
| core | 7.998 |
| sdkjs | 736 |
| web-apps | 587 |
| document-server-integration | 448 |
| server | 120 |
| sdkjs-forms | 20 |

### CODIGO_INTERNO — **NÃO RENOMEAR** (quebra o build / o protocolo)

Identificadores e valores de protocolo que contêm a string da marca mas **não são UI**:

| repo | arquivo | linha | string | por que não tocar |
|---|---|---|---|---|
| web-apps | `apps/common/main/lib/view/SelectFileDlg.js` | 106 | `msg.Referer == "onlyoffice"` | valor de wire do `postMessage` — renomear quebra a integração |
| web-apps | `apps/common/main/lib/view/SaveAsDlg.js` | 109 | `msg.Referer == "onlyoffice"` | idem |
| web-apps | `apps/common/main/lib/view/DocumentAccessDialog.js` | 109 | `msg.Referer == "onlyoffice"` | idem |
| server | `AdminPanel/client/package.json` | 2 | `"onlyoffice-adminpanel-client"` | nome de pacote npm interno |
| server | `AdminPanel/server/package.json` | 2 | `"onlyoffice-adminpanel-server"` | idem |

> A global `DocsAPI` e o objeto `DocEditor` **não** contêm a string da marca e permanecem
> intocados — a API pública continua compatível, como exige o invariante nº 1.

### LOGO_ASSET — 74 arquivos

Alvo do overlay `brand-icons`. Os que importam:

| repo | caminho |
|---|---|
| server | `branding/info/img/{logo.svg, logo.png, favicon.ico, icon-cross.png}` |
| server | `branding/welcome/img/{favicon.ico, icon-done.png, icon-cross.png}` |
| server | `AdminPanel/client/src/assets/{logo.svg, AppLogo.svg, AppMenuLogo.svg, dark-logo_s.svg}` |
| server | `AdminPanel/client/public/images/{favicon.ico, favicon_eo.svg}` |
| document-server-integration | `web/documentserver-example/nodejs/public/images/{logo.svg, mobile-logo.svg, favicon.ico, favicon_eo.svg, mobile-logo_eo.svg}` |
| web-apps | `apps/{documenteditor,spreadsheeteditor,presentationeditor,pdfeditor,visioeditor}/main/resources/img/favicon.ico` |

(Os `favicon.ico` em `web-apps/vendor/**` são de bibliotecas de terceiros — underscore,
backbone, requirejs. **Não tocar.**)

### STRING_UI — texto visível

`server/branding/{info,welcome}/index.html` são as páginas de marca do servidor.
No `web-apps`, a marca vem por config/build (não hard-coded em locale) — as 4.555
ocorrências de `onlyoffice` concentram-se em conteúdo de **ajuda** (`help/`) e URLs
de documentação, não em rótulos de UI:

| web-apps: onde estão as ocorrências | arquivos |
|---|---:|
| `apps/documenteditor` (majoritariamente `help/`) | 556 |
| `apps/spreadsheeteditor` | 512 |
| `apps/presentationeditor` | 338 |
| `apps/pdfeditor` | 136 |
| `apps/visioeditor` | 42 |
| `apps/common` | 11 |

### URL — links de marca

~2.500 ocorrências, dominadas por links de ajuda/marketing dentro de traduções e
metadados de plugin. Top:

| URL | ocorrências |
|---|---:|
| `https://www.onlyoffice.com/document-editor.aspx` (+ variantes /pt /fr /de /en) | ~600 |
| `https://www.onlyoffice.com/spreadsheet-editor.aspx` (+ variantes) | ~430 |
| `https://www.onlyoffice.com/presentation-editor.aspx` (+ variantes) | ~230 |
| `https://helpcenter.onlyoffice.com/**` | ~250 |
| `https://api.onlyoffice.com/docs/plugin-and-macros/**` | ~60 |

### NOME_PACOTE / CONFIG

| repo | arquivo | linha | string | ação |
|---|---|---|---|---|
| document-server-package | `Makefile` | 5 | `COMPANY_NAME ?= EURO-OFFICE` | sobrescrever via bake arg |
| document-server-package | `Makefile` | 13 | `PUBLISHER_NAME ?= Euro-Office` | sobrescrever |
| document-server-package | `Makefile` | 14 | `PUBLISHER_URL ?= http://github.com/euro-office` | → REPO_PUBLICO |
| document-server-package | `Makefile` | 15 | `SUPPORT_URL ?= http://github.com/euro-office` | → REPO_PUBLICO |
| document-server-package | `Makefile` | 16 | `SUPPORT_MAIL ?= support@euro-office.com` | → e-mail Vulcan |
| DocumentServer | `build/docker-bake.hcl` | 8-22 | `COMPANY_NAME`/`PRODUCT_NAME` | sobrescrever |
| (derivado) | — | — | `/var/www/euro-office/documentserver` → `/var/www/vulcan/...` | muda sozinho com `COMPANY_NAME_LOW` |

> ⚠️ Os bind-mounts do `docker-compose.yml` atual apontam para `/var/www/euro-office/...`.
> Num build de fonte com `COMPANY_NAME=Vulcan`, esses caminhos passam a ser
> `/var/www/vulcan/...` e **todos os mounts atuais quebram**.

---

## 4. ARM64 — risco muito menor do que se supunha

O handoff da sessão 1 registrou que o CI morreu por disco. Para o **DocumentServer**, o
quadro é outro: **`aarch64` é target de primeira classe, testado no CI do upstream.**

`.github/workflows/build.yml:138,146-148`:

```yaml
runs-on: ${{ matrix.arch == 'arm64' && 'ubuntu-24.04-arm' || 'ubuntu-latest' }}
matrix:
  arch: [amd64, arm64]
```

O build ARM roda **nativamente** em runner ARM, não sob emulação. O `AGENTS.md` do
upstream confirma: a imagem publicada é *"multi-arch (amd64/arm64)"*.

**Consequência:** não há motivo esperado para um componente C++ não compilar em ARM.
Mas esta máquina é **x86_64** — buildar ARM aqui exigiria QEMU (lentíssimo para C++ deste
porte). O build ARM deve rodar **nativamente**: no host Ampere A1, ou em runner ARM.

Disco local: **1,6 TB livres** — não é gargalo.

---

## 5. ⚠️ Risco jurídico que preciso levantar antes do GATE 1

**Não sou advogado. Isto precisa de revisão jurídica humana.**

O upstream Euro-Office **removeu a cláusula da Seção 7(b)** do ONLYOFFICE de `web-apps`,
`sdkjs`, `sdkjs-forms`, `core`, `server` — via workflow dedicado
(`.github/workflows/strip-logo-clause.yml`), que roda:

```sed
/Pursuant to Section 7(b)/,/grant you any rights under trademark law/d
/You can contact Ascensio System SIA/,/street, Riga, Latvia/d
```

com o título de PR *"chore(license): Remove non-obligatory Section 7 additions"*.

**O ponto:** a AGPL-3.0 §7 lista os termos adicionais *permitidos*, e o item **7(b)** —
*"requiring preservation of specified reasonable legal notices or author attributions"* —
**é um termo permitido**, não uma "further restriction". Só *further restrictions* podem
ser removidas livremente por quem recebe o software. A posição do Euro-Office de que a
cláusula é "non-obligatory" é **uma tese jurídica deles, não um fato pacificado** — a
removibilidade da cláusula de logo da ONLYOFFICE é genuinamente contestada.

**Ao forkar o Euro-Office, herdamos essa tese.** E há tensão direta com o critério de
aceite nº 2 do próprio prompt ("zero ocorrência visível de ONLYOFFICE na UI"): se a
cláusula 7(b) da Ascensio for válida e não-removível, suprimir a atribuição ONLYOFFICE
das *Appropriate Legal Notices* seria violação de licença.

**Mitigação padrão e defensável** (e que já está alinhada com o resto do prompt):
manter a atribuição a Ascensio/ONLYOFFICE **visível no diálogo "Sobre"** (que é
justamente o *Appropriate Legal Notices*), enquanto a marca Vulcan assume o logo do
cabeçalho e o nome do produto. Isso satisfaz 7(b) sem conflitar com o objetivo comercial.

---

## 6. Bug de conformidade AGPL já em produção (independe do fork)

O link de código-fonte exibido na UI hoje **está quebrado**:

| Link publicado | Onde | Status |
|---|---|---|
| `github.com/freddominugez/vulcanoffice` | `branding/welcome-docker.html` linhas 32, 42, 88 | **HTTP 404** |
| `github.com/freddominugez/vulcan-office-stack` | repo real | HTTP 200 |

Isto faz o critério de aceite nº 3 falhar **hoje**, em produção, e é uma falha real de
AGPL §13. Correção barata, vale fazer independentemente do caminho escolhido.

---

## 7. Recomendação para o GATE 1

1. **Ampliar o escopo** de 8 → 10 repos, incluindo `document-server-integration` e
   `document-server-package`. Sem eles o rebrand não fecha.
2. **Rebrandar pelo mecanismo oficial** (`brands/vulcan-office-brand/` + `COMPANY_NAME`),
   **não** por `sed` em massa. Zero edição em `core`/`sdkjs`/`sdkjs-forms`/`core-fonts`/
   `document-formats` → zero conflito de merge com o upstream, idempotente por construção.
3. **Buildar ARM64 nativamente** (Ampere A1 ou runner ARM), nunca sob QEMU nesta máquina x86.
4. **Decidir o item 5 (cláusula 7(b)) com revisão jurídica** antes de publicar qualquer
   binário rebrandado.
5. Corrigir o link 404 do item 6.

**PARADO NO GATE 1.** Nenhum arquivo de upstream foi modificado.
