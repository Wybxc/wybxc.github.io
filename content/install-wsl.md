---
title: A simple method to install WSL on a non-system drive
date: 2023-06-13
---
By default, WSL is installed on the system drive. If there is insufficient space on the system drive, you can install WSL on a non-system drive using the following steps:

**Step 1:** Install a WSL distribution as usual:
```powershell
wsl --install -d Ubuntu
```

**Step 2:** Export the distribution's hard drive:
```powershell
wsl --export Ubuntu D:\WSL\Ubuntu\ext4.vhdx --vhd
```

**Step 3:** Uninstall the recently installed distribution:
```powershell
wsl --unregister Ubuntu
```

**Step 4:** Re-establish WSL on the exported hard drive in place:
```powershell
wsl --import-in-place Ubuntu D:\WSL\Ubuntu\ext4.vhdx
```

**Step 5 (optional):** After the above operations, the default login user will be root. To switch back to a non-root user:
```powershell
ubuntu config --default-user <username>
```
