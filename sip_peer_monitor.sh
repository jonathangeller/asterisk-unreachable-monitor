#!/bin/bash

# Disclaimer: This script is provided "as is", without warranty of any kind, express or implied.
# The author(s) will not be liable for any damages, loss of data, or any other harm arising from its use.
# Free for use and modification. Users are encouraged to customize the script as per their needs.

# Usage:
# ./script_name [tenant] [recipient email] [mute period in seconds]
# - tenant: Optional. The tenant name to filter SIP peers. If not provided, no tenant filter is applied.
# - recipient email: The email address where notifications should be sent. Can be overridden below.
# - mute period: Optional. The period in seconds to mute repeated alerts for the same device. Defaults to 24 hours (86400 seconds).
# Note: The tenant and recipient email are positional parameters passed to the script. They can also be directly modified in the setup section below.

### Start of Setup Section ###
# Setup variables. These can be modified according to your needs.

tenant=${1}  # Tenant name for filtering. If not provided, the script does not apply tenant filtering.
recipient=$2  # Email address to receive notifications.
bcc="admin@example.com"  # BCC email address for additional notifications.
from="Notification Service <no-reply@example.com>"  # 'From' email address for sending notifications.
mute_period=${3:-86400}  # Mute period in seconds, default 24 hours (86400 seconds).

record_file="/tmp/reported_offline_${tenant:-default}.txt"  # File to track notifications, unique per tenant or 'default' if none specified.
### End of Setup Section ###

# Ensure the record file exists.
touch "$record_file"

# Command to fetch unreachable SIP peers. Apply tenant filtering only if tenant is specified.
if [ -n "$tenant" ]; then
    cmd="asterisk -rx \"sip show peers like $tenant\" | grep UNREACHABLE"
else
    cmd="asterisk -rx \"sip show peers\" | grep UNREACHABLE"
fi

echo "Running command: $cmd"

current_time=$(date +%s)
output=""

# Process current unreachable peers and prepare for notification.
while IFS= read -r line; do
    extension=$(echo "$line" | awk '{print $1}' | cut -d'/' -f1)
    last_reported=$(grep "^$extension " "$record_file" | cut -d' ' -f2)
    if [[ -z "$last_reported" || $((current_time - last_reported)) -gt $mute_period ]]; then
        ip=$(echo "$line" | awk '{print $2}' | grep -oP '(\d{1,3}\.){3}\d{1,3}' || echo "Unavailable")
        port=$(echo "$line" | awk '{print $5}' || echo "N/A")
        printf -v line_fmt "%-30s %-19s %-7s" "$extension" "$ip" "$port"
        output+="$line_fmt\n"
        echo "$extension $current_time" >> "$record_file"
    fi
done < <(eval "$cmd")

if [[ -n "$output" ]]; then
    echo "Found unreachable peers, preparing email."
    
    # Convert mute_period to a human-readable format for the notification.
    if ((mute_period >= 86400)); then
        period_display=$(printf "%.0f day(s)" "$((mute_period / 86400))")
    elif ((mute_period >= 3600)); then
        period_display=$(printf "%.0f hour(s)" "$((mute_period / 3600))")
    elif ((mute_period >= 60)); then
        period_display=$(printf "%.0f minute(s)" "$((mute_period / 60))")
    else
        period_display="$mute_period seconds"
    fi

    subject="Alert: SIP Device(s) Offline"
    tableHeader="Extension                      Last IP             Last Port\n"
    tableHeader+="------------------------------------------------------------\n"
    body="Hello,\n\nThe following SIP device(s) have recently reported offline:"
    body+="\n\n$tableHeader$output"
    body+="\n\nNote: No further alerts for these devices for $period_display, unless their status changes."
    body+="\n\n-------------------------------------\nNotification Service"
    
    if [[ -z "$recipient" ]]; then
        mailHeaders="From: $from\nTo: $bcc\nSubject: $subject"
    else
        mailHeaders="From: $from\nTo: $recipient\nBcc: $bcc\nSubject: $subject"
    fi

    echo -e "$mailHeaders\n$body" | sendmail -t
else
    echo "No UNREACHABLE SIP peers found or all recently reported."
fi
