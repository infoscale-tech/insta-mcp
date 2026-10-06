#!/bin/sh
# Inicia o servidor. Ele usa imports relativos e lê o .env da pasta atual,
# por isso precisa ser iniciado de dentro da própria pasta.
cd "$(dirname "$0")" && exec .venv/bin/python -m src.instagram_mcp_server
