# StealthCup 2025: Evasion-Focused IDS Benchmarking

**StealthCup** is a novel evaluation framework that benchmarks Intrusion Detection Systems (IDS) under **realistic, adversarial conditions**.  
Instead of replaying synthetic datasets, StealthCup uses **evasion-focused Capture-the-Flag (CTF)** challenges executed by professional penetration testers on a validated IT/OT testbed.  

The project combines:
- A fully automated, reproducible Infrastructure-as-Code setup (Terraform, Ansible, Packer) spanning enterprise IT (Active Directory, Windows/Linux servers) and OT environments (virtualized PLCs, SCADA, historians).
- Realistic, multi-stage attack chains (IT → OT pivoting, AD takeover, PLC manipulation).
- A fully automated, reproducible Infrastructure-as-Code setup (Terraform, Ansible, Packer) spanning enterprise IT and OT environments.
- Comparative evaluation of open-source (Suricata, Wazuh) and anonymized commercial IDS solutions.
- Open datasets of alerts, PCAPs, logs, and structured attacker writeups.

StealthCup complements traditional benchmarks by exposing where IDS configurations fail against stealthy adversaries.

## Key Documents
- [Event Rules of the Game (PDF)](docs/Event_Rules_of_the_Game.pdf) – CTF competition format and scoring.  
- [Attack Walkthrough (MD)](docs/Attack_Walkthrough.md) – Step-by-step multi-stage intrusion example (for others see the writeups)
- [Writeups](docs/Writeups)  
- [Attack Chains (MD)](docs/img/KillChain.drawio.pdf) – Overview of the implemented TTPs.  
- [Plumetech Story (PDF)](docs/Plumetech_Story.pdf) – Narrative background used during the event.  

### Scientific Application & Results
- [Evaluation CSV](docs/ScientificApplication/csv)
- [IDS FP Labeling](docs/ManualDetectionEvaluation.xlsx)
- [Comparison with Volt Typhoon TTPs (XLSX)](docs/ScientificApplication/Comparison_VoltTyphoon.xlsx)  
- [StealthCup Event Timeline (XLSX)](docs/ScientificApplication/StealthCup_Timeline.xlsx)  

### IDS Configuration & Detection
- [Wazuh Detection Blog - Detecting State of the Art Active Directory attacks](docs/Wazuh-Detections/Blog-WazuhDetections.md)  
- [Local Wazuh Rules](docs/Wazuh-Detections/local_rules.xml)  
- [Custom Suricata Rules](docs/Wazuh-Detections/suricata_custom.rules)  

## Infrastructure

The `provisioning/` directories contain Terraform, Ansible, and Packer configurations for deploying the full IT/OT environment.  
Scripts and utilities for redeployment, testing, and simulation can be found under `scripts/` and `testing/`. 

![Overview of the network](docs/img/Network.png)

[Detailed Infrastructure](docs/img/Network_detail_aws.drawio.pdf)

### Setup
We will publish more informations on how to deploy the network soon. Meanwhile you are invited to send us a message if you have any questions: xxx

## Publications

StealthCup is described in detail in our research paper:  
- StealthCup: Realistic, Multi-Stage, Evasion-Focused CTF for Benchmarking IDS (March 2025 event)

```
tbd
```

## Raw data
Raw data (PCAPs, host logs) can be found [here](https://drive.google.com/drive/folders/1tImOIJMAg2kVXX8EeBACiXdWf2wGdlnW?usp=sharing).

### Disclaimer
StealthCup is a research framework. Some scripts, exploits, and configurations are provided for academic use only. Do not deploy outside controlled environments.