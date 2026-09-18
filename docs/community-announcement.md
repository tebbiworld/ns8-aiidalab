<!--
First community post for the NS8 AiiDAlab module, written in the style
of https://community.nethserver.org/t/ns8-forgejo-testing/28554 (first post).
Paste into a new topic on community.nethserver.org, category "App", tag "ns8".
Fill in the wiki link once the page is published.
-->

# NS8 AiiDAlab (testing)

Hi all,

I've built an NS8 module for [AiiDAlab](https://www.aiidalab.net/) — the web platform for computational chemistry and materials science built on the [AiiDA](https://www.aiida.net/) workflow engine.

It's in my community repository. To try it, add the repo once:

```
api-cli run add-repository --data '{"name":"tebbiworld","url":"https://raw.githubusercontent.com/tebbiworld/ns8-repo/main/ns8/updates/","status":true,"testing":false}'
```

then install **AiiDAlab** from the Software Center. (Or straight from the image: `add-module ghcr.io/tebbiworld/aiidalab:latest 1`.)

What it does:

* Runs the official `aiidalab/full-stack` image (Jupyter, the AiiDA daemon, PostgreSQL and RabbitMQ, all in one rootless container) behind Traefik with Let's Encrypt and password login
* AiiDA workflows with **full provenance** — every input, code and result stays traceable and reproducible
* Jupyter apps such as the **Quantum ESPRESSO app** (`aiidalab-qe`), installable at start, with more from the App Store inside AiiDAlab
* **Remote computer**: register an SSH-reachable machine — e.g. a GPU node on your Proxmox host or a cluster — as an AiiDA computer from the settings; calculations run there while AiiDAlab keeps the bookkeeping. The instance's SSH public key is shown on the settings page and a connection test is one click.
* NS8 backup of the whole workspace (AiiDA profile, PostgreSQL data, file repository, apps, notebooks, SSH key) plus a consistent `pg_dumpall`

A few things to know:

* **One instance is one workspace for one user** — that's how the AiiDAlab image is built. Several instances per cluster are fine.
* The login password is required; it's hashed and handed to Jupyter, and token login is off.
* For the remote computer: AiiDA computers are immutable once used, so changing the host or work dir means a new label; and a target on the NethServer node itself must be entered as `host.containers.internal`, since a rootless container can't reach the node's own IP.
* Reckon on roughly 1.5 GB RAM for the daemon stack (image is about 2.7 GB); the heavy computation happens on the remote computer, or on the node's CPUs through the built-in `localhost` computer.

Still testing, so I'd genuinely welcome any feedback — especially from anyone wiring up a remote GPU/compute node over SSH.

Docs: NethServer wiki (tebbiworld repository) · Source: [github.com/tebbiworld/ns8-aiidalab](https://github.com/tebbiworld/ns8-aiidalab)

Thanks!

*Category: App · Tags: ns8*
