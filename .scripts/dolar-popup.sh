#!/usr/bin/env bash
# dolar-popup.sh — display all dollar rates in a tmux popup
# Called via the launcher (launcher-wrapper.sh → launcher-popup.sh)

export LC_ALL=en_US.UTF-8

cache_file="/tmp/tmux2k_dolar_cache"
cache_ttl=300

fetch_rates() {
    curl -sf --max-time 5 "https://dolarapi.com/v1/dolares" 2>/dev/null
}

get_cached_or_fetch() {
    if [ -f "$cache_file" ]; then
        local age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))
        if [ "$age" -lt "$cache_ttl" ]; then
            cat "$cache_file"
            return
        fi
    fi
    local result
    result=$(fetch_rates)
    if [ -n "$result" ]; then
        echo "$result" > "$cache_file"
        echo "$result"
    elif [ -f "$cache_file" ]; then
        cat "$cache_file"
    fi
}

json=$(get_cached_or_fetch)

if [ -z "$json" ]; then
    echo "No se pudo obtener cotizaciones."
    read -r -t 5
    exit 1
fi

python3 - "$json" <<'PYEOF'
import sys, json

raw = sys.argv[1]
data = json.loads(raw)

order = ["oficial", "blue", "bolsa", "contadoconliqui", "mayorista", "cripto", "tarjeta"]
data_map = {item["casa"]: item for item in data}

GREEN  = "\033[32m"
YELLOW = "\033[33m"
CYAN   = "\033[36m"
BOLD   = "\033[1m"
RESET  = "\033[0m"

print(f"{BOLD}{CYAN}  Cotizaciones del Dólar{RESET}")
print(f"{CYAN}{'─' * 42}{RESET}")
print(f"{BOLD}{'Nombre':<22} {'Compra':>8} {'Venta':>8}{RESET}")
print(f"{CYAN}{'─' * 42}{RESET}")

for casa in order:
    item = data_map.get(casa)
    if not item:
        continue
    nombre = "CCL" if casa == "contadoconliqui" else "MEP" if casa == "bolsa" else item.get("nombre", casa)
    compra = item.get("compra")
    venta  = item.get("venta")
    c_str = f"${int(compra) if compra == int(compra) else compra:,.1f}" if compra is not None else "  --"
    v_str = f"${int(venta)  if venta  == int(venta)  else venta:,.1f}"  if venta  is not None else "  --"

    color = YELLOW if casa == "bolsa" else GREEN
    print(f"{color}{nombre:<22} {c_str:>8} {v_str:>8}{RESET}")

# Updated timestamp from the most recent item
last_update = max((item.get("fechaActualizacion","") for item in data), default="")
if last_update:
    from datetime import datetime, timezone
    try:
        dt = datetime.fromisoformat(last_update.replace("Z", "+00:00"))
        local_dt = dt.astimezone()
        ts = local_dt.strftime("%d/%m/%Y %H:%M")
    except Exception:
        ts = last_update
    print(f"\n{CYAN}Actualizado: {ts}{RESET}")

print(f"\n{CYAN}Presioná cualquier tecla para cerrar…{RESET}")
PYEOF

read -r -n1 -s
