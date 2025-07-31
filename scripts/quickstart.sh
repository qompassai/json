#!/bin/sh
# /qompassai/json/scripts/quickstart.sh
# Qompass AI JSON Quick Start Script
# Copyright (C) 2025 Qompass AI, All rights reserved
####################################################
set -eu
IFS='
'
case "$(uname -s)" in
Linux*) OS=linux ;;
Darwin*) OS=mac ;;
CYGWIN* | MINGW* | MSYS*) OS=windows ;;
*) OS=unknown ;;
esac
case "$OS" in
windows)
	USERPROFILE="${USERPROFILE:-$HOME}"
	XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$USERPROFILE/.config}"
	LOCAL_PREFIX="$USERPROFILE/.local"
	;;
*)
	XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
	LOCAL_PREFIX="$HOME/.local"
	;;
esac
BIN_DIR="$LOCAL_PREFIX/bin"
LIB_DIR="$LOCAL_PREFIX/lib"
SHARE_DIR="$LOCAL_PREFIX/share"
SRC_DIR="$LOCAL_PREFIX/src/json"
mkdir -p "$BIN_DIR" "$LIB_DIR" "$SHARE_DIR" "$SRC_DIR" "$XDG_CONFIG_HOME/json"
case ":$PATH:" in
*":$BIN_DIR:"*) ;;
*) export PATH="$BIN_DIR:$PATH" ;;
esac
detect_arch() {
	case "$(uname -m)" in
	x86_64 | amd64) echo "x86_64" ;;
	aarch64 | arm64) echo "aarch64" ;;
	armv7l | armv8* | arm*) echo "arm" ;;
	riscv64*) echo "riscv64" ;;
	*) echo "unknown" ;;
	esac
}
ARCH="$(detect_arch)"
echo '╭────────────────────────────────────────────╮'
echo '│     Qompass AI · JSON Quick‑Start          │'
echo '╰────────────────────────────────────────────╯'
echo '  © 2025 Qompass AI. All rights reserved'
echo
echo "Detected OS:    $OS"
echo "Detected Arch:  $ARCH"
echo
echo "Core JSON tools will be installed to $LOCAL_PREFIX/{bin,lib,share}"
echo
##################################
echo "→ Installing jq (JSON CLI processor)..."
JQ_URL=""
case "$OS" in
linux | mac)
	case "$ARCH" in
	x86_64) JQ_URL="https://github.com/jqlang/jq/releases/latest/download/jq-${OS}64" ;;
	aarch64) JQ_URL="https://github.com/jqlang/jq/releases/latest/download/jq-${OS}-arm64" ;;
	arm) JQ_URL="" ;; # Build from source - not provided prebuilt
	riscv64) JQ_URL="" ;;
	esac
	if [ -n "$JQ_URL" ]; then
		curl -fsSL "$JQ_URL" -o "$BIN_DIR/jq"
		chmod +x "$BIN_DIR/jq"
	else
		echo "Prebuilt jq not found for $ARCH. If you want, compile from source or install via your package manager."
	fi
	;;
windows)
	JQ_URL="https://github.com/jqlang/jq/releases/latest/download/jq-win64.exe"
	curl -fsSL "$JQ_URL" -o "$BIN_DIR/jq.exe"
	;;
*)
	echo "Unsupported or unknown OS!"
	exit 1
	;;
esac
echo "→ Installing fx (modern interactive JSON tool)..."
case "$OS" in
linux | mac)
	FX_URL=""
	case "$ARCH" in
	x86_64) FX_URL="https://github.com/antonmedv/fx/releases/latest/download/fx_linux_amd64" ;;
	aarch64) FX_URL="https://github.com/antonmedv/fx/releases/latest/download/fx_linux_arm64" ;;
	arm) FX_URL="" ;;
	esac
	if [ -n "$FX_URL" ]; then
		curl -fsSL "$FX_URL" -o "$BIN_DIR/fx"
		chmod +x "$BIN_DIR/fx"
	else
		echo "Prebuilt fx not found for $ARCH. You can install with npm if you have it."
	fi
	;;
windows)
	FX_URL="https://github.com/antonmedv/fx/releases/latest/download/fx_win.exe"
	curl -fsSL "$FX_URL" -o "$BIN_DIR/fx.exe"
	;;
*)
	echo "Skipping fx install."
	;;
esac
echo "→ Installing jsonlint (JSON linter/validator)..."
if command -v npm >/dev/null 2>&1; then
	npm install -g jsonlint
elif command -v pipx >/dev/null 2>&1; then
	pipx install jsonlint
else
	PY_CMD="$(command -v python3 || command -v python)"
	if [ -n "$PY_CMD" ]; then
		"$PY_CMD" -m pip install --user jsonlint
	else
		echo "Neither npm nor python found, skipping jsonlint."
	fi
fi
echo
printf "Do you want to install \033[1mJSON Language Server (vscode-json-languageserver)\033[0m for VSCode/LS support? [Y/n]: "
read -r ans
[ -z "$ans" ] && ans="Y"
if [ "$ans" = "Y" ] || [ "$ans" = "y" ]; then
	if command -v npm >/dev/null 2>&1; then
		npm install -g vscode-langservers-extracted
	elif command -v pipx >/dev/null 2>&1; then
		pipx install vscode-langservers-extracted
	else
		echo "Neither npm nor pipx found; please install vscode-langservers-extracted manually if desired."
	fi
fi
add_path_to_shell_rc() {
	rcfile=$1
	line="export PATH=\"$BIN_DIR:\$PATH\""
	if [ -f "$rcfile" ]; then
		if ! grep -Fxq "$line" "$rcfile"; then
			printf '\n# Added by Qompass AI JSON quickstart script\n%s\n' "$line" >>"$rcfile"
			echo " → Added PATH export to $rcfile"
		fi
	fi
}
add_path_to_shell_rc "$HOME/.bashrc"
add_path_to_shell_rc "$HOME/.zshrc"
add_path_to_shell_rc "$HOME/.profile"
create_xdg_config() {
	tool="$1"
	default_content="$2"
	confdir="$XDG_CONFIG_HOME/$tool"
	confpath="$confdir/config.json"
	mkdir -p "$confdir"
	if [ -f "$confpath" ]; then
		echo "→ $tool config already exists at $confpath"
		return
	fi
	printf "Do you want to write an example config for $tool to %s? [Y/n]: " "$confpath"
	read -r ans
	[ -z "$ans" ] && ans="Y"
	if [ "$ans" = "Y" ] || [ "$ans" = "y" ]; then
		echo "→ Creating example $tool config at $confpath"
		printf "%s\n" "$default_content" >"$confpath"
	fi
}
JSONLINT_CFG='{
  "rules": {
    "indent": 2,
    "allowComments": false
  }
}'
JQ_CFG='{
  // Add jq config options here
}'
LSP_CFG='{
  "json": {
    "schemas": {},
    "validate": true
  }
}'
create_xdg_config "jsonlint" "$JSONLINT_CFG"
create_xdg_config "jq" "$JQ_CFG"
create_xdg_config "vscode-json-languageserver" "$LSP_CFG"
echo
echo "✅ JSON tools have been installed in $BIN_DIR"
echo "→ Test jq with:      jq --version"
echo "→ Test fx with:      fx --version"
echo "→ Test jsonlint with: jsonlint --version"
echo "→ All configs placed in $XDG_CONFIG_HOME/"
echo "→ All user binaries/libs/configs are under ~/.local/, ~/.config/"
echo "→ To uninstall, just rm -rf $LOCAL_PREFIX/{bin,lib,share} $SRC_DIR $XDG_CONFIG_HOME/jsonlint $XDG_CONFIG_HOME/jq $XDG_CONFIG_HOME/vscode-json-languageserver"
echo "─ Ready, Set, JSON! ─"
exit 0
