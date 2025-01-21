# Mac Datacenter Configuration Script

This script automates the configuration of Mac minis for datacenter use.

## Features

- Disables automatic macOS updates
- Configures power management settings (sleep, power nap, disk sleep, display sleep, Wake on Network Access)
- Enables SSH remote access
- Optional Wi-Fi and Bluetooth configuration
- Includes comprehensive verification checks with visual status indicators
- Screen Sharing configuration guidance

## Usage

1. Clone the repository:

```bash
git clone https://github.com/your-username/mac-datacenter-config.git
cd mac-datacenter-config
```

2. Run the script:

```bash
sudo sh ./configure-mac.sh
```

3. Follow the prompts to:

   - Configure network settings (optional Wi-Fi/Bluetooth disable)
   - Review and verify all configurations
   - Set up Screen Sharing manually through System Settings

4. The script will apply the changes and perform detailed verification checks with status indicators.

## Notes

- This script is designed for Mac minis running macOS 14.0 or later
- It is recommended to run the script on a clean macOS installation
- The script is idempotent, so it can be run multiple times without causing issues
- Requires sudo privileges to run
- Some settings like Screen Sharing require manual configuration through System Settings
