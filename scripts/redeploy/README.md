# Script Overview
This script is used to **destroy and redeploy virtual machines** selected from the VM map defined in a YAML file.
It can get executed from anywhere within the project.

---

## Usage

### Console Command
```bash
redeploy <path/to/vm_map.yaml>
```

### Instructions
1. In the terminal, tick the checkboxes of the machines you want to destroy and redeploy.  
2. Press **Enter** to execute the operation.

---

## Example VM Map

The **key** represents the instance name in AWS (the resource that will be destroyed and redeployed).  
The **value** indicates the corresponding Terragrunt subdirectory in the project.

```yaml
reposerver: repository
linuxshare: repository
webcam: videoserver
corpdns: videoserver
attacker: attacker
inet-dns: bootstrap
inet-fw: bootstrap
mgmt: bootstrap
```
