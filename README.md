# FlexModule

This is a Powershell module for FlexRadio 6000 series amateur radios. Note that this project is NOT maintained by FlexRadio Systems.

More information about FlexRadio can be found on their website: [<http://www.flexradio.com>]

## Installation

To install -- Clone this repo to an appropriate Modules folder in Powershell, for example, in your `Documents\WindowsPowerShell\Modules\FlexModule` folder.

If this is your first time running scripts in Powershell, you may also need to launch a Powershell session as Administrator (Right click
the Powershell icon, select "Run as administrator") and then type `Set-ExecutionPolicy RemoteSigned`. This will open up the security settings
a little on your computer so that you can run scripts.

## Usage

If you're running a recent version of Powershell, just run `Get-FlexRadio` and it should show your FlexRadio 6000 series radio. Run `Connect-FlexRadio` to connect to it.  If you are operating remotely, you will need to first connect to SmartLink by running `Connect-FlexSmartLink`. If you haven't
configured SmartLink yet, please do so using SmartSDR.

```Powershell
PS C:\> Get-FlexRadio

Model           Serial                    IP                   Connected  Callsign
-----           ------                    --                   ---------  --------
FLEX-6700       4213-3107-6700-8545       192.168.1.155        False      KI4TTZ

PS C:\> Connect-FlexRadio

Model           Serial                    IP                   Connected  Callsign
-----           ------                    --                   ---------  --------
FLEX-6700       4213-3107-6700-8545       192.168.1.155        True       KI4TTZ

PS C:\>
```

## Examples

*Changing the RF Power:*

```Powershell
PS C:\> Get-FlexRadio | select *power*

MaxPowerLevel RFPower TunePower TXRFPowerChangesAllowed
------------- ------- --------- -----------------------
          100      15        10                    True

PS C:\> Get-FlexRadio | Set-FlexRadio -RFPower 100
PS C:\> Get-FlexRadio | select *power*

MaxPowerLevel RFPower TunePower TXRFPowerChangesAllowed
------------- ------- --------- -----------------------
          100     100        10                    True

PS C:\>
```

*Changing the frequency of the active slice receiver:*

```Powershell
PS C:\> Get-FlexSliceReceiver -Active

Index           Active                    RXAnt                TXAnt      Freq
-----           ------                    -----                -----      ----
0               True                      RX_A                 ANT1       7.1301

PS C:\> Get-FlexSliceReceiver -Active | Set-FlexSliceReceiver -Freq "7.127"

Confirm
Are you sure you want to perform this action?
Performing the operation "Modify Freq on Slice #0" on target "4213-3107-6700-8545".
[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): y
PS C:\>
```

## Available Cmdlets

To see all of the cmdlets available in this module, run `Get-FlexCommand`. The commands currently available are:

* Connect-FlexRadio
* Connect-FlexSmartLink
* Disable-FlexLog
* Disable-FlexTNF
* Disconnect-FlexRadio
* Enable-FlexLog
* Enable-FlexTNF
* Export-FlexDatabase
* Get-FlexCommand
* Get-FlexLatestFolderPath
* Get-FlexLibPath
* Get-FlexLog
* Get-FlexMemory
* Get-FlexPacket
* Get-FlexPanadapter
* Get-FlexProfile
* Get-FlexRadio
* Get-FlexSliceReceiver
* Get-FlexVersion
* Import-FlexLib
* Install-FlexGPS
* New-FlexMemory
* New-FlexSliceReceiver
* Remove-FlexMemory
* Remove-FlexPanadapter
* Remove-FlexSliceReceiver
* Restart-FlexRadio
* Select-FlexMemory
* Set-FlexMemory
* Set-FlexPanadapter
* Set-FlexRadio
* Set-FlexSliceReceiver
* Start-FlexScreenSaver
* Uninstall-FlexGPS

## Conclusion

If you have questions, feel free to ask (rfoust at gmail.com).

Enjoy!

73,

-Robbie KI4TTZ
