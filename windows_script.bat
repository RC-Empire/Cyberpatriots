@echo off
setlocal enabledelayedexpansion
net session
if %errorlevel%==0 (
	echo Admin rights granted!
) else (
    echo Failure run this through administrator level
	pause
    exit
)

cls
	
:menu
	cls
	echo ---Roosters eat chicken---
	echo --- Enable Admin rights---
	echo --- RC tested so it works----
	echo 101)Password Policy      
	echo 102)Firewall Policy
	echo 103)Lockout Policy 
	echo 104) remote desktop (enable/disable)
	echo needs to be tested  
	echo 105) diable guest
	set /p answer=Please choose an option: 
		if "%answer%"=="101" goto :rcpasswordpolicy
		if "%answer%"=="102" goto :rcenablefirewallpolicy
		if "%answer%"=="103" goto :rclockout
		if "%answer%"=="104" goto :RCRemoteDesktop
		if "%answer%"=="105" goto :RCdisable_guest
		if "%answer%"=="41" exit
		if "%answer%"=="67" shutdown /r
	pause

:rcpasswordpolicy
	rem Sets the password policy
	echo Setting pasword policies
	echo Applying Password History (5)
	net accounts /uniquepw:5

	echo Applying Minimum Password Length (8)
	net accounts /minpwlen:8

	echo Applying Maximum Password Age (90 days)
	net accounts /maxpwage:90

	echo Applying Minimum Password Age (10 days)
	net accounts /minpwage:10
	
	pause
	goto :menu

:rcenablefirewallpolicy
	rem Enables firewall
	REM 1. Ensure the Firewall is ON for all profiles
	netsh advfirewall set allprofiles state on

	REM 2. Set the default policy: Block Inbound, Allow Outbound (Hardening Standard)
	REM This ensures only explicitly allowed inbound connections work.
	netsh advfirewall set allprofiles firewallpolicy blockinbound,allowoutbound

	echo.
	echo Blocking Unnecessary Inbound Ports (Example: Telnet, FTP, RDP)...
	REM --- Blocking Specific Ports (Usually Inbound) ---

	REM Block Inbound Telnet (TCP 23)
	netsh advfirewall firewall add rule name="CP_Block_Telnet_In" dir=in action=block protocol=TCP localport=23 	enable=yes

	REM Block Inbound FTP (TCP 21)
	netsh advfirewall firewall add rule name="CP_Block_FTP_In" dir=in action=block protocol=TCP localport=21 enable=yes

	REM Block Inbound RDP (TCP 3389) - ONLY if RDP is NOT required for scoring/access!
	REM netsh advfirewall firewall add rule name="CP_Block_RDP_In" dir=in action=block protocol=TCP localport=3389 enable=yes

	echo.
	echo Disabling Unnecessary Rule Groups (Example: Remote Desktop)...
	REM --- Disabling Pre-defined Rule Groups ---

	REM Disable the Remote Desktop group rules (Applies to all profiles)
	REM NOTE: If RDP is needed for scoring, skip this or use 'enable=yes' instead of 'enable=no'
	netsh advfirewall firewall set rule group="Remote Desktop" new enable=no

	REM Disable the File and Printer Sharing group rules (High-risk service)
	netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=no

	echo.
	echo Deleting Unwanted/Vulnerable Rules (Example: a suspicious rule name)...
	REM --- Deleting Rogue Rules ---

	REM You can delete rules by their exact name
	netsh advfirewall firewall delete rule name="Suspicious Allow Rule"

	REM You can also delete rules by group (useful for cleanup)
	REM netsh advfirewall firewall delete rule group="Suspicious Application Group"

	echo.
	echo Displaying Firewall Status for verification...
	netsh advfirewall show allprofiles

	echo.
	echo Firewall hardening complete.
	pause
	goto :menu

:rclockout
	rem Sets the lockout policy
	echo Setting the lockout policy
	net accounts /lockoutduration:30
	echo lockoutduration:30
	net accounts /lockoutthreshold:5
	echo lockoutthreshold:5
	net accounts /lockoutwindow:30
	echo lockoutwindow:30
	pause
	goto :menu

:RCRemoteDesktop
	rem Asks if remote desktop needs to be enabled
	set /p answer=Do you want remote desktop enabled(its usually disabled)?[y/n]
	if /I "%answer%"=="y" (
		reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
		echo RemoteDesktop is enabled, (reboot?_ 
	)
	if /I "%answer%"=="n" (
		reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f
		echo RemoteDesktop is disabled, please reboot
	)
	
	pause
	goto :menu


:RCdisable_guest
	rem checking if guest account is disabled 
	net user Guest | findstr Active | findstr Yes
	if %errorlevel%==0 (
		echo Guest account is already disabled.
	)
	if %errorlevel%==1 (
		net user guest Cyb3rPatr!0t$ /active:no
		echo guest account now has been disabled
	)

	pause
	goto :menu



endlocal
