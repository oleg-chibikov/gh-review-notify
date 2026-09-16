# gh-review-notify

A macOS notification when someone reviews or comments on your pull request. Click
it and the comment opens.

## The problem

GitHub sends email. You read email twice a day, so an approval sits there for
hours.

The GitHub app for Slack posts every review in a repo, with no way to say "only
mine". And `/github subscribe` refuses to run in a DM with the app, so you end up
making a channel for yourself.

## How it works

A `launchd` agent runs a shell script every 3 minutes. It asks the GitHub CLI for
the pull requests you are part of:

- you opened it
- you commented, were mentioned or assigned
- you already reviewed it
- someone asked you by name to review it

For each one it reads the reviews, the conversation comments and the inline
comments on the diff, drops what you wrote yourself and what it has already
shown, and pops the rest. The notification opens the exact comment:
`.../pull/42#discussion_r123`.

It stays quiet about:

- bots. CodeRabbit and Semgrep leave dozens of comments and bury the people.
  `GH_REVIEW_NOTIFY_BOTS=1` brings them back.
- reviews asked of your team. GitHub search counts those as
  `review-requested:@me`, and that is where most of the noise comes from. Each
  hit is checked against `requested_reviewers`, so only your own name counts.
- your own comments, closed PRs, CI.

Ten inline comments from one reviewer arrive as a single notification. Past four
new items on the same PR they collapse into "7 new comments on api-users#570"
with the names underneath.

The first run records the last 3 days silently, so you skip the wall of old
notifications. What it has shown lives in `~/.cache/gh-review-notify/seen.txt`.

## Install

macOS, with [GitHub CLI](https://cli.github.com) installed and logged in.

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/oleg-chibikov/gh-review-notify/main/install.sh)"
```

It installs `jq` and `terminal-notifier` through Homebrew if they are missing,
puts the script in `~/.local/bin` and loads the agent. The agent starts again at
every login.

To read the code first:

```sh
git clone https://github.com/oleg-chibikov/gh-review-notify.git
cd gh-review-notify && ./install.sh
```

A test notification comes at the end. If nothing shows up, switch on **System
Settings > Notifications > terminal-notifier** and run `gh-review-notify --test`.

## Settings

Read when you install, and written into the agent:

```sh
GH_REVIEW_NOTIFY_INTERVAL=60 ./install.sh   # poll every 60 seconds, default 180
GH_REVIEW_NOTIFY_DAYS=7 ./install.sh        # look 7 days back, default 3
GH_REVIEW_NOTIFY_BOTS=1 ./install.sh        # bot comments too, default off
```

The first run reads every pull request you are part of and takes a minute. After
that it only opens the ones whose `updatedAt` moved, so a run is under 10 seconds
and a few API calls out of the 5000 you get an hour.

## Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/oleg-chibikov/gh-review-notify/main/uninstall.sh | bash
```

## When nothing arrives

```sh
gh-review-notify --status   # agent, account, last run, settings
gh-review-notify --test     # checks the macOS side only
tail ~/Library/Logs/gh-review-notify.log
```

A user agent runs while you are logged in and sleeps with the Mac. On wake it
does one run and catches up.

github.com only, no Enterprise hosts.

## Licence

MIT
