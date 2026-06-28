$ErrorActionPreference = "Stop"
Write-Host "Baixando o instalador do Python 3.12..."
$url = "https://www.python.org/ftp/python/3.12.4/python-3.12.4-amd64.exe"
$output = "$env:TEMP\python-installer.exe"
Invoke-WebRequest -Uri $url -OutFile $output

Write-Host "Instalando o Python (isso pode levar alguns minutos)..."
# Instalando de forma silenciosa e já adicionando o Python ao PATH do Windows
Start-Process -FilePath $output -ArgumentList "/quiet InstallAllUsers=0 PrependPath=1 Include_test=0" -Wait

Write-Host "Instalando o Jupyter..."
# Usa o pip do Python recém instalado
$env:Path += ";$env:USERPROFILE\AppData\Local\Programs\Python\Python312\Scripts;$env:USERPROFILE\AppData\Local\Programs\Python\Python312"
python -m pip install --upgrade pip
python -m pip install jupyter

Write-Host "Instalação concluída com sucesso!"
