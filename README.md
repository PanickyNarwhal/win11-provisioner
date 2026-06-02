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
```
### How to Build the USB
1. Open Windows Configuratior Designer and create a new Advanced Provisioning Project (Bottom Left).
2. Configure your baseline settings under `Runtime settings:`.
   * Set `HideOOBE` to True.
   * Create your local admin account.
   * Under WLAN enter your company Wi-Fi SSID and password.
3. Add the scrips
   * Go to `ProvisioningCommands -> Device Context -> CommandLine`.
   * Upload both the `Provision.ps1` and `config.json` from this repository.
4. Set the Launch Command
   * Go to `ProvisioningCommands -> DeviceContext -> CommandLine.`.
   * Enter the following command to bypass execution policies: `cmd.exe /c powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File .\Provision.ps1
5. Export the project as a Provisiong Package(.ppkg) and save it to the root of a USB formated to NTFS or FAT.

### Usage
1. Turn on your new Windows 10|11 laptop.
2. When the "Select your region" screen appears, plug in your USB drive.
3. Windows will automatically detect the package, reboot, and begin the automated provisioning process.
