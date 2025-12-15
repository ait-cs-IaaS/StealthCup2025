# StealthCup Dataset Layout

This repository contains artifacts collected from StealthCup runs.
Data is organized by view angle (attacker, host, network, IDS, event) and further split by team and run where applicable.

Data root: `stealthcup/`
Run metadata: `dataset/teamX/runY/run.yaml` (high-level dataset metadata lives in `dataset/`)

## Event Overview

The event was officially conducted from **08:30 to 16:30 (UTC)** on **2025-03-28** in Vienna.  
Each team was provided with an isolated infrastructure consisting of the hosts described in [hosts.yaml](hosts.yaml). The infrastructures were strictly separated from one another.

All network traffic was routed through an AWS Network Firewall. Each team accessed its environment via a dedicated management host, which also acted as the Ansible control node and executed orchestration scripts. This management host had port forwarding enabled to the team’s respective Kali Linux machine. All attacks were initially orchestrated from the Kali Linux host.

## Dataset Structure and Runs

In total, we collected 24 runs. One run corresponds to one dataset instance on a single infrastructure. Each team performed up to three runs, where a *reset* of the infrastructure disabled network access until a fresh environment was provisioned. The reset resulted in a logically identical infrastructure with new credentials and partially randomized artifacts.

For each run, teams were given predefined objectives, which were validated as:

- `it_flag` – domain administrator access within the IT domain  
- `ot_flag` – disabling of a PLC safety function  

These objectives are described in the [dataset description](stealthcup_dataset.yaml). Not every team was able to solve all challenges.

## Attack Vectors

All intended attack vectors available during the evaluation are documented in [attack_vectors.yaml](attack_vectors.yaml). In addition, we include unintended attack vectors that were not part of the original design but were identified through the write-ups submitted by participating teams.

## Naming Conventions

Teams and runs:
- teamX where X is the team number, e.g. team3
- runY where Y is the run number, e.g. run2

## Run
To navigate the runs, we have created the following metadata for each run in a seperate file `dataset/teamX/runY/run.yaml`. An overview of all runs can be found in the [Dataset Run Index Table](dataset_run_index.md).

Per run we provide the following metadata:
```
timeline:
  start: None (we notified players when we opened the game infrastructure for them, this information is not available for all runs)
  suricata_start: 2025-03-28 15:08:53 (from backups of suricata logs - indicator when the infrastructure was up running)
  first_con_not_win_host: 2025-03-28 08:38:07 (first connection to host that is not in the same subnet, since windows and kali connection is noisy - indicator for hacking attempts)
  it_flag: 2025-03-28T15:51:57 (database - objective solves where automatically verified and saved to event database)
  ot_flag: None (database - objective solves where automatically verified and saved to event database)
  reset: 2025-03-28T14:37:54 (database - resets where saved to event database)
  writeup: None (are writeups for that run availabe?)
  host_logs: 2025-03-28T14:11:00 (are host logs for that run availabe?)
```


# raw dataset
## attacker
Writeups are stored per team and run:
 * `attacker/writeups/teamX/runY/`

Typical contents:
- writeup.md including GMT+1 timestamps and team name

## event
Event-level telemetry shared across teams.
 * `event/alerts/`
 * `event/game_database/`


## host
Host logs (per team/run, timestamped snapshot):
 * `host/logs/teamX/runY/<host-ip>/`

Example:
 * `host/logs/team1/run1/10.0.1.11/`

Host metrics (global snapshots):
 * `host/metrics/teamX/runY/<host-ip>/`


## ids
IDS exports per team and run:
 * `ids/suricata/teamX/runY/`
 * `ids/wazuh/teamX/runY/`
 * `ids/commercial_vendor_a/teamX/runY/`
 * `ids/commercial_vendor_b/teamX/runY/`

## network

PCAPs per team and run:
 * `network/pcap/teamX/runY/`

Firewall telemetry:
 * `network/firewall/netflow`
 * `network/firewall/alerts`


## Notes

- if not explicilty mentioned, UTC. Otherwise timzone is indicated as GMT+1
- dataset YAML files are the source of truth for artifact availability and timing
- host log timestamp directories represent collection snapshots
- missing artifacts should be treated explicitly
