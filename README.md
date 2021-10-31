# LogWatcher

WIP: not ready for consumption

Working out a rudimentary way to emit a strongly typed event based on parsing a line than comes through a pipe.

Initial use case is detecting when any MacOS App turns on/off webcam.   No known public API, so monitor unified logging for known clues.

NOTE: requires disabling app sandbox so it can execute /usr/bin/log (remove com.apple.security.app-sandbox section from entitlements)
