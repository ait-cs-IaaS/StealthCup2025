# StealthCup 2025: Evasion-Focused IDS Benchmarking

**StealthCup** is a novel evaluation framework that benchmarks Intrusion Detection Systems (IDS) under **realistic, adversarial conditions**.  
Instead of replaying synthetic datasets, StealthCup uses **evasion-focused Capture-the-Flag (CTF)** challenges executed by professional penetration testers on a validated IT/OT testbed.  

The project combines:
- Realistic, multi-stage attack chains (IT → OT pivoting, AD takeover, PLC manipulation).
- A fully automated, reproducible **Infrastructure-as-Code** setup (Terraform, Ansible, Packer).
- Comparative evaluation of open-source (Snort, Suricata, Wazuh) and commercial IDS solutions.
- Open datasets of alerts, PCAPs, logs, and structured attacker writeups.  

StealthCup complements traditional benchmarks by exposing **where IDS configurations fail against stealthy adversaries**.

---

## Key Documents

- [Event Rules of the Game (PDF)](docs/Event_Rules_of_the_Game.pdf) – CTF competition format and scoring.  
- [Attack Walkthrough (MD)](docs/Attack_Walkthrough.md) – Step-by-step multi-stage intrusion example.  
- [Attack Chains (MD)](docs/Attack_Chains.md) – Overview of the implemented TTPs.  
- [Plumetech Story (PDF)](docs/Plumetech_Story.pdf) – Narrative background used during the event.  

### Scientific Application & Results
- [Evaluation Notes (MD)](docs/ScientificApplication/eval.md) – IDS evaluation writeup.  
- [Manual Detection Evaluation (XLSX)](docs/ScientificApplication/ManualDetectionEvaluation.xlsx)  
- [Comparison with Volt Typhoon TTPs (XLSX)](docs/ScientificApplication/Comparison_VoltTyphoon_felix_manuel.xlsx)  
- [StealthCup Timeline (XLSX)](docs/ScientificApplication/StealthCup_Timeline.xlsx)  
- [TTP Mapping (MD)](docs/ScientificApplication/TTPs.md)  

### IDS Configuration & Detection
- [Wazuh Detection Blog - Detecting State of the Art Active Directory attacks](docs/Wazuh-Detections/Blog-WazuhDetections.md)  
- [Local Wazuh Rules](docs/Wazuh-Detections/local_rules.xml)  
- [Custom Suricata Rules](docs/Wazuh-Detections/suricata_custom.rules)  

---

## 🛠️ Infrastructure

The `provisioning/` and `windows-setup/` directories contain **Terraform, Ansible, and Packer** configurations for deploying the full IT/OT environment.  
Scripts and utilities for redeployment, testing, and simulation can be found under `scripts/` and `testing/`.  

---

## 📊 Publications

StealthCup is described in detail in our upcoming research papers:  
- xxx

---

## Related

- Dataset release (alerts, PCAPs, logs) – coming soon.  
- CALDERA attack profiles derived from attacker writeups – work in progress.  

---

### Disclaimer
StealthCup is a research framework. Some scripts, exploits, and configurations are provided **for academic use only**. Do **not** deploy outside controlled environments.