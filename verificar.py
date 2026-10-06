"""Confere a instalação sem nunca mostrar o token.

    python verificar.py            token, validade, permissões e conta padrão
    python verificar.py --contas   grava contas.md com o @ e o ID de cada Instagram
"""

import asyncio
import logging
import sys
from datetime import datetime

import structlog

# Silencia os registros de depuração, que incluem a URL com o token.
structlog.configure(
    wrapper_class=structlog.make_filtering_bound_logger(logging.WARNING)
)
logging.basicConfig(level=logging.WARNING)

from src.config import get_settings  # noqa: E402
from src.instagram_client import InstagramAPIError, InstagramClient  # noqa: E402

RECOMENDADAS = [
    "instagram_basic",
    "instagram_manage_insights",
    "pages_show_list",
    "pages_read_engagement",
]


async def verificar(client: InstagramClient) -> int:
    settings = get_settings()
    if "COLE_" in settings.instagram_access_token:
        print("FALTA: o token ainda não foi colado no .env")
        return 1

    if not await client.validate_access_token():
        print("ERRO: a Meta recusou o token (inválido, vencido ou colado com espaço/aspas)")
        return 1
    print("OK    token aceito pela Meta")

    info = (
        await client._make_request(
            "GET",
            "debug_token",
            params={"input_token": client.access_token},
            use_cache=False,
        )
    ).get("data", {})

    status = 0
    expira = info.get("expires_at")
    if expira:
        quando = datetime.fromtimestamp(expira)
        dias = (quando - datetime.now()).total_seconds() / 86400
        if dias < 2:
            print(
                f"AVISO token CURTO: vence em {quando:%d/%m/%Y %H:%M}. "
                "Estenda no Depurador de Token e cole o novo no .env"
            )
            status = 2
        else:
            print(f"OK    token vence em {quando:%d/%m/%Y} (faltam {dias:.0f} dias)")
    else:
        print("OK    token sem data de vencimento")

    escopos = info.get("scopes", [])
    faltando = [p for p in RECOMENDADAS if p not in escopos]
    print("OK    permissões:", ", ".join(sorted(escopos)))
    if faltando:
        print("AVISO faltam permissões:", ", ".join(faltando))
        status = 2

    conta = settings.instagram_business_account_id
    if not conta or "COLE_" in conta:
        print("FALTA: INSTAGRAM_BUSINESS_ACCOUNT_ID no .env (rode ./setup.sh --contas para ver os IDs)")
        return 1
    try:
        perfil = await client.get_profile_info()
        print(
            f"OK    conta padrão: @{perfil.username} "
            f"({perfil.followers_count} seguidores, {perfil.media_count} posts)"
        )
    except InstagramAPIError as e:
        print(f"ERRO: não consegui ler a conta padrão {conta}: {e}")
        return 1
    return status


async def contas(client: InstagramClient) -> int:
    paginas = []
    params = {"fields": "name,instagram_business_account{id,username}", "limit": 100}
    while True:
        data = await client._make_request(
            "GET", "me/accounts", params=dict(params), use_cache=False
        )
        paginas.extend(data.get("data", []))
        after = data.get("paging", {}).get("cursors", {}).get("after")
        if not data.get("paging", {}).get("next") or not after:
            break
        params["after"] = after

    com = sorted(
        (p for p in paginas if p.get("instagram_business_account")),
        key=lambda p: p["name"].lower(),
    )
    sem = sorted(p["name"] for p in paginas if not p.get("instagram_business_account"))

    linhas = [
        "# Contas do Instagram alcançadas pelo token",
        "",
        f"Consulta feita em {datetime.now():%d/%m/%Y}.",
        "Use o ID da coluna \"ID do Instagram\" como `account_id` nas consultas.",
        "",
        "| Página do Facebook | @ do Instagram | ID do Instagram |",
        "| --- | --- | --- |",
    ]
    for p in com:
        ig = p["instagram_business_account"]
        linhas.append(f"| {p['name']} | {ig.get('username', '')} | {ig['id']} |")
    if sem:
        linhas += ["", "## Páginas sem Instagram profissional vinculado", ""]
        linhas += [f"- {n}" for n in sem]

    with open("contas.md", "w", encoding="utf-8") as f:
        f.write("\n".join(linhas) + "\n")
    print(f"OK    contas.md gravado: {len(com)} contas com Instagram, {len(sem)} páginas sem")
    return 0


async def main() -> int:
    client = InstagramClient()
    if "--contas" in sys.argv:
        return await contas(client)
    return await verificar(client)


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
