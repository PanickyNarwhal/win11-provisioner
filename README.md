# win11-provisioner
An alternative to Microsoft Autopilot using Windows Configuration Designer (WCD) and PowerShell to automate the OOBE and deploy software using WinGet

### Overview
This toolkit allows IT technicians to easily provision a machine. By placing a `.ppkg` file on a USB drive, Windows will automatically bypass setup screens, connect to Wi-Fi, make a local admin account, and execute a PowerShell script to download software through WinGet.

### Prerequisites
* USB Flash Drive
* [Windows Configuration Designer (WCD)](https://learn.microsoft.com/en-us/windows/configuration/provisioning-packages/provisioning-install-icd) installed from the Microsoft Store.

### Configuration 
Edit `config.json` to match your organization's software. Use `winget search <appname>` in your terminal to find the applicatoin IDs.

```json
{
  "AppsToInstall",: [
    "App.You.Want.Installed",
    "Mozilla.Firefox"
  ]
  "BloatwareToRemove": [
    "Apps.You.Want.Removed",
    "Microsoft.XboxApp"
  ],
  "ComputerNamePrefix": "Corporationname-Laptop-"
}
