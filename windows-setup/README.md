# Windows-Setup

The powershell scripts in this folder are ment to automate the process of setting up the Windows clients for StealthCup.
Copy the scripts to the Windows machines and execute each one on the corresponding host in the following sequence:
1) `setup-DC1.CORP.LOCAL.ps1`
2) `setup-DC1.CORP.OT.ps1`
3) `setup-FS1.CORP.LOCAL.ps1`
4) `setup-CLI1.CORP.LOCAL.ps1`
5) `setup-JUMP.CORP.OT.ps1`

## ESC1 Setup
Unfortunately I haven't found a method to automate the configuration of a certificate vulnerable to ESC1 yet, which is why you will have to do this manually for now.
Execute the following on `DC1.CORP.LOCAL`: 
- Press `Windows` + `R`, type `certtmpl.msc` and press `Enter` to open up `Certificate Templates Console`.
- Right-click the `User` template and select `Duplicate Template`.
- Select the `General` tab and change the template name to `ESC1Template`.
- Select the `Subject Name` tab and select `Supply in the request`.
- Select the `Security` tab &rarr; `Authenticated Users` and add the `Enroll` permission.
- Press `OK` to apply the changes.
- Press `Windows` + `R`, type `certsrv.msc` and press `Enter` to open up `Certificate Authority Console`.
- Expand your CA server and right-click `Certificate Templates`.
- Select `New` &rarr; `Certificate Template to Issue`.
- Select `ESC1Template` and press `OK` to apply the changes.
