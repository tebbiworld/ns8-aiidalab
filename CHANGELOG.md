# Changelog

## 1.1.0 — 2026-09-19

Alignment with the NethServer module conventions (NethServer/agents skills).

### Changed

- **Secrets moved out of the module environment.** The hash of the notebook password is now kept in `state/passwords.env` (mode 0600) instead of `state/environment`, which NS8 mirrors to Redis in plain text. Existing installations are migrated on update; the password does not change.
- The module backup includes `state/passwords.env`; restore reads the hash from it (backups taken with 1.0.0 are still restorable) and re-creates the route with the original Let's Encrypt setting.
- `update-module` only restarts a running instance.

### Added

- Robot Framework tests (install, update from the previous release, backup and restore) run on real NS8 nodes through `stephdl/ns8-ci-actions`.

## 1.0.0 — 2026-09-15

- Initial release: aiidalab/full-stack (pinned) behind Traefik with
  password login, AiiDA identity, apps installed at start, remote computer
  provisioning over SSH (setup + configure + connection test action, public
  key on the settings page), backup with pg_dumpall + home volume, restore,
  settings UI (EN/DE), automatic upstream-update releases.
