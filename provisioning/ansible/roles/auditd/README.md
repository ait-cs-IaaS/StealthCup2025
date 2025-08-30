# Ansible-Role: auditd

Ansible Role that installs and configures [auditd](https://linux.die.net/man/8/auditd)

## Requirements

- Debian stretch or newer
- Ubuntu bionic or newer

## Defaults

```yaml
audit_rules_tpl: "audit_rules.j2"
```

```yaml
audit_rules: []
```

```yaml
audit_buffer: 81920
```

# Usage

```yaml
- hosts: localhost
  roles:
    - auditd
  vars:
    audit_rules:
      - { rule: '-a always,exit -S all -F uid=www-data', comment: "hallo" }
      - { rule: '-a always,exit -S all -F uid=root' }

```
