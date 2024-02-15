# Asterisk SIP Peer Monitor

## Overview
This script is designed for monitoring SIP peers in Asterisk-based systems that use `chan_sip` (not `pjsip`), with a particular focus on multi-tenant systems such as SIPSTACK UC or Thirdlane. These systems typically name their extensions with the tenant name, making it possible to filter and monitor SIP peers based on tenant-specific criteria. The script checks for `UNREACHABLE` SIP peers and sends email notifications, with a built-in mute period to prevent repeated alerts for the same device within a given timeframe.

## Features
- **Tenant Filtering**: Supports monitoring SIP peers by specific tenant names, making it ideal for multi-tenant PBX systems.
- **Email Notifications**: Sends email alerts for `UNREACHABLE` SIP peers, with detailed information including extension, last known IP, and port.
- **Mute Period**: Configurable mute period to limit repeat notifications for the same `UNREACHABLE` SIP peer within the set timeframe.

> Please note, if a monitored device transitions from an `UNREACHABLE` state back to reachable (online) and then becomes `UNREACHABLE` again, a new notification will be sent regardless of the mute period. This ensures that each significant status change is communicated, providing timely alerts for devices experiencing intermittent issues.

## Requirements
- Asterisk-based system using `chan_sip` module.
- `sendmail` or compatible MTA (Mail Transfer Agent) configured for sending emails from the command line.

## Usage
To use the script, simply clone or download it to your Asterisk server and make it executable:

```bash
chmod +x sip_peer_monitor.sh
```

Run the script with optional arguments:

```bash
./sip_peer_monitor.sh [tenant] [recipient email] [mute period in seconds]
```

- **tenant**: Optional. Specify the tenant name to filter SIP peers. If omitted, all peers are considered.
- **recipient email**: Mandatory. The email address where notifications will be sent.
- **mute period**: Optional. Time in seconds to mute repeated alerts for the same device. Defaults to 86400 seconds (24 hours).

### Example
Monitor all SIP peers and send notifications to admin@example.com, with a mute period of 12 hours (43200 seconds):

```bash
./sip_peer_monitor.sh "" admin@example.com tenantNameHere
```

## Cron Job Suggestion
To automate monitoring, you can set up a cron job to run the script at desired intervals. For example, to check every 15 minutes:

```cron
*/15 * * * * /path/to/sip_peer_monitor.sh "" admin@example.com tenantNameHere
```

Adjust the script path, email address, and mute period as needed.

## License
This script is provided under the MIT License. See the included LICENSE file for details.

## Disclaimer
This script is offered AS IS, without warranty of any kind. The author(s) will not be liable for any damages, loss of data, or any other harm arising from its use. Users are encouraged to review and test the script thoroughly before relying on it in production environments.
