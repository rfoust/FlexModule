# FlexModule

This is a Powershell module for FlexRadio 6000 series amateur radios. Note that this project is NOT maintained by FlexRadio Systems.

More information about FlexRadio can be found at their website: [http://www.flexradio.com]

## Installation

To install -- Clone this repo to an appropriate Modules folder in Powershell, for example, in your `Documents\WindowsPowerShell\Modules\FlexModule` folder.

## Usage

If you're running a recent version of Powershell, just run `Get-FlexRadio` and it should show your FlexRadio 6000 series radio.  Run `Connect-FlexRadio` to connect to it.

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

## Available Cmdlets

To see all of the cmdlets available in this module, run `Get-FlexCommand`. The commands currently available are:

* Connect-FlexRadio
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

If you have questions, feel free to ask (rfoust at gmail.com). If you are interested in a feature that I haven't implemented yet, let me know and I'll probably make it a priority. This is a "proof-of-concept" and "for-fun" project.

Enjoy!

73,

-Robbie KI4TTZ
