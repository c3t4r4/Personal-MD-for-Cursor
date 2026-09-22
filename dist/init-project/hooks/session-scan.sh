#!/usr/bin/env bash
#
# session-scan.sh — wrapper para o hook sessionStart do Cursor
#
# Lê JSON de stdin (contrato de hooks do Cursor), roda _scan.sh sessao no
# workspace quando possível, e emite followup_message com o resumo (ou
# {} se não houver contexto útil).
#
# Nunca falha de forma a bloquear a abertura da sessão.

set -uo pipefail

CURSOR_HOME="${CURSOR_CONFIG_DIR:-$HOME/.cursor}"
SCAN_SH="${CURSOR_HOME}/templates/init-project/_scan.sh"

# Tentar extrair workspace/root do JSON de entrada (best-effort).
input="$(cat || true)"
cwd="."
if command -v python3 >/dev/null 2>&1 && [[ -n "${input}" ]]; then
  extracted="$(python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
except Exception:
    sys.exit(0)
for k in ("workspace_roots","workspaceRoots","cwd","root","project_dir","projectDir"):
    v=d.get(k)
    if isinstance(v,list) and v:
        print(v[0]); sys.exit(0)
    if isinstance(v,str) and v:
        print(v); sys.exit(0)
' <<<"${input}" 2>/dev/null || true)"
  if [[ -n "${extracted}" ]]; then
    cwd="${extracted}"
  fi
fi

if [[ ! -x "${SCAN_SH}" ]]; then
  echo '{}'
  exit 0
fi

resumo="$("${SCAN_SH}" sessao "${cwd}" 2>/dev/null || true)"
if [[ -z "${resumo}" ]]; then
  echo '{}'
  exit 0
fi

if command -v python3 >/dev/null 2>&1; then
  python3 -c '
import json,sys
msg=sys.stdin.read().strip()
if not msg:
    print("{}")
else:
    print(json.dumps({"followup_message": msg}, ensure_ascii=False))
' <<<"${resumo}"
else
  # Fallback mínimo sem python
  escaped="${resumo//\\/\\\\}"
  escaped="${escaped//\"/\\\"}"
  escaped="${escaped//$'\n'/\\n}"
  printf '{"followup_message":"%s"}\n' "${escaped}"
fi

exit 0
