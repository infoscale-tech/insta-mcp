#!/bin/bash
# Instala e registra o servidor MCP do Instagram.
#
#   ./setup.sh                    instala e registra no Claude Code (.mcp.json desta pasta)
#   ./setup.sh --claude-desktop   também registra no chat do app desktop do Claude
#   ./setup.sh --codex            também registra no Codex
#   ./setup.sh --verificar        confere token, validade, permissões e conta padrão
#   ./setup.sh --contas           grava contas.md com o @ e o ID de cada Instagram
#
# Pode ser rodado de novo sem risco: não sobrescreve o .env existente.
set -euo pipefail
cd "$(dirname "$0")"
DIR="$(pwd)"
PY="$DIR/.venv/bin/python"

instalar() {
  if ! command -v uv >/dev/null 2>&1; then
    echo "ERRO: o 'uv' não está instalado."
    echo "Instale com:  curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo "Depois feche e abra o terminal e rode ./setup.sh de novo."
    exit 1
  fi

  if [ ! -x "$PY" ]; then
    echo "> Criando ambiente Python 3.12 em .venv"
    uv venv --python 3.12 .venv -q
  fi
  echo "> Instalando dependências"
  uv pip install -q --python "$PY" -r requirements-runtime.txt

  chmod +x run.sh

  if [ -f .env ]; then
    echo "> .env já existe; mantido como está"
  else
    cp env.modelo .env
    echo "> .env criado a partir de env.modelo (ainda sem token)"
  fi
  chmod 600 .env

  "$PY" - "$DIR" <<'PYEOF'
import json, sys
d = sys.argv[1]
cfg = {"mcpServers": {"instagram": {"command": f"{d}/run.sh", "args": []}}}
with open(f"{d}/.mcp.json", "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
    f.write("\n")
PYEOF
  echo "> .mcp.json criado (registro para o Claude Code nesta pasta)"
}

registrar_claude_desktop() {
  "$PY" - "$DIR" <<'PYEOF'
import json, os, sys
d = sys.argv[1]
path = os.path.expanduser("~/Library/Application Support/Claude/claude_desktop_config.json")
cfg = {}
if os.path.exists(path):
    with open(path) as f:
        cfg = json.load(f)
    with open(path + ".bak", "w") as f:
        json.dump(cfg, f, indent=2, ensure_ascii=False)
else:
    os.makedirs(os.path.dirname(path), exist_ok=True)
cfg.setdefault("mcpServers", {})["instagram"] = {"command": f"{d}/run.sh", "args": []}
with open(path, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
    f.write("\n")
print("> Registrado no app desktop do Claude (cópia anterior em claude_desktop_config.json.bak)")
print("  Feche o app por completo e abra de novo para carregar.")
PYEOF
}

registrar_codex() {
  local cfg="$HOME/.codex/config.toml"
  mkdir -p "$HOME/.codex"
  if [ -f "$cfg" ] && grep -q '^\[mcp_servers\.instagram\]' "$cfg"; then
    echo "> Codex já tem um servidor 'instagram' em $cfg; nada alterado"
    return
  fi
  [ -f "$cfg" ] && cp "$cfg" "$cfg.bak"
  {
    echo ""
    echo "[mcp_servers.instagram]"
    echo "command = \"$DIR/run.sh\""
    echo "args = []"
  } >> "$cfg"
  echo "> Registrado no Codex ($cfg)"
}

exigir_instalado() {
  if [ ! -x "$PY" ] || [ ! -f .env ]; then
    echo "ERRO: rode ./setup.sh primeiro."
    exit 1
  fi
}

case "${1:-}" in
  "")               instalar ;;
  --claude-desktop) instalar; registrar_claude_desktop ;;
  --codex)          instalar; registrar_codex ;;
  --verificar)      exigir_instalado; exec "$PY" verificar.py ;;
  --contas)         exigir_instalado; exec "$PY" verificar.py --contas ;;
  *) echo "Opção desconhecida: $1"; sed -n '2,10p' "$0"; exit 1 ;;
esac

echo
if grep -q "COLE_SEU_TOKEN_AQUI" .env; then
  echo "Falta o token: abra o .env, cole o token de 60 dias e o ID da conta,"
  echo "depois rode ./setup.sh --verificar"
else
  echo "Instalação pronta. Rode ./setup.sh --verificar para conferir o token."
fi
