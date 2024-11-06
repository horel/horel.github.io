oh-my-posh init pwsh --config 'C:\Users\horel\AppData\Local\Programs\oh-my-posh\themes\my_theme.omp.json' | Invoke-Expression
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineKeyHandler -Key "Ctrl+d" -Function ViExit
Import-Module z