# gh-review-notify

A macOS notification the moment someone reviews or comments on your pull request.
Click it and the comment opens in the browser.

## The problem

GitHub tells you by email. Email lands in a folder you read twice a day, so an
approval sits there for hours and the branch goes stale.

The GitHub app for Slack doesn't fix it. `/github subscribe owner/repo reviews`
posts every review in the repo, including PRs you have nothing to do with, and
there is no filter for "mine only". It also refuses to work in a DM with the
app, so you end up creating a channel for yourself.

## How it works

A `launchd` agent runs one shell script every 3 minutes. The script asks the
GitHub CLI for the pull requests you have a stake in:

- you opened it
- you commented on it, were mentioned or assigned
- you already left a review
- someone asked you by name to review it

For each of those it reads the reviews, the comments on the conversation tab and
the inline comments on the diff. Then it drops everything you wrote yourself and
everything it has already shown, and posts the rest. The notification opens the
exact comment, e.g. `.../pull/42#discussion_r123`.

What it stays quiet about:

- bots. CodeRabbit, Semgrep and friends leave dozens of comments and drown out
  the people. Set `GH_REVIEW_NOTIFY_BOTS=1` to hear them.
- reviews asked of a team you belong to. GitHub search counts those as
  `review-requested:@me`, which is how most of the noise gets in. Every hit is
  checked against `requested_reviewers` on the PR, so only your own name counts.
- your own comments, closed PRs, CI results.

A reviewer who leaves ten inline comments at once gets one notification, not
ten: more than four new items on the same PR collapse into "7 new comments on
api-users#570" with the names underneath.

The first run records the last 3 days without a sound, so you don't get a wall
of old notifications. Seen items live in `~/.cache/gh-review-notify/seen.txt`.

## Install

macOS, with [GitHub CLI](https://cli.github.com) installed and logged in.

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/oleg-chibikov/gh-review-notify/main/install.sh)"
```

It installs `jq` and `terminal-notifier` through Homebrew if they are missing,
puts the script in `~/.local/bin`, and loads the agent. The agent starts again
by itself at every login.

To read the code before running it:

```sh
git clone https://github.com/oleg-chibikov/gh-review-notify.git
cd gh-review-notify && ./install.sh
```

The first thing to check is that a test notification appears. If nothing shows
up, switch on **System Settings > Notifications > terminal-notifier** and run
`gh-review-notify --test`.

## Settings

All three are read when you install, and written into the agent:

```sh
GH_REVIEW_NOTIFY_INTERVAL=60 ./install.sh   # poll every 60 seconds, default 180
GH_REVIEW_NOTIFY_DAYS=7 ./install.sh        # look 7 days back, default 3
GH_REVIEW_NOTIFY_BOTS=1 ./install.sh        # bot comments too, default off
```

The first run reads every pull request you take part in and takes about a
minute. After that each run only opens the ones whose `updatedAt` moved, so the
usual run is under 10 seconds and a handful of API calls, against a limit of
5000 an hour.

## Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/oleg-chibikov/gh-review-notify/main/uninstall.sh | bash
```

## When nothing arrives

```sh
launchctl list | grep gh-review-notify   # third column is the label, second is the last exit code
tail ~/Library/Logs/gh-review-notify.log
gh-review-notify --test                  # checks only the macOS side
```

A user agent runs while you are logged in, and stops while the Mac sleeps. On
wake it does one run and catches up on anything from the last 3 days.

github.com only. GitHub Enterprise hosts are not handled.

## Licence

MIT
