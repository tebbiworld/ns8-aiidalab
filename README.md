# ns8-aiidalab

[NethServer 8](https://github.com/NethServer/ns8-core) module for
**[AiiDAlab](https://www.aiidalab.net/)** — the web platform for
computational chemistry and materials science built on the
[AiiDA](https://www.aiida.net/) workflow engine — from the official
`aiidalab/full-stack` image.

- One-click AiiDA workflows with full provenance (every input, code and
  result stays traceable and reproducible), Jupyter notebooks, and AiiDAlab
  apps such as the **Quantum ESPRESSO app** (`aiidalab-qe`)
- **Remote computer**: register an SSH-reachable machine — e.g. a GPU
  container on Proxmox — as AiiDA computer from the module settings;
  calculations are submitted there while AiiDAlab keeps the bookkeeping.
  The instance's SSH public key is shown on the settings page; a connection
  test (`verdi computer test`) is one click away.
- Published through Traefik with Let's Encrypt, password login
- Backup of the whole workspace (AiiDA profile, PostgreSQL data, file
  repository, apps, notebooks, SSH key) plus a consistent `pg_dumpall`
- Pinned image with automatic upstream-update releases

One instance is **one workspace for one user** (that is how the AiiDAlab
image works — Jupyter, AiiDA daemon, PostgreSQL and RabbitMQ all run inside
the container as the `jovyan` user). Several instances per cluster are fine.

## Install

Add the repository `https://raw.githubusercontent.com/tebbiworld/ns8-repo/main/ns8/updates/`
in Software Center → Repositories, then install *AiiDAlab*. Or from the
leader node:

    add-module ghcr.io/tebbiworld/aiidalab:latest 1

## Configure

Open the instance settings: host name, Let's Encrypt, **login password**
(required), AiiDA identity (recorded as author in the provenance graph),
optional apps to install at start, optional remote computer. Save. The first
start creates the AiiDA profile and installs the apps — allow a few minutes;
the settings page shows the state. Then open `https://<host>/` and log in.

| Setting | Notes |
| --- | --- |
| Login password | Hashed and passed to Jupyter (`PasswordIdentityProvider`); token login is off. Leave empty to keep it. |
| AiiDA identity | E-mail, name, institution → `verdi quicksetup` at profile creation; later changes only affect new profiles. |
| Apps installed at start | `AIIDALAB_DEFAULT_APPS`: app names from the [registry](https://aiidalab.github.io/aiidalab-registry/) or git URLs, e.g. `aiidalab-qe`. Installed if missing at every start; more apps from the App Store inside AiiDAlab. |
| Remote computer | `verdi computer setup` (transport `core.ssh`, chosen scheduler, work dir, MPI command, MPI procs per machine) + `verdi computer configure core.ssh` with the instance's own key `~/.ssh/id_rsa`. An existing computer is only re-configured (AiiDA computers are immutable once used). |

### Remote computer (GPU node) workflow

1. Enable *Remote computer*, enter host, SSH user, work directory, scheduler
   (`core.direct` for a plain machine, `core.slurm` for a cluster), save.
2. Copy the **SSH public key** shown on the settings page into
   `~/.ssh/authorized_keys` of that user on the remote machine.
3. Click **Test connection** — runs `verdi computer test <label>` (login,
   scheduler, work directory, file transfer).
4. Install the simulation codes on the remote machine (Quantum ESPRESSO
   `pw.x`, CP2K, xtb, …; GPU builds welcome) and register them in AiiDAlab
   (Setup code widget or `verdi code create core.code.installed --computer
   <label> --filepath-executable /path/to/pw.x --default-calc-job-plugin
   quantumespresso.pw`). The Quantum ESPRESSO app has its own resource
   setup wizard.

The remote machine needs: SSH access, `bash`, the codes, and (for MPI) an
MPI runtime. Two AiiDA rules to know: a computer's host name, work directory
and scheduler are immutable once created (use a new label to change them —
the module warns and only re-applies the SSH transport), and a target on the
NethServer node itself must be entered as `host.containers.internal`, because
a rootless container cannot reach the node's own IP address. AiiDA copies inputs over SSH, submits, polls, and retrieves
the results into the provenance database on the NethServer node.

### Command line

    runagent -m aiidalab1 podman exec -it aiidalab-app bash -l   # verdi, pip, aiidalab CLI
    api-cli run module/aiidalab1/test-computer --data '{"label":"gpu-node"}'

## Backup and restore

The NS8 backup contains the module settings and the `aiidalab-home` volume
(profile, PostgreSQL data, file repository, apps, notebooks, SSH key). Right
before the snapshot the module writes a consistent `pg_dumpall` into its
state directory (`state/aiidalab.sql`), included in the backup as a
fallback should the raw database files have been caught mid-write. A
restore recreates the instance from the snapshot, fixes ownership for the
container user and starts it; the remote computer configuration is
re-applied.

## Resources

~1.5 GB RAM for Jupyter + AiiDA daemon + PostgreSQL + RabbitMQ (calculations
run on the remote computer, or on the node's CPUs through the built-in
`localhost` computer); the image is 2.7 GB, the home volume grows with the
file repository.

## Updates

The module pins the `aiidalab/full-stack` image (calendar tags
`YYYY.NNNN`). A weekly GitHub Action checks Docker Hub for a newer tag that
is at least six weeks old and releases a new module version; the Software
Center update restarts the container, AiiDA migrates the profile if needed.

## Development

    IMAGETAG=1.0.0 bash ./build-images.sh

## License

GPL-3.0-or-later. AiiDA and AiiDAlab are MIT-licensed projects of the
MARVEL NCCR / PSI / EPFL; the official image is pulled at runtime.
