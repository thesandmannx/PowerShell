takeown /f %windir%\ServiceProfiles\LocalService\AppData\Local\Microsoft\NGC /r /d j

icacls %windir%\ServiceProfiles\LocalService\AppData\Local\Microsoft\NGC /grant administrators:F /t

rd /s /q C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\NGC\