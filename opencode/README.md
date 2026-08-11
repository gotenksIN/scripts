# OpenCode2 Notes

## Service port must stay below 49152 (WSL2 mirrored networking)

### Symptom

`opencode2` fails to start.
The TUI stops responding at "Starting background server..." and respawns `serve --service` every six seconds continuously.
The service exits with:

```text
Error: Managed service port 49374 on 127.0.0.1 is already in use by another process.
Configure another port with `opencode service set port <port>` and start the service again.
```

### Root cause (2026-08-11)

Opencode2 v0.0.0-next-17149 changed its managed background-service default port to 49374 (0xC0DE).
This machine runs WSL2 with `networkingMode=mirrored` (`C:\Users\...\.wslconfig`).
Inside WSL with mirrored networking, the entire Windows dynamic port range 49152-65535 cannot be bound.
`bind()` returns `EADDRINUSE` for any port in that range.
No socket appears in `ss`/`/proc/net/tcp`, and nothing listens on the Windows side either.
The range is a Hyper-V reservation inherited by mirrored networking.
The old binary used port 4096 (below 49152), which is why it worked before the update.

### Fix

```sh
opencode2 service set port 4096
opencode2 service start
```

Keep the configured port below 49152.
Any port in 49152-65535 fails on this WSL setup.

### Cleanup (2026-08-11)

We also removed stale state from crashed runs (`~/.local/state/opencode/service.json`, `~/.local/state/opencode/locks/`).
The application creates the service state file with `O_CREAT|O_EXCL`.
A stale file can also break startup after a version change.

## Updates are manual

The update warning "automatic update skipped: installation method not found" is expected.
The binary is installed manually at `~/.opencode/bin/opencode2`, so auto-update cannot detect the installation method.
Manually update the application when a new `next` version is announced.
