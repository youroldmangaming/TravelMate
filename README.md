# Raspberry Pi Travel Router Setup Guide

This document provides instructions for setting up your Raspberry Pi as an all-in-one travel router using environment variables for configuration.

## What's Included

- **Pi-hole** for network-wide ad blocking
- **RaspAP** for easy WiFi configuration
- **ZeroTier** for remote access
- **SMB** and **NFS** file sharing
- All configured from a single `.env` file

## Initial Setup

### 1. Hardware Requirements

- Raspberry Pi (3B, 3B+, or 4B recommended)
- MicroSD card (16GB+ recommended)
- Two WiFi interfaces:
  - Built-in WiFi (for internet connection)
  - USB WiFi adapter (for creating your hotspot)
- Power supply for the Raspberry Pi

### 2. Software Prerequisites

- Raspberry Pi OS Lite (64-bit recommended)
- Docker and Docker Compose
- Git

Install the prerequisites:
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
```

### 3. Clone the Repository

```bash
git clone https://github.com/youroldmangaming/travelmate.git
cd TravelMate
```

### 4. Configure Your Router

1. Copy the example .env file and edit it:
```bash
cp .env.example .env
nano .env
```

2. Customize the environment variables according to your needs:
   - Set your WiFi SSID and password
   - Choose secure passwords for Pi-hole, RaspAP, and Samba
   - Add your ZeroTier network ID
   - Specify the path to your shared directory

### 5. Build and Run

```bash
make build
make run
```

The first build may take some time as it downloads and installs all necessary packages.

## Accessing Your Services

After the router is running, you can access the following services:

### Pi-hole Admin Panel
- URL: http://192.168.42.1/admin
- Password: The one you set in the `.env` file under `PIHOLE_PASSWORD`

### RaspAP Admin Panel
- URL: http://192.168.42.1/raspap
- Username/Password: As set in the `.env` file under `RASPAP_USERNAME` and `RASPAP_PASSWORD`

### Shared Files
- SMB: `\\192.168.42.1\shared`
- NFS: `192.168.42.1:/shared`
- Login: As set in the `.env` file under `SMB_USERNAME` and `SMB_PASSWORD`

## Managing Your Router

### Checking Status
```bash
make status
```

### Viewing Logs
```bash
make logs
```

### Updating Passwords
If you change passwords in the `.env` file after the router is already running:
```bash
make update-passwords
```

### Stopping and Cleaning Up
```bash
make clean
```

## Customizing Further

### Changing WiFi Settings After Deployment
1. Edit the `.env` file and update the relevant variables
2. Run `docker restart travel-router` or redeploy with `make clean && make build && make run`

### Adding Custom DNS Entries
You can use Pi-hole's admin interface to add local DNS records.

### Extending Shared Storage
If you need more storage for your shared directory:
1. Connect an external USB drive to your Raspberry Pi
2. Format it with a suitable filesystem (ext4 recommended)
3. Mount it and update your `.env` file to point to the new location

## Troubleshooting

### WiFi Hotspot Not Working
- Make sure your USB WiFi adapter is compatible with hostapd
- Check that the interface names in `.env` match your actual hardware
- View hostapd logs: `docker exec -it travel-router cat /var/log/hostapd.err.log`

### ZeroTier Connection Issues
- Verify your network ID is correct in the `.env` file
- Check that the node is authorized in your ZeroTier network admin panel
- Check ZeroTier logs: `docker exec -it travel-router cat /var/log/zerotier.err.log`

### File Sharing Problems
- Ensure permissions are correct: `docker exec -it travel-router chmod 777 /shared`
- Restart Samba: `docker exec -it travel-router supervisorctl restart smbd nmbd`
- Restart NFS: `docker exec -it travel-router supervisorctl restart nfsd mountd rpcbind`

## Security Considerations

- Change all default passwords in the `.env` file
- For public networks, consider increasing WiFi security settings
- Regularly update your Docker image with `make build && make run`

## Advanced Configuration

For advanced users who want to modify the setup beyond what's available in the `.env` file:

1. Modify the Dockerfile and rebuild
2. Add new template files and update the `start.sh` script
3. Extend the supervisord.conf to manage additional services
