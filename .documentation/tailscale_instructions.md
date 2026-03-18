# Tailscale Setup & SSH Key Authentication

## 1. Install Tailscale (Ubuntu)

If you have any PPAs that don't support your Ubuntu version, remove them first to avoid breaking the installer:

```bash
sudo add-apt-repository --remove ppa:neovim-ppa/stable -y
```

Then run the official installer:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

---

## 2. Start Tailscale

```bash
sudo tailscale up
```

Follow the URL printed in the terminal to authenticate with your Tailscale account.

---

## 3. Verify the Connection

Check your Tailscale IP:

```bash
tailscale ip -4
```

Check the status of all devices on your tailnet:

```bash
tailscale status
```

---

## 4. Enable MagicDNS (optional but recommended)

Instead of using the raw Tailscale IP, MagicDNS gives each device a hostname.

1. Go to https://login.tailscale.com/admin/dns
2. Enable **MagicDNS**

After that, you can reach this machine by hostname instead of IP:

```bash
ssh lucas@your-hostname
```

---

## 5. Enable SSH Server on the Host Machine

```bash
sudo systemctl enable --now ssh
```

Verify it's running:

```bash
sudo systemctl status ssh
```

---

## 6. Set Up SSH Key Authentication

### On the external (client) machine

Generate an SSH key pair if you don't have one:

```bash
ssh-keygen -t ed25519
```

This creates:
- `~/.ssh/id_ed25519` — private key (never share this)
- `~/.ssh/id_ed25519.pub` — public key (this is what you share)

Print the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the output — it looks like:

```
ssh-ed25519 AAAA...long string... user@machine
```

### On the host machine (SSH server)

Add the external machine's public key to your authorized keys:

```bash
echo "ssh-ed25519 AAAA...paste-the-public-key-here..." >> ~/.ssh/authorized_keys
```

Make sure the permissions are correct:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

---

## 7. Disable Password Authentication (recommended)

Edit the SSH config:

```bash
sudo nano /etc/ssh/sshd_config
```

Set or update these lines:

```
PasswordAuthentication no
PubkeyAuthentication yes
```

Restart SSH to apply:

```bash
sudo systemctl restart ssh
```

---

## 8. Connect from the External Machine

Using Tailscale IP:

```bash
ssh lucas@<tailscale-ip>
```

Or using MagicDNS hostname:

```bash
ssh lucas@your-hostname
```

---

## Security Summary

| Layer     | What it provides                                  |
|-----------|---------------------------------------------------|
| Tailscale | Device must be enrolled in your tailnet           |
| SSH key   | Device must hold the matching private key         |

Together these form a strong two-factor setup with no extra software required.
