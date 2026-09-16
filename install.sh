#!/bin/bash
set -euo pipefail

repo_raw=${GH_REVIEW_NOTIFY_SRC:-https://raw.githubusercontent.com/oleg-chibikov/gh-review-notify/main}
label=io.github.gh-review-notify
interval=${GH_REVIEW_NOTIFY_INTERVAL:-180}
bin_dir="$HOME/.local/bin"
script="$bin_dir/gh-review-notify"
plist="$HOME/Library/LaunchAgents/$label.plist"
log="$HOME/Library/Logs/gh-review-notify.log"

die() { echo "$1" >&2; exit 1; }

[ "$(uname)" = "Darwin" ] || die "macOS only."
command -v gh > /dev/null || die "Install the GitHub CLI first: brew install gh"
gh auth status > /dev/null 2>&1 || die "Log in first: gh auth login"

if ! command -v jq > /dev/null; then
  echo "Installing jq..."
  brew install jq
fi

if ! command -v terminal-notifier > /dev/null; then
  echo "Installing terminal-notifier..."
  brew install terminal-notifier
fi

# macOS shows no notification until the app is known to LaunchServices.
app="$(brew --prefix terminal-notifier 2> /dev/null)/terminal-notifier.app"
if [ -d "$app" ]; then
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app"
  open -g "$app" --args -title "gh-review-notify" -message "Installing" > /dev/null 2>&1 || true
fi

mkdir -p "$bin_dir"
here=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2> /dev/null && pwd || echo .)
if [ -f "$here/gh-review-notify" ]; then
  cp "$here/gh-review-notify" "$script"
else
  curl -fsSL "$repo_raw/gh-review-notify" -o "$script"
fi
chmod +x "$script"

mkdir -p "$HOME/Library/LaunchAgents"
cat > "$plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$label</string>
	<key>ProgramArguments</key>
	<array>
		<string>$script</string>
	</array>
	<key>StartInterval</key>
	<integer>$interval</integer>
	<key>RunAtLoad</key>
	<true/>
	<key>StandardOutPath</key>
	<string>$log</string>
	<key>StandardErrorPath</key>
	<string>$log</string>
</dict>
</plist>
PLIST

echo "Reading your last few days of pull requests, this takes about a minute..."
"$script" || die "The first run failed. See $log"

launchctl bootout "gui/$(id -u)/$label" 2> /dev/null || true
launchctl bootstrap "gui/$(id -u)" "$plist"

"$script" --test

cat << TEXT

Installed.
  script   $script
  agent    $plist, every ${interval}s, starts again at login
  log      $log

A test notification should be on screen. If it is missing, switch on
System Settings > Notifications > terminal-notifier, then run:
  gh-review-notify --test
TEXT
