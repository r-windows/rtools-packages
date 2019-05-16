# We use upstream msys2 to build packages because the runtime from rtools may
# be out of sync with the upstream core build utilities.
Function InstallMSYS64 {
	Write-Host "Installing MSYS2 64-bit..." -ForegroundColor Cyan
	$zipPath = "$($env:USERPROFILE)\msys2-x86_64-latest.tar.xz"
	$tarPath = "$($env:USERPROFILE)\msys2-x86_64-latest.tar"

	Write-Host "Downloading MSYS installation package..."
	(New-Object Net.WebClient).DownloadFile('http://repo.msys2.org/distrib/msys2-x86_64-latest.tar.xz', $zipPath)

	Write-Host "Untaring installation package..."
	7z x $zipPath -y -o"$env:USERPROFILE" | Out-Null

	Write-Host "Unzipping installation package..."
	7z x $tarPath -y -oC:\ | Out-Null
	del $zipPath
	del $tarPath

	Write-Host "Initiating pacman..."
	C:\msys64\usr\bin\bash.exe --login -c exit
}

##### Old stuff ###

$RTOOLS_ARCH = ${env:RTOOLS_ARCH}
$RTOOLS_ZIP = "rtools40-${RTOOLS_ARCH}.7z"
$RTOOLS_EXE = "rtools40-${RTOOLS_ARCH}.exe"
#$ErrorActionPreference = "Stop";

### Use for bootstrapping installation
$RTOOLS_MIRROR = "https://dl.bintray.com/rtools/installer/"
# $RTOOLS_MIRROR = "https://cloud.r-project.org/bin/windows/Rtools/"
# $RTOOLS_MIRROR = "https://ftp.opencpu.org/archive/rtools/4.0/"

function CheckExitCode($msg) {
  if ($LastExitCode -ne 0) {
    Throw $msg
  }
}

# Unzip and Initiate Rtools dump
Function InstallRtoolsZip {
	Write-Host "Installing ${RTOOLS_ZIP}..." -ForegroundColor Cyan
	$tmp = "$($env:USERPROFILE)\${RTOOLS_ZIP}"
	(New-Object Net.WebClient).DownloadFile($RTOOLS_MIRROR + $RTOOLS_ZIP, $tmp)
	7z x $tmp -y -oC:\ | Out-Null
	CheckExitCode "Failed to extract ${RTOOLS_ZIP}"
	C:\rtools40\usr\bin\bash.exe --login -c exit 2>$null
	Write-Host "Installation of ${RTOOLS_ZIP} done!" -ForegroundColor Green
}

# Don't use installer when: (1) architecture doesn't match host (2) Dir C:/rtools40 already exists
Function InstallRtoolsExe {
	Write-Host "Installing ${RTOOLS_EXE}..." -ForegroundColor Cyan
	$tmp = "$($env:USERPROFILE)\${RTOOLS_EXE}"	
	(New-Object Net.WebClient).DownloadFile($RTOOLS_MIRROR + $RTOOLS_EXE, $tmp)
	Start-Process -FilePath $tmp -ArgumentList /VERYSILENT -NoNewWindow -Wait
#	CheckExitCode "Failed to install ${RTOOLS_EXE}"
	Write-Host "Installation of ${RTOOLS_EXE} done!" -ForegroundColor Green
}


function bash($command) {
    Write-Host $command -NoNewline
    cmd /c start /wait C:\rtools40\usr\bin\sh.exe --login -c $command
    Write-Host " - OK" -ForegroundColor Green
}

function InstallRtools {
	InstallRtoolsExe
	bash 'pacman -Sy --noconfirm pacman pacman-mirrors'
	bash 'pacman -Syyu --noconfirm --ask 20'		
}
