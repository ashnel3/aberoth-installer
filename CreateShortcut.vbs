' https://ss64.com/nt/shortcut.html
Set oWS = WScript.CreateObject("WScript.Shell")
Set oLink = oWS.CreateShortcut("..\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Aberoth.lnk")
oLink.TargetPath = "%USERPROFILE%\.aberoth\Aberoth.jar"
oLink.IconLocation = "%USERPROFILE%\.aberoth\icon.ico"
oLink.Save
