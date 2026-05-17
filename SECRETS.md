# Secrets Setup Guide

Run these commands once after restoring your GPG key and cloning the pass store.
This populates `pass` with every secret that chezmoi templates reference.

```bash
# Initialise pass with your GPG key ID
# Find it with: gpg --list-secret-keys --keyid-format LONG
pass init <YOUR_GPG_KEY_ID>
```

## OCI

```bash
pass insert oci/tenancy-ocid    # ocid1.tenancy.oc1..xxx
pass insert oci/user-ocid       # ocid1.user.oc1..xxx
pass insert oci/fingerprint     # a6:9d:e8:...
```

## Oracle DB

```bash
pass insert oracle/username
pass insert oracle/password
pass insert oracle/wallet-password
```

## Atlassian (Jira + Confluence share the same token)

```bash
pass insert atlassian/api-token   # ATATT3x...
```

## Misc

```bash
pass insert misc/regional-password
```

## Contravisory DB

```bash
pass insert db/contra/url        # jdbc:mysql://...
pass insert db/contra/username
pass insert db/contra/password
```

## After populating pass

Verify chezmoi can render templates cleanly:

```bash
chezmoi execute-template < ~/.local/share/chezmoi/home/private_dot_env.sh.tmpl
```

All values should be real credentials with no `{{ }}` visible.
Then apply:

```bash
chezmoi apply
```

## SSH keys

SSH keys are NOT in git or pass — they live on your USB backup only.
After bootstrap, copy keys manually:

```bash
cp /media/<user>/USB/ssh-keys/* ~/.ssh/
chmod 600 ~/.ssh/*.key ~/.ssh/*.pem
```
