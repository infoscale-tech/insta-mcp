# Instalação guiada por IA

Este arquivo é escrito para um assistente de código (Claude Code, Codex ou similar)
executar a instalação junto com o usuário. Se você é uma pessoa, peça ao seu assistente:

> Instale o MCP do Instagram deste repositório seguindo o INSTALAR.md.

O resultado final é um servidor MCP local que consulta dados orgânicos de contas
Instagram profissionais pela Graph API oficial da Meta.

## Regras para o assistente

1. **Nunca manipule o token.** Não peça para o usuário colar o token no chat, não o
   digite em campos, não o imprima e não leia o `.env` em voz alta. O usuário cola o
   token no `.env` com as próprias mãos. Para conferir o resultado, use
   `./setup.sh --verificar`, que nunca mostra o token.
2. **Senha, termos e autorização são do usuário.** Login no Facebook, aceite dos termos
   da Meta e a janela de autorização do token são feitos por ele, ou por você apenas
   com um "pode" explícito dado naquele momento.
3. **Peça só o mínimo de permissões.** Para análise, as quatro obrigatórias da etapa 3
   bastam. Publicação e DMs dão poder de escrita em todas as contas que o token
   alcança; só inclua se o usuário pedir.
4. **Pare e avise** quando um passo depender do usuário. Diga exatamente o que ele deve
   fazer e espere a confirmação.
5. Funciona em macOS e Linux. No Windows, use o WSL.

## Etapa 1: instalar (você faz sozinho)

Se o repositório ainda não foi baixado:

```bash
git clone https://github.com/infoscale-tech/insta-mcp.git ~/insta-mcp
```

Dentro da pasta do repositório:

```bash
./setup.sh
```

O script cria o ambiente Python 3.12, instala as dependências, cria o `.env` a partir de
`env.modelo` (sem sobrescrever um existente) e grava o `.mcp.json` com o caminho desta
máquina.

Se ele responder que o `uv` não está instalado, peça autorização ao usuário para rodar
`curl -LsSf https://astral.sh/uv/install.sh | sh`, depois rode `./setup.sh` de novo.

Não use `requirements.txt` nem `env.example`: ambos fazem o servidor falhar ao iniciar.

## Etapa 2: conta e app na Meta

Pré-requisitos, que você deve confirmar com o usuário:

- a conta do Instagram é Profissional (Empresa ou Criador de conteúdo);
- ela está vinculada a uma Página do Facebook;
- o usuário tem acesso de administrador a essa Página.

Criação do app, em <https://developers.facebook.com/apps> (telas conferidas em 05/10/2026):

1. **Criar aplicativo**.
2. **Detalhes do app**: nome sem "Instagram", "Facebook" ou "Meta" (por exemplo
   `Claude Dados Organicos`) e e-mail de contato. **Avançar**.
3. **Casos de uso**: filtro **Outros**, opção **Outro** no fim da lista. **Avançar**.
   Não escolha o caso de uso de Instagram em "Gerenciamento de conteúdo": ele gera
   outro tipo de token, que este servidor não aceita.
4. **Tipo de aplicativo**: **Empresa**. **Avançar**.
5. **Portfólio empresarial**: deixar sem portfólio.
6. **Criar aplicativo**. Este clique aceita os termos da Meta: é do usuário.

Com acesso ao navegador do usuário você pode preencher os passos 1 a 5. Sem acesso,
dite os passos e espere.

## Etapa 3: gerar o token

No Explorador da Graph API, <https://developers.facebook.com/tools/explorer>:

1. Em **App da Meta**, selecionar o app criado.
2. Em **Permissões**, adicionar uma por uma:

   | Permissão | Necessária? |
   | --- | --- |
   | `instagram_basic` | Sim |
   | `instagram_manage_insights` | Sim |
   | `pages_show_list` | Sim |
   | `pages_read_engagement` | Sim |
   | `business_management` | Se as Páginas estão num Gerenciador de Negócios |
   | `instagram_manage_comments` | Opcional: autor dos comentários e menções |
   | `instagram_content_publish` | Opcional: publicar. Poder de escrita |
   | `instagram_manage_messages`, `pages_messaging` | Opcional: DMs. Poder de escrita |

3. **Generate Access Token**. Abre um pop-up; o usuário confirma o perfil e marca as
   Páginas e contas do Instagram que quer consultar. O que ficar desmarcado não aparece
   depois.

## Etapa 4: estender e colar o token (o usuário faz)

O token do Explorador dura cerca de 1 hora. Peça ao usuário:

1. Copiar o token no Explorador (ícone ao lado do campo).
2. Abrir <https://developers.facebook.com/tools/debug/accesstoken/>, colar e clicar em
   **Depurar**.
3. No fim da página, clicar em **Estender token de acesso**.
4. Copiar o token **novo**, que aparece abaixo do botão.
5. Abrir o `.env` (`open -e .env` no macOS), trocar `COLE_SEU_TOKEN_AQUI` pelo token,
   sem espaço nem aspas, e salvar.

## Etapa 5: conferir e escolher a conta padrão (você faz)

```bash
./setup.sh --contas
```

Grava `contas.md` com o @ e o ID de cada Instagram que o token alcança. Mostre a lista
ao usuário, pergunte qual é a conta padrão e escreva o ID dela na linha
`INSTAGRAM_BUSINESS_ACCOUNT_ID` do `.env`. Edite só essa linha.

```bash
./setup.sh --verificar
```

| Saída | O que fazer |
| --- | --- |
| Só linhas `OK` | Pronto, siga para a etapa 6 |
| `AVISO token CURTO` | O usuário colou o token de 1 hora. Refazer a etapa 4 |
| `AVISO faltam permissões` | Refazer as etapas 3 e 4 incluindo as que faltam |
| `ERRO: a Meta recusou o token` | Token vencido ou colado com espaço, aspas ou quebra de linha |
| `FALTA` | O `.env` ainda tem um valor de exemplo |

## Etapa 6: registrar no cliente

| Cliente | Como registrar |
| --- | --- |
| Claude Code | Já feito: `.mcp.json` nesta pasta. Para usar em outro projeto, copie o arquivo para a pasta dele |
| Chat do app desktop do Claude | `./setup.sh --claude-desktop`, depois fechar e abrir o app |
| Codex | `./setup.sh --codex` |

Os registros de desktop e Codex guardam uma cópia `.bak` da configuração anterior.

ChatGPT e claude.ai no navegador não funcionam com este servidor: só aceitam conectores
remotos, e este roda no computador do usuário.

O servidor só é carregado no início da sessão. Avise o usuário para abrir uma sessão
nova na pasta que tem o `.mcp.json` e aprovar o servidor `instagram` quando perguntado.
Depois de mudar o `.env`, é preciso reconectar: `/mcp` > `instagram` > **Reconnect**.

## Etapa 7: testar na sessão nova

O servidor não cria comando de barra. O usuário pede em linguagem normal:

1. `Usando o MCP do Instagram, mostre o perfil da minha conta.`
2. `Liste meus 5 últimos posts com curtidas e comentários.`
3. `Traga os insights do meu último post.`
4. `Mostre o perfil da conta <ID de outra conta do contas.md>.`

## Como usar depois

- **Outras contas:** as consultas de perfil, posts, insights e stories aceitam
  `account_id`. Um token consulta qualquer conta listada no `contas.md`.
- **Insights de post:** não informe métricas; o servidor escolhe as que valem para Reel
  ou para feed. Pedir uma métrica que o tipo não aceita derruba a consulta inteira.
- **Tempos** (`ig_reels_avg_watch_time`, `ig_reels_video_view_total_time`) vêm em
  milissegundos.
- **Publicação** vai sempre para a conta padrão do `.env`.
- **Renovação:** o token vence em cerca de 60 dias. Refazer as etapas 3 e 4.
- **Não funciona ainda:** dados demográficos dos seguidores e busca por hashtag (exige
  revisão do app pela Meta).

## Arquivos que nunca vão para o Git

`.env` (token), `contas.md` (dados de clientes) e `.mcp.json` (caminho da máquina) já
estão no `.gitignore`. Não os adicione nem os envie a ninguém.
