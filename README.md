# Cisco Device Inventory Script

## Version: 1.0
**Purpose:** Automate Cisco IOS-XE device inventory collection using RESTCONF API via PowerShell.

---

## Requirements
This script requires **PowerShell 7+** and a Cisco IOS-XE device with RESTCONF API enabled.

### Checking Your PowerShell Version
To check your current PowerShell version, open a terminal and run:
```powershell
$PSVersionTable.PSVersion
```
If the **Major version** is **7 or higher**, you are good to go.

### Upgrading to PowerShell 7+ (If Needed)
If your PowerShell version is **5.x or lower**, install PowerShell 7+ with the following steps:

#### Windows (Using Winget)
```powershell
winget install --id Microsoft.PowerShell --source winget
```
Or download manually from:
[PowerShell Releases](https://github.com/PowerShell/PowerShell/releases)

#### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install -y powershell
pwsh
```
#### MacOS (Homebrew)
```bash
brew install --cask powershell
```
After installation, run:
```powershell
pwsh
```
to start PowerShell 7.

---

## Input File: `inventory.csv`
The script reads a list of Cisco IOS-XE device IPs from a CSV file named `inventory.csv`.

### Expected Format
```csv
host
192.168.5.1
192.168.5.2
```
- The **first line must contain the header**: `host`
- Each subsequent line should contain an **IP address** or **hostname** of a Cisco device.

---

## Cisco IOS-XE Device Configuration
To ensure that RESTCONF API is available on your Cisco IOS-XE devices, run the following commands on each router or switch.

### Enable RESTCONF
```bash
conf t
ip http server
ip http secure-server
restconf
exit
write memory
```

### Verify RESTCONF is Enabled
```bash
show running-config | include restconf
```

### Configure API Authentication (Username & Password)
The script will **prompt for credentials**, but ensure a valid user exists with API access.  
To create a new user with RESTCONF privileges:
```bash
username cisco privilege 15 secret mypassword
aaa new-model
aaa authentication login default local
```
This allows login with **username:** `cisco` and **password:** `mypassword` (replace accordingly).

### Verify RESTCONF API Access
From your local machine, test the API with:
```bash
curl -k -u cisco:mypassword https://192.168.5.1/restconf/data
```
If you get a JSON response, the API is working correctly.

---

## How to Run the Script
1. Ensure PowerShell 7+ is installed (`pwsh`).  
2. Ensure `inventory.csv` exists with the correct format.  
3. Run the script from the terminal:
```powershell
./inventory.ps1
```
4. Enter Cisco device credentials when prompted.  
5. Wait for the script to complete. It will display a table with device information.

---

## Output File: `inventory_results_YYYYMMDD_HHMMSS.csv`
After execution, the script will generate a results file named with a **timestamp**, such as:
```
inventory_results_20250203_203500.csv
```
This prevents overwriting previous results.

### Example Output File
```csv
Device,Hostname,OS_Version,Serial_Number
192.168.5.1,HOME,17.9,9TFTD9XSAID
192.168.5.2,UNREACHABLE,UNREACHABLE,UNREACHABLE
```
If a device is **unreachable**, it will be marked as `"UNREACHABLE"` instead of causing the script to fail.

---

## Troubleshooting
### PowerShell Errors
**1. Error: `Invoke-RestMethod : The SSL connection could not be established`**  
Solution: Ensure PowerShell 7+ is installed and use `-SkipCertificateCheck` or a custom HttpClient as used in this script.

**2. Error: `ConvertFrom-Json: Cannot bind argument to parameter 'InputObject' because it is null`**  
Solution: This script already handles null responses, but verify that RESTCONF is properly enabled on the device.

### Cisco Device Issues
**1. Device does not respond to RESTCONF requests**  
Solution: Ensure `ip http server`, `ip http secure-server`, and `restconf` are configured on the Cisco device.

**2. Authentication fails**  
Solution: Verify the username and password configured on the device.

---

## Features & Benefits
- **Automated Inventory Collection**: Fetches Hostname, OS Version, and Serial Number for each device.  
- **Handles Unreachable Devices**: If a device is offline, it logs `"UNREACHABLE"` instead of failing.  
- **Secure Authentication**: Prompts for credentials dynamically, preventing hardcoded passwords.  
- **Timestamped Output Files**: No data loss from overwriting previous results.  
- **Compatible with Multiple Devices**: Works with all Cisco IOS-XE devices supporting RESTCONF.

---

## Additional Resources
- Cisco RESTCONF API Documentation:  
  [https://developer.cisco.com/docs/ios-xe/#!restconf-introduction](https://developer.cisco.com/docs/ios-xe/#!restconf-introduction)  
- PowerShell 7 Download:  
  [https://github.com/PowerShell/PowerShell/releases](https://github.com/PowerShell/PowerShell/releases)  

---

## Final Thoughts
This script provides a **reliable, automated way** to collect inventory data from Cisco devices. It **ensures security**, **handles errors gracefully**, and **creates properly formatted reports** for future analysis.

If you encounter issues, **double-check your PowerShell version** and **ensure RESTCONF is enabled on your Cisco devices**.

This guide provides a detailed overview for any future users, covering installation, configuration, usage, troubleshooting, and output format. Let me know if there are any additional details needed.

